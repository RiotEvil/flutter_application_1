const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

const REGION = "europe-west3";
const MAX_TOKENS_PER_REQUEST = 500;
const DEFAULT_TIMEZONE = "Europe/Warsaw";
const PLAN_SYNC_MIN_INTERVAL_MS = 15 * 1000;
const BILLING_AUDIT_RETENTION_DAYS = 180;
const revenueCatSecret = defineSecret("REVENUECAT_SECRET_KEY");

const DAY_MS = 24 * 60 * 60 * 1000;

const DEFAULT_SCHEDULE = {
  slotMinutes: 30,
  minNoticeMinutes: 60,
  days: {
    "1": {start: "09:00", end: "18:00", breaks: [{start: "13:00", end: "14:00"}]},
    "2": {start: "09:00", end: "18:00", breaks: [{start: "13:00", end: "14:00"}]},
    "3": {start: "09:00", end: "18:00", breaks: [{start: "13:00", end: "14:00"}]},
    "4": {start: "09:00", end: "18:00", breaks: [{start: "13:00", end: "14:00"}]},
    "5": {start: "09:00", end: "18:00", breaks: [{start: "13:00", end: "14:00"}]},
    "6": {start: "10:00", end: "15:00", breaks: []},
    "0": null,
  },
};

function withCors(req, res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return true;
  }
  return false;
}

function parseIsoMs(value) {
  if (!value || typeof value !== "string") return null;
  const ms = Date.parse(value);
  return Number.isFinite(ms) ? ms : null;
}

function parseFirestoreMs(value) {
  if (!value) return null;
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function isEntitlementActive(entitlement, nowMs) {
  if (!entitlement || typeof entitlement !== "object") {
    return false;
  }

  const expiresMs = parseIsoMs(entitlement.expires_date);
  const graceMs = parseIsoMs(entitlement.grace_period_expires_date);

  if (expiresMs == null) {
    return true;
  }

  if (expiresMs > nowMs) {
    return true;
  }

  return graceMs != null && graceMs > nowMs;
}

function derivePlanStatus(entitlement, nowMs) {
  if (!entitlement || typeof entitlement !== "object") {
    return "inactive";
  }

  const graceMs = parseIsoMs(entitlement.grace_period_expires_date);
  const billingIssueMs = parseIsoMs(entitlement.billing_issues_detected_at);
  const periodType = String(entitlement.period_type || "").toLowerCase();

  if ((graceMs != null && graceMs > nowMs) || billingIssueMs != null) {
    return "grace";
  }

  if (periodType.includes("trial")) {
    return "trial";
  }

  return "active";
}

function resolvePlanFromSubscriber(subscriber) {
  const nowMs = Date.now();
  const entitlements = subscriber && subscriber.entitlements &&
      typeof subscriber.entitlements === "object"
    ? subscriber.entitlements
    : {};

  const businessEntitlement = entitlements.business;
  const proEntitlement = entitlements.pro;

  if (isEntitlementActive(businessEntitlement, nowMs)) {
    return {
      plan: "business",
      planStatus: derivePlanStatus(businessEntitlement, nowMs),
      billingProvider: "revenuecat",
    };
  }

  if (isEntitlementActive(proEntitlement, nowMs)) {
    return {
      plan: "pro",
      planStatus: derivePlanStatus(proEntitlement, nowMs),
      billingProvider: "revenuecat",
    };
  }

  return {
    plan: "free",
    planStatus: "inactive",
    billingProvider: "revenuecat",
  };
}

async function verifyAuthAndGetUid(req) {
  const authHeader = String(req.headers.authorization || "");
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return null;
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return null;
  }

  const decoded = await admin.auth().verifyIdToken(token);
  return decoded && decoded.uid ? decoded.uid : null;
}

