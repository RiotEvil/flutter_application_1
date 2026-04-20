import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/access_guard.dart';
import '../core/app_data_service.dart';
import '../core/constants.dart';
import '../core/subscription_texts.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!AccessGuard.canUseOnlineBooking()) {
      return Scaffold(
        appBar: _ScreenAppBar(title: l10n.bookingRequestsTitle),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SubscriptionTexts.bookingProTitle(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(SubscriptionTexts.bookingProMessage(context)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => AccessGuard.showUpgradePrompt(
                          context,
                          title: SubscriptionTexts.bookingProTitle(context),
                          message: SubscriptionTexts.bookingProMessage(context),
                          requiredPlan: AppPlan.pro,
                        ),
                        child: Text(SubscriptionTexts.viewPlans(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: _ScreenAppBar(title: l10n.bookingRequestsTitle),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l10n.bookingRequestsFirebaseUnavailable),
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: _ScreenAppBar(title: l10n.bookingRequestsTitle),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l10n.bookingRequestsSignInRequired),
          ),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('booking_requests')
        .where('masterUid', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: _ScreenAppBar(title: l10n.bookingRequestsTitle),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.bookingRequestsError(snapshot.error.toString()),
                ),
              ),
            );
          }

          final docs = [...(snapshot.data?.docs ?? const [])]
            ..sort((a, b) {
              final ta = _asMillis(a.data()['createdAt']);
              final tb = _asMillis(b.data()['createdAt']);
              return tb.compareTo(ta);
            });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.bookingRequestsEmpty),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final clientName = data['clientName']?.toString() ?? '-';
              final phone = data['clientPhone']?.toString() ?? '';
              final service = data['service']?.toString() ?? '-';
              final car = data['car']?.toString() ?? '';
              final date = data['preferredDate']?.toString() ?? '-';
              final time = data['preferredTime']?.toString() ?? '-';
              final note = data['note']?.toString().trim() ?? '';
              final status = (data['status']?.toString() ?? 'pending')
                  .toLowerCase();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${l10n.bookingRequestServiceLabel}: $service'),
                      if (car.isNotEmpty)
                        Text('${l10n.bookingRequestCarLabel}: $car'),
                      Text('${l10n.bookingRequestScheduleLabel}: $date $time'),
                      if (phone.isNotEmpty)
                        Text('${l10n.bookingRequestPhoneLabel}: $phone'),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('${l10n.bookingRequestNoteLabel}: $note'),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (status == 'pending')
                            ElevatedButton.icon(
                              onPressed: () => _setStatus(doc.id, 'accepted'),
                              icon: const Icon(Icons.check),
                              label: Text(l10n.bookingRequestAccept),
                            ),
                          if (status == 'pending')
                            OutlinedButton.icon(
                              onPressed: () => _setStatus(doc.id, 'declined'),
                              icon: const Icon(Icons.close),
                              label: Text(l10n.bookingRequestDecline),
                            ),
                          if (phone.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _call(phone),
                              icon: const Icon(Icons.call_outlined),
                              label: Text(l10n.bookingRequestCall),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _setStatus(String id, String status) async {
    final ref = FirebaseFirestore.instance
        .collection('booking_requests')
        .doc(id);

    await ref.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'declined') {
      // If the request was already imported — delete the linked order.
      final snap = await ref.get();
      final orderId = snap.data()?['importedOrderId']?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        final box = Hive.box(HiveBoxes.orders);
        for (final key in box.keys.toList()) {
          final raw = box.get(key);
          if (raw is Map && raw['id']?.toString() == orderId) {
            box.delete(key);
            unawaited(AppDataService.deleteOrderFromCloud(orderId));
            break;
          }
        }
      }
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

int _asMillis(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }

  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    final numeric = int.tryParse(value);
    if (numeric != null) {
      return numeric;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.millisecondsSinceEpoch;
    }
  }

  return 0;
}

class _ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ScreenAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = l10n.bookingRequestStatusAccepted;
        break;
      case 'declined':
        color = Colors.redAccent;
        label = l10n.bookingRequestStatusDeclined;
        break;
      default:
        color = Colors.orange;
        label = l10n.bookingRequestStatusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