exports.syncPlanStatus = onRequest(
  {
    region: REGION,
    memory: "256MiB",
    maxInstances: 5,
    invoker: "public",
    secrets: [revenueCatSecret],
  },
  async (req, res) => {
    if (withCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({error: "method-not-allowed"});
      return;
    }

    let uid;
    try {
      uid = await verifyAuthAndGetUid(req);
    } catch (error) {
      logger.error("syncPlanStatus auth verification failed", error);
      res.status(401).json({error: "unauthorized"});
      return;
    }

    if (!uid) {
      res.status(401).json({error: "unauthorized"});
      return;
    }

    const revenueCatApiKey = String(revenueCatSecret.value() || "").trim();
    if (!revenueCatApiKey) {
      res.status(503).json({error: "revenuecat-secret-missing"});
      return;
    }

    try {
      const firestore = admin.firestore();
      const userRef = firestore.collection("users").doc(uid);
      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};

      const nowMs = Date.now();
      const lastPlanSyncMs = parseFirestoreMs(userData.lastPlanSyncAt);
      if (lastPlanSyncMs != null && nowMs - lastPlanSyncMs < PLAN_SYNC_MIN_INTERVAL_MS) {
        const retryAfterMs = PLAN_SYNC_MIN_INTERVAL_MS - (nowMs - lastPlanSyncMs);
        res.status(429).json({
          error: "rate-limited",
          retryAfterMs,
        });
        return;
      }

      const rcResponse = await fetch(
        `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${revenueCatApiKey}`,
            "Content-Type": "application/json",
          },
        },
      );

      if (!rcResponse.ok) {
        const details = await rcResponse.text();
        logger.error("syncPlanStatus revenuecat request failed", {
          status: rcResponse.status,
          uid,
          details,
        });
        res.status(502).json({error: "revenuecat-fetch-failed"});
        return;
      }

      const rcPayload = await rcResponse.json();
      const subscriber = rcPayload && rcPayload.subscriber ? rcPayload.subscriber : null;
      const resolved = resolvePlanFromSubscriber(subscriber);
      const seatLimit = resolved.plan === "business" ? 5 : 1;

      const orgId = userData.orgId;
      const previousPlan = String(userData.plan || "free");
      const previousStatus = String(userData.planStatus || "inactive");
      const previousProvider = String(userData.billingProvider || "unknown");

      const batch = firestore.batch();
      batch.set(
        userRef,
        {
          plan: resolved.plan,
          planStatus: resolved.planStatus,
          billingProvider: resolved.billingProvider,
          lastPlanSyncAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );

      if (typeof orgId === "string" && orgId.trim().length > 0) {
        batch.set(firestore.collection("organizations").doc(orgId),
          {
            plan: resolved.plan,
            planStatus: resolved.planStatus,
            billingProvider: resolved.billingProvider,
            seatLimit,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      }

      const changed =
        previousPlan !== resolved.plan ||
        previousStatus !== resolved.planStatus ||
        previousProvider !== resolved.billingProvider;

      if (changed) {
        const auditRef = firestore.collection("billing_audit").doc();
        batch.set(auditRef, {
          uid,
          orgId: typeof orgId === "string" ? orgId : null,
          source: "syncPlanStatus",
          previous: {
            plan: previousPlan,
            planStatus: previousStatus,
            billingProvider: previousProvider,
          },
          current: {
            plan: resolved.plan,
            planStatus: resolved.planStatus,
            billingProvider: resolved.billingProvider,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      res.status(200).json({
        ok: true,
        uid,
        plan: resolved.plan,
        planStatus: resolved.planStatus,
        billingProvider: resolved.billingProvider,
      });
    } catch (error) {
      logger.error("syncPlanStatus failed", error);
      res.status(500).json({error: "internal"});
    }
  },
);

exports.functionsHealth = onRequest(
  {
    region: REGION,
    memory: "128MiB",
    maxInstances: 2,
    invoker: "public",
  },
  async (req, res) => {
    if (withCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({error: "method-not-allowed"});
      return;
    }

    res.status(200).json({
      ok: true,
      service: "detailing-pro-functions",
      region: REGION,
      timestamp: new Date().toISOString(),
    });
  },
);

function clampNumber(value, fallback, min, max) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, Math.round(n)));
}

function parseMonthRange(month) {
  const m = String(month || "").trim();
  const match = /^(\d{4})-(\d{2})$/.exec(m);
  if (!match) return null;
  const year = Number(match[1]);
  const mon = Number(match[2]);
  if (mon < 1 || mon > 12) return null;
  const start = new Date(Date.UTC(year, mon - 1, 1));
  const end = new Date(Date.UTC(year, mon, 0, 23, 59, 59, 999));
  return {startMs: start.getTime(), endMs: end.getTime(), year, month: mon};
}

function parseTimeToMinutes(raw) {
  if (typeof raw !== "string") return null;
  const match = /^(\d{1,2}):(\d{2})$/.exec(raw.trim());
  if (!match) return null;
  const hh = Number(match[1]);
  const mm = Number(match[2]);
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
  return hh * 60 + mm;
}

function minutesToTime(minutes) {
  const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
  const mm = String(minutes % 60).padStart(2, "0");
  return `${hh}:${mm}`;
}

function parseYmd(raw) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(raw || "").trim());
  if (!match) return null;
  const y = Number(match[1]);
  const m = Number(match[2]);
  const d = Number(match[3]);
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return {y, m, d};
}

function ymdKeyFromUtcMs(ms) {
  const d = new Date(ms);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function zonedPartsFromMs(ms, timeZone) {
  const formatter = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });
  const map = {};
  for (const part of formatter.formatToParts(new Date(ms))) {
    if (part.type !== "literal") {
      map[part.type] = part.value;
    }
  }

  const dayKey = `${map.year}-${map.month}-${map.day}`;
  const minutes = Number(map.hour || 0) * 60 + Number(map.minute || 0);
  return {dayKey, minutes};
}

function weekdayFromYmd(ymd) {
  return new Date(Date.UTC(ymd.y, ymd.m - 1, ymd.d)).getUTCDay();
}

function dayStartUtcMs(ymd) {
  return Date.UTC(ymd.y, ymd.m - 1, ymd.d, 0, 0, 0, 0);
}

function overlap(aStart, aEnd, bStart, bEnd) {
  return aStart < bEnd && bStart < aEnd;
}

function normalizeSchedule(raw) {
  const src = raw && typeof raw === "object" ? raw : {};
  const slotMinutes = clampNumber(src.slotMinutes, DEFAULT_SCHEDULE.slotMinutes, 15, 120);
  const minNoticeMinutes = clampNumber(
    src.minNoticeMinutes,
    DEFAULT_SCHEDULE.minNoticeMinutes,
    0,
    24 * 60,
  );
  const days = {};

  for (let day = 0; day <= 6; day += 1) {
    const key = String(day);
    const fallback = DEFAULT_SCHEDULE.days[key];
    const sourceDay = src.days && typeof src.days === "object" ? src.days[key] : undefined;
    const effective = sourceDay === undefined ? fallback : sourceDay;

    if (!effective || typeof effective !== "object") {
      days[key] = null;
      continue;
    }

    const startMinutes = parseTimeToMinutes(effective.start);
    const endMinutes = parseTimeToMinutes(effective.end);
    if (startMinutes == null || endMinutes == null || endMinutes <= startMinutes) {
      days[key] = null;
      continue;
    }

    const breaks = Array.isArray(effective.breaks) ? effective.breaks : [];
    const normalizedBreaks = breaks
      .map((b) => {
        const bStart = parseTimeToMinutes(b && b.start);
        const bEnd = parseTimeToMinutes(b && b.end);
        if (bStart == null || bEnd == null || bEnd <= bStart) return null;
        return {start: bStart, end: bEnd};
      })
      .filter(Boolean);

    days[key] = {
      start: startMinutes,
      end: endMinutes,
      breaks: normalizedBreaks,
    };
  }

  return {slotMinutes, minNoticeMinutes, days};
}

function timestampMs(raw) {
  if (!raw) return null;
  if (typeof raw.toMillis === "function") {
    return raw.toMillis();
  }
  if (typeof raw === "number" && Number.isFinite(raw)) {
    return raw;
  }
  return null;
}

function extractBookingIntervals(docs, fallbackDurationMinutes) {
  const out = [];
  for (const d of docs) {
    const data = d.data() || {};
    const status = String(data.status || "pending").toLowerCase();
    if (status !== "pending" && status !== "accepted") continue;

    const ymd = parseYmd(data.preferredDate);
    const startMinutes = parseTimeToMinutes(data.preferredTime);
    if (!ymd || startMinutes == null) continue;

    const duration = clampNumber(
      data.requestedDurationMinutes,
      fallbackDurationMinutes,
      15,
      8 * 60,
    );
    out.push({
      dayKey: `${String(ymd.y).padStart(4, "0")}-${String(ymd.m).padStart(2, "0")}-${String(ymd.d).padStart(2, "0")}`,
      start: startMinutes,
      end: startMinutes + duration,
    });
  }
  return out;
}

function extractOrderIntervals(
  docs,
  masterUid,
  fallbackDurationMinutes,
  businessMode,
  timeZone,
) {
  const out = [];
  for (const d of docs) {
    const data = d.data() || {};
    const status = String(data.status || "").toLowerCase();
    if (status === "completed" || status === "paid") continue;

    const assignedToUid = String(data.assignedToUid || "").trim();
    if (businessMode === "team") {
      if (!assignedToUid || assignedToUid !== masterUid) continue;
    }

    const ms = timestampMs(data.scheduledDate);
    if (!ms) continue;

    const zoned = zonedPartsFromMs(ms, timeZone);
    const duration = clampNumber(data.duration, fallbackDurationMinutes, 15, 8 * 60);

    out.push({
      dayKey: zoned.dayKey,
      start: zoned.minutes,
      end: zoned.minutes + duration,
    });
  }
  return out;
}

exports.getBookingAvailability = onRequest(
  {
    region: REGION,
    memory: "256MiB",
    maxInstances: 5,
    invoker: "public",
  },
  async (req, res) => {
    if (withCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({error: "method-not-allowed"});
      return;
    }

    const masterUid = String(req.query.masterUid || "").trim();
    const month = String(req.query.month || "").trim();
    const timezone = String(req.query.timezone || DEFAULT_TIMEZONE).trim() || DEFAULT_TIMEZONE;
    const serviceDurationMinutes = clampNumber(req.query.serviceMinutes, 120, 30, 8 * 60);

    if (!masterUid) {
      res.status(400).json({error: "missing-masterUid"});
      return;
    }

    const monthRange = parseMonthRange(month);
    if (!monthRange) {
      res.status(400).json({error: "invalid-month", expected: "YYYY-MM"});
      return;
    }

    try {
      const users = admin.firestore().collection("users");
      const userSnap = await users.doc(masterUid).get();
      if (!userSnap.exists) {
        res.status(404).json({error: "master-not-found"});
        return;
      }

      const userData = userSnap.data() || {};
      const orgId = String(userData.orgId || "").trim();
      const businessMode = String(userData.businessMode || "solo").trim().toLowerCase();
      const schedule = normalizeSchedule(userData.bookingSchedule);

      const [requestsSnap, ordersSnap] = await Promise.all([
        admin
          .firestore()
          .collection("booking_requests")
          .where("masterUid", "==", masterUid)
          .where("preferredDate", ">=", `${month}-01`)
          .where("preferredDate", "<=", `${month}-31`)
          .get(),
        orgId
          ? admin
              .firestore()
              .collection(`organizations/${orgId}/orders`)
              .where(
                "scheduledDate",
                ">=",
                admin.firestore.Timestamp.fromMillis(monthRange.startMs),
              )
              .where(
                "scheduledDate",
                "<=",
                admin.firestore.Timestamp.fromMillis(monthRange.endMs),
              )
              .get()
          : Promise.resolve({docs: []}),
      ]);

      const intervalsByDay = new Map();

      const requestIntervals = extractBookingIntervals(
        requestsSnap.docs,
        serviceDurationMinutes,
      );
      const orderIntervals = extractOrderIntervals(
        ordersSnap.docs,
        masterUid,
        serviceDurationMinutes,
        businessMode,
        timezone,
      );

      for (const interval of [...requestIntervals, ...orderIntervals]) {
        const list = intervalsByDay.get(interval.dayKey) || [];
        list.push(interval);
        intervalsByDay.set(interval.dayKey, list);
      }

      const nowMs = Date.now();
      const minStartMs = nowMs + schedule.minNoticeMinutes * 60 * 1000;
      const slotsByDate = {};
      const availableDates = [];

      for (let dayMs = monthRange.startMs; dayMs <= monthRange.endMs; dayMs += DAY_MS) {
        const dayKey = ymdKeyFromUtcMs(dayMs);
        const ymd = parseYmd(dayKey);
        if (!ymd) continue;

        const weekday = weekdayFromYmd(ymd);
        const dayCfg = schedule.days[String(weekday)];
        if (!dayCfg) continue;

        const busy = intervalsByDay.get(dayKey) || [];
        const daySlots = [];

        for (
          let slotStart = dayCfg.start;
          slotStart + serviceDurationMinutes <= dayCfg.end;
          slotStart += schedule.slotMinutes
        ) {
          const slotEnd = slotStart + serviceDurationMinutes;
          const slotStartMs = dayStartUtcMs(ymd) + slotStart * 60 * 1000;
          if (slotStartMs < minStartMs) continue;

          let blocked = false;
          for (const br of dayCfg.breaks) {
            if (overlap(slotStart, slotEnd, br.start, br.end)) {
              blocked = true;
              break;
            }
          }
          if (blocked) continue;

          for (const iv of busy) {
            if (overlap(slotStart, slotEnd, iv.start, iv.end)) {
              blocked = true;
              break;
            }
          }
          if (blocked) continue;

          daySlots.push(minutesToTime(slotStart));
        }

        if (daySlots.length > 0) {
          slotsByDate[dayKey] = daySlots;
          availableDates.push(dayKey);
        }
      }

      res.status(200).json({
        masterUid,
        month,
        timezone,
        businessMode,
        serviceDurationMinutes,
        slotMinutes: schedule.slotMinutes,
        availableDates,
        slotsByDate,
        stats: {
          requestsConsidered: requestIntervals.length,
          ordersConsidered: orderIntervals.length,
        },
      });
    } catch (error) {
      logger.error("getBookingAvailability failed", error);
      res.status(500).json({error: "internal", message: String(error)});
    }
  },
);

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

async function getDirectorUsers(orgId) {
  const snap = await admin
    .firestore()
    .collection("users")
    .where("orgId", "==", orgId)
    .get();

  return snap.docs
    .map((d) => ({id: d.id, ...d.data()}))
    .filter((u) => u.role === "director" || u.role === "masterOwner");
}

async function notifyOrgDirectors({orgId, title, body, data}) {
  const directors = await getDirectorUsers(orgId);

  if (directors.length === 0) {
    logger.info("No directors found for org", {orgId});
    return;
  }

  const tokensWithOwner = [];
  for (const director of directors) {
    const tokens = Array.isArray(director.fcmTokens) ? director.fcmTokens : [];
    for (const token of tokens) {
      if (typeof token === "string" && token.trim().length > 0) {
        tokensWithOwner.push({token: token.trim(), uid: director.id});
      }
    }
  }

  if (tokensWithOwner.length === 0) {
    logger.info("No FCM tokens for directors", {orgId});
    return;
  }

  const uniqueTokens = [...new Set(tokensWithOwner.map((x) => x.token))];
  const payload = {
    notification: {title, body},
    data: data || {},
  };

  let successCount = 0;
  const invalidByUser = new Map();

  for (const part of chunk(uniqueTokens, MAX_TOKENS_PER_REQUEST)) {
    const response = await admin.messaging().sendEachForMulticast({
      ...payload,
      tokens: part,
    });

    successCount += response.successCount;

    response.responses.forEach((r, i) => {
      if (r.success || !r.error) return;
      const code = r.error.code || "unknown";
      const token = part[i];
      const isInvalid =
        code.includes("registration-token-not-registered") ||
        code.includes("invalid-argument");

      if (!isInvalid) return;

      const owner = tokensWithOwner.find((t) => t.token === token);
      if (!owner) return;

      const current = invalidByUser.get(owner.uid) || [];
      current.push(token);
      invalidByUser.set(owner.uid, current);
    });
  }

  // Best-effort cleanup of invalid tokens in users/{uid}.fcmTokens
  const updates = [];
  invalidByUser.forEach((tokens, uid) => {
    updates.push(
      admin
        .firestore()
        .collection("users")
        .doc(uid)
        .set(
          {
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokens),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        ),
    );
  });
  await Promise.all(updates);

  logger.info("Director push sent", {
    orgId,
    title,
    attemptedTokens: uniqueTokens.length,
    successCount,
  });
}

exports.cleanupBillingAudit = onSchedule(
  {
    region: REGION,
    schedule: "every day 03:30",
    timeZone: DEFAULT_TIMEZONE,
    memory: "256MiB",
    maxInstances: 1,
  },
  async () => {
    const cutoffMs = Date.now() - BILLING_AUDIT_RETENTION_DAYS * DAY_MS;
    const cutoffTs = admin.firestore.Timestamp.fromMillis(cutoffMs);
    const db = admin.firestore();

    let deleted = 0;

    while (true) {
      const snap = await db
        .collection("billing_audit")
        .where("createdAt", "<=", cutoffTs)
        .limit(400)
        .get();

      if (snap.empty) {
        break;
      }

      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }

      await batch.commit();
      deleted += snap.size;

      if (snap.size < 400) {
        break;
      }
    }

    logger.info("cleanupBillingAudit completed", {
      deleted,
      retentionDays: BILLING_AUDIT_RETENTION_DAYS,
    });
  },
);

function orderMessage(before, after) {
  if (!before.exists && after.exists) {
    const car = after.data().car || "New order";
    return {
      title: "New order",
      body: `${car} was created`,
      eventType: "order_created",
    };
  }

  if (before.exists && !after.exists) {
    const car = before.data().car || "Order";
    return {
      title: "Order deleted",
      body: `${car} was removed`,
      eventType: "order_deleted",
    };
  }

  const beforeData = before.data();
  const afterData = after.data();
  const car = afterData.car || beforeData.car || "Order";

  if (beforeData.status !== afterData.status) {
    return {
      title: "Order status changed",
      body: `${car}: ${beforeData.status || "unknown"} -> ${afterData.status || "unknown"}`,
      eventType: "order_status_changed",
    };
  }

  return {
    title: "Order updated",
    body: `${car} was updated`,
    eventType: "order_updated",
  };
}

function inventoryMessage(before, after) {
  if (!before.exists && after.exists) {
    const item = after.data().name || "Item";
    return {
      title: "Inventory item created",
      body: `${item} was added to inventory`,
      eventType: "inventory_created",
    };
  }

  if (before.exists && !after.exists) {
    const item = before.data().name || "Item";
    return {
      title: "Inventory item deleted",
      body: `${item} was removed from inventory`,
      eventType: "inventory_deleted",
    };
  }

  const beforeData = before.data();
  const afterData = after.data();
  const item = afterData.name || beforeData.name || "Item";
  const beforeAmount = Number(beforeData.amount || 0);
  const afterAmount = Number(afterData.amount || 0);
  const minStock = Number(afterData.minStock || 0);

  if (beforeAmount !== afterAmount) {
    if (minStock > 0 && afterAmount <= minStock) {
      return {
        title: "Low stock alert",
        body: `${item}: ${afterAmount} left (min ${minStock})`,
        eventType: "inventory_low_stock",
      };
    }

    return {
      title: "Inventory updated",
      body: `${item}: ${beforeAmount} -> ${afterAmount}`,
      eventType: "inventory_amount_changed",
    };
  }

  return {
    title: "Inventory updated",
    body: `${item} details were updated`,
    eventType: "inventory_updated",
  };
}

exports.onOrderWritten = onDocumentWritten(
  {
    document: "organizations/{orgId}/orders/{orderId}",
    region: REGION,
  },
  async (event) => {
    const orgId = event.params.orgId;
    const orderId = event.params.orderId;
    const before = event.data.before;
    const after = event.data.after;

    const msg = orderMessage(before, after);

    await notifyOrgDirectors({
      orgId,
      title: msg.title,
      body: msg.body,
      data: {
        type: msg.eventType,
        orgId,
        entity: "order",
        entityId: orderId,
      },
    });
  },
);

exports.onInventoryWritten = onDocumentWritten(
  {
    document: "organizations/{orgId}/inventory/{itemId}",
    region: REGION,
  },
  async (event) => {
    const orgId = event.params.orgId;
    const itemId = event.params.itemId;
    const before = event.data.before;
    const after = event.data.after;

    const msg = inventoryMessage(before, after);

    await notifyOrgDirectors({
      orgId,
      title: msg.title,
      body: msg.body,
      data: {
        type: msg.eventType,
        orgId,
        entity: "inventory",
        entityId: itemId,
      },
    });
  },
);
