import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/app_data_service.dart';
import '../core/constants.dart';
import '../core/order_services.dart';
import 'order_details_screen.dart';

// ─── Layout constants ────────────────────────────────────────────────
const int _kDayStart = 7;
const int _kDayEnd = 22;
const double _kHourWidth = 80.0; // px per hour
const double _kRowHeight = 88.0; // height of each master row
const double _kRowLabelWidth = 110.0; // left sticky column
const double _kTimeHeaderHeight = 36.0;
const double _kTotalWidth = (_kDayEnd - _kDayStart) * _kHourWidth;
const double _kMinCardWidth = 48.0;

double _minuteToX(int minuteOfDay) {
  return (minuteOfDay - _kDayStart * 60) / 60.0 * _kHourWidth;
}

int _xToMinuteOfDay(double x) {
  final raw = (x / _kHourWidth * 60).round() + _kDayStart * 60;
  return raw.clamp(_kDayStart * 60, _kDayEnd * 60 - 15);
}

int _snapMinute(int minuteOfDay) {
  return ((minuteOfDay + 7) ~/ 15) * 15;
}

// ─── CalendarScreen ──────────────────────────────────────────────────

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  final ScrollController _hScrollCtrl = ScrollController();
  final ScrollController _vScrollCtrl = ScrollController();

  Timer? _nowTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    _hScrollCtrl.dispose();
    _vScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    if (!_hScrollCtrl.hasClients) return;
    final nowX = _minuteToX(_now.hour * 60 + _now.minute) - 120;
    final target = nowX.clamp(0.0, _hScrollCtrl.position.maxScrollExtent);
    _hScrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  bool _canEditOrders() {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final businessMode = BusinessMode.fromStorage(
      settingsBox.get('businessMode')?.toString(),
    );
    final appRole = AppRole.fromStorage(
      settingsBox.get('appRole')?.toString(),
      mode: businessMode,
    );
    return appRole.canManageOrdersAndClients;
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _scheduledDateTime(Map<String, dynamic> order) {
    final rawDate = order['scheduledDate'];
    if (rawDate is! num) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(rawDate.toInt());
    final time = _parseTime(order['scheduledTime']?.toString());
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  int _durationMinutes(Map<String, dynamic> order) {
    final raw = (order['duration'] as num?)?.toInt() ?? 0;
    return raw <= 0 ? 60 : raw;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(OrderStatus status) => status.color;

  Future<void> _updateOrder(
    BuildContext ctx,
    dynamic key,
    Map<String, dynamic> current,
    Map<String, dynamic> patch, {
    bool showSnackBar = true,
  }) async {
    if (!_canEditOrders()) {
      final l10n = AppLocalizations.of(ctx)!;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(l10n.permissionEditOrderDenied)));
      return;
    }
    final box = Hive.box(HiveBoxes.orders);
    final updated = Map<String, dynamic>.from(current)..addAll(patch);
    await box.put(key, updated);
    AppDataService.syncOrderToCloud(updated).ignore();
    if (showSnackBar) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(ctx)!.orderUpdated)),
      );
    }
  }

  Future<void> _editStartTime(
    BuildContext ctx,
    dynamic key,
    Map<String, dynamic> order,
  ) async {
    final selectedDay = _selectedDay;
    final scheduled = _scheduledDateTime(order);
    if (scheduled == null || selectedDay == null) return;
    final initial = TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
    final picked = await showTimePicker(context: ctx, initialTime: initial);
    if (picked == null || !ctx.mounted) return;
    final newDate = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      picked.hour,
      picked.minute,
    );
    await _updateOrder(ctx, key, order, {
      'scheduledDate': newDate.millisecondsSinceEpoch,
      'scheduledTime': _formatTimeOfDay(picked),
    });
  }

  Future<void> _changeDuration(
    BuildContext ctx,
    dynamic key,
    Map<String, dynamic> order,
    int deltaMinutes,
  ) async {
    final current = _durationMinutes(order);
    final next = (current + deltaMinutes).clamp(15, 12 * 60);
    await _updateOrder(ctx, key, order, {
      'duration': next,
    }, showSnackBar: false);
  }

  Future<void> _resizeOrderRight(
    BuildContext ctx,
    dynamic key,
    Map<String, dynamic> order,
    int deltaMinutes,
  ) async {
    final scheduled = _scheduledDateTime(order);
    if (scheduled == null) return;

    final startMin = scheduled.hour * 60 + scheduled.minute;
    final currentDuration = _durationMinutes(order);
    final maxDuration = (_kDayEnd * 60 - startMin).clamp(15, 12 * 60);
    final nextDuration = (currentDuration + deltaMinutes).clamp(
      15,
      maxDuration,
    );

    if (nextDuration == currentDuration) return;

    await _updateOrder(ctx, key, order, {
      'duration': nextDuration,
    }, showSnackBar: false);
  }

  Future<void> _resizeOrderLeft(
    BuildContext ctx,
    dynamic key,
    Map<String, dynamic> order,
    int deltaMinutes,
  ) async {
    final scheduled = _scheduledDateTime(order);
    if (scheduled == null) return;

    final startMin = scheduled.hour * 60 + scheduled.minute;
    final currentDuration = _durationMinutes(order);
    final endMin = startMin + currentDuration;

    final minStart = _kDayStart * 60;
    final maxStart = (endMin - 15).clamp(minStart, _kDayEnd * 60 - 15);
    final nextStart = (startMin + deltaMinutes).clamp(minStart, maxStart);
    final nextDuration = endMin - nextStart;

    if (nextDuration < 15) return;
    if (nextStart == startMin && nextDuration == currentDuration) return;

    final nextDate = DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
      nextStart ~/ 60,
      nextStart % 60,
    );

    await _updateOrder(ctx, key, order, {
      'scheduledDate': nextDate.millisecondsSinceEpoch,
      'scheduledTime': _formatTimeOfDay(
        TimeOfDay(hour: nextDate.hour, minute: nextDate.minute),
      ),
      'duration': nextDuration,
    }, showSnackBar: false);
  }

  void _openOrderDetails(BuildContext ctx, Map<String, dynamic> order) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final currency = settingsBox.get('currency', defaultValue: '€').toString();
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          orderData: Map<String, dynamic>.from(order),
          currency: currency,
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsBox = Hive.box(HiveBoxes.settings);
    final String locale = settingsBox.get('locale', defaultValue: 'en');
    final oBox = Hive.box(HiveBoxes.orders);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.navCalendar),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Top: TableCalendar ──────────────────────────────────
          TableCalendar(
            locale: locale,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToNow(),
              );
            },
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            eventLoader: (day) {
              return oBox.values.where((o) {
                if (o['scheduledDate'] == null) return false;
                return isSameDay(
                  DateTime.fromMillisecondsSinceEpoch(o['scheduledDate']),
                  day,
                );
              }).toList();
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // ── Bottom: Horizontal Timeline ─────────────────────────
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: oBox.listenable(),
              builder: (context, Box box, _) {
                // Collect orders for selected day
                final dayOrders = <MapEntry<dynamic, Map<String, dynamic>>>[];
                for (final key in box.keys) {
                  final raw = box.get(key);
                  if (raw is! Map) continue;
                  final order = Map<String, dynamic>.from(raw);
                  if (order['scheduledDate'] == null || _selectedDay == null) {
                    continue;
                  }
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    (order['scheduledDate'] as num).toInt(),
                  );
                  if (!isSameDay(date, _selectedDay)) continue;
                  final scheduled = _scheduledDateTime(order);
                  if (scheduled == null) continue;
                  final minuteOfDay = scheduled.hour * 60 + scheduled.minute;
                  if (minuteOfDay < _kDayStart * 60 ||
                      minuteOfDay >= _kDayEnd * 60) {
                    continue;
                  }
                  dayOrders.add(MapEntry(key, order));
                }

                if (dayOrders.isEmpty) {
                  return Center(child: Text(l10n.noOrdersTitle));
                }

                // Group by master name
                final masterMap =
                    <String, List<MapEntry<dynamic, Map<String, dynamic>>>>{};
                for (final entry in dayOrders) {
                  final master =
                      entry.value['assignedToName']?.toString().trim() ?? '';
                  masterMap.putIfAbsent(master, () => []).add(entry);
                }
                final masters = masterMap.keys.toList()..sort();

                final canEdit = _canEditOrders();
                final isToday = isSameDay(_selectedDay, DateTime.now());

                return _HorizontalTimeline(
                  masters: masters,
                  masterOrders: masterMap,
                  hScrollCtrl: _hScrollCtrl,
                  vScrollCtrl: _vScrollCtrl,
                  now: _now,
                  isToday: isToday,
                  canEdit: canEdit,
                  locale: locale,
                  l10n: l10n,
                  scheduledDateTime: _scheduledDateTime,
                  durationMinutes: _durationMinutes,
                  statusColor: _statusColor,
                  onCardTap: (order) => _openOrderDetails(context, order),
                  onEditTime: (key, order) =>
                      _editStartTime(context, key, order),
                  onChangeDuration: (key, order, delta) =>
                      _changeDuration(context, key, order, delta),
                  onResizeLeft: (key, order, delta) =>
                      _resizeOrderLeft(context, key, order, delta),
                  onResizeRight: (key, order, delta) =>
                      _resizeOrderRight(context, key, order, delta),
                  onDrop: (key, order, newMinuteOfDay) async {
                    final selected = _selectedDay;
                    if (selected == null) return;
                    final snapped = _snapMinute(
                      newMinuteOfDay,
                    ).clamp(_kDayStart * 60, _kDayEnd * 60 - 15);
                    final hour = snapped ~/ 60;
                    final minute = snapped % 60;
                    final newDate = DateTime(
                      selected.year,
                      selected.month,
                      selected.day,
                      hour,
                      minute,
                    );
                    await _updateOrder(context, key, order, {
                      'scheduledDate': newDate.millisecondsSinceEpoch,
                      'scheduledTime': _formatTimeOfDay(
                        TimeOfDay(hour: hour, minute: minute),
                      ),
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Horizontal Timeline Widget ──────────────────────────────────────

class _HorizontalTimeline extends StatelessWidget {
  final List<String> masters;
  final Map<String, List<MapEntry<dynamic, Map<String, dynamic>>>> masterOrders;
  final ScrollController hScrollCtrl;
  final ScrollController vScrollCtrl;
  final DateTime now;
  final bool isToday;
  final bool canEdit;
  final String locale;
  final AppLocalizations l10n;
  final DateTime? Function(Map<String, dynamic>) scheduledDateTime;
  final int Function(Map<String, dynamic>) durationMinutes;
  final Color Function(OrderStatus) statusColor;
  final void Function(Map<String, dynamic> order) onCardTap;
  final Future<void> Function(dynamic key, Map<String, dynamic> order)
  onEditTime;
  final Future<void> Function(
    dynamic key,
    Map<String, dynamic> order,
    int deltaMinutes,
  )
  onChangeDuration;
  final Future<void> Function(
    dynamic key,
    Map<String, dynamic> order,
    int deltaMinutes,
  )
  onResizeLeft;
  final Future<void> Function(
    dynamic key,
    Map<String, dynamic> order,
    int deltaMinutes,
  )
  onResizeRight;
  final Future<void> Function(
    dynamic key,
    Map<String, dynamic> order,
    int newMinuteOfDay,
  )
  onDrop;

  const _HorizontalTimeline({
    required this.masters,
    required this.masterOrders,
    required this.hScrollCtrl,
    required this.vScrollCtrl,
    required this.now,
    required this.isToday,
    required this.canEdit,
    required this.locale,
    required this.l10n,
    required this.scheduledDateTime,
    required this.durationMinutes,
    required this.statusColor,
    required this.onCardTap,
    required this.onEditTime,
    required this.onChangeDuration,
    required this.onResizeLeft,
    required this.onResizeRight,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left sticky: row labels ───────────────────────────────
        SizedBox(
          width: _kRowLabelWidth,
          child: Column(
            children: [
              // Placeholder for time header row
              Container(
                height: _kTimeHeaderHeight,
                color: AppColors.background,
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: SingleChildScrollView(
                  controller: vScrollCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: masters.map((master) {
                      return _MasterLabel(name: master.isEmpty ? '—' : master);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1, color: Colors.white12),

        // ── Right: horizontal scroll content ─────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: hScrollCtrl,
            child: SizedBox(
              width: _kTotalWidth,
              child: Column(
                children: [
                  // Time header
                  _TimeHeader(),
                  const Divider(height: 1, color: Colors.white12),
                  // Master rows
                  Expanded(
                    child: SingleChildScrollView(
                      controller: vScrollCtrl,
                      child: Stack(
                        children: [
                          // Hour grid lines
                          _HourGridLines(masters: masters),
                          // Master rows with order cards
                          Column(
                            children: masters.map((master) {
                              return _MasterRow(
                                master: master,
                                entries: masterOrders[master] ?? [],
                                canEdit: canEdit,
                                locale: locale,
                                l10n: l10n,
                                scheduledDateTime: scheduledDateTime,
                                durationMinutes: durationMinutes,
                                statusColor: statusColor,
                                onCardTap: onCardTap,
                                onEditTime: onEditTime,
                                onChangeDuration: onChangeDuration,
                                onResizeLeft: onResizeLeft,
                                onResizeRight: onResizeRight,
                                onDrop: onDrop,
                              );
                            }).toList(),
                          ),
                          // Now line (vertical red)
                          if (isToday) _NowLine(now: now),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Time header (07:00 … 22:00) ─────────────────────────────────────

class _TimeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hours = <Widget>[];
    for (var h = _kDayStart; h < _kDayEnd; h++) {
      hours.add(
        SizedBox(
          width: _kHourWidth,
          height: _kTimeHeaderHeight,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '${h.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return Row(children: hours);
  }
}

// ─── Hour grid vertical lines ─────────────────────────────────────────

class _HourGridLines extends StatelessWidget {
  final List<String> masters;
  const _HourGridLines({required this.masters});

  @override
  Widget build(BuildContext context) {
    final totalHeight = masters.length * _kRowHeight;
    return SizedBox(
      width: _kTotalWidth,
      height: totalHeight,
      child: CustomPaint(painter: _GridPainter(masters.length)),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int rowCount;
  _GridPainter(this.rowCount);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    final rowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    // Vertical hour lines
    for (var h = 0; h <= (_kDayEnd - _kDayStart); h++) {
      final x = h * _kHourWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      // Half-hour
      if (h < (_kDayEnd - _kDayStart)) {
        canvas.drawLine(
          Offset(x + _kHourWidth / 2, 0),
          Offset(x + _kHourWidth / 2, size.height),
          halfPaint,
        );
      }
    }

    // Horizontal row dividers
    for (var r = 1; r < rowCount; r++) {
      final y = r * _kRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.rowCount != rowCount;
}

// ─── Red "Now" vertical line ──────────────────────────────────────────

class _NowLine extends StatelessWidget {
  final DateTime now;
  const _NowLine({required this.now});

  @override
  Widget build(BuildContext context) {
    final minuteOfDay = now.hour * 60 + now.minute;
    if (minuteOfDay < _kDayStart * 60 || minuteOfDay > _kDayEnd * 60) {
      return const SizedBox.shrink();
    }
    final x = _minuteToX(minuteOfDay);
    return Positioned(
      left: x - 1,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: 2,
          color: Colors.redAccent.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

// ─── Master row label (left column) ─────────────────────────────────

class _MasterLabel extends StatelessWidget {
  final String name;
  const _MasterLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline, size: 18, color: Colors.white38),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Single master row with order cards ──────────────────────────────

class _MasterRow extends StatelessWidget {
  final String master;
  final List<MapEntry<dynamic, Map<String, dynamic>>> entries;
  final bool canEdit;
  final String locale;
  final AppLocalizations l10n;
  final DateTime? Function(Map<String, dynamic>) scheduledDateTime;
  final int Function(Map<String, dynamic>) durationMinutes;
  final Color Function(OrderStatus) statusColor;
  final void Function(Map<String, dynamic> order) onCardTap;
  final Future<void> Function(dynamic, Map<String, dynamic>) onEditTime;
  final Future<void> Function(dynamic, Map<String, dynamic>, int)
  onChangeDuration;
  final Future<void> Function(dynamic, Map<String, dynamic>, int) onResizeLeft;
  final Future<void> Function(dynamic, Map<String, dynamic>, int) onResizeRight;
  final Future<void> Function(dynamic, Map<String, dynamic>, int) onDrop;

  const _MasterRow({
    required this.master,
    required this.entries,
    required this.canEdit,
    required this.locale,
    required this.l10n,
    required this.scheduledDateTime,
    required this.durationMinutes,
    required this.statusColor,
    required this.onCardTap,
    required this.onEditTime,
    required this.onChangeDuration,
    required this.onResizeLeft,
    required this.onResizeRight,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_OrderDragData>(
      onWillAcceptWithDetails: (details) {
        return canEdit && details.data.masterKey == master;
      },
      onAcceptWithDetails: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final local = renderBox.globalToLocal(details.offset);
        final minuteOfDay = _xToMinuteOfDay(local.dx);
        onDrop(details.data.key, details.data.order, minuteOfDay);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: _kTotalWidth,
          height: _kRowHeight,
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.blueAccent.withValues(alpha: 0.07)
                : Colors.transparent,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: entries.map((entry) {
              final scheduled = scheduledDateTime(entry.value);
              if (scheduled == null) return const SizedBox.shrink();
              final xPos = _minuteToX(scheduled.hour * 60 + scheduled.minute);
              final dur = durationMinutes(entry.value);
              final cardWidth = (dur / 60.0 * _kHourWidth).clamp(
                _kMinCardWidth,
                600.0,
              );
              final status = OrderStatus.fromName(
                entry.value['status']?.toString(),
              );
              final color = statusColor(status);

              final card = Positioned(
                left: xPos,
                top: 4,
                bottom: 4,
                child: SizedBox(
                  width: cardWidth,
                  child: _OrderCard(
                    entry: entry,
                    cardWidth: cardWidth,
                    color: color,
                    status: status,
                    scheduled: scheduled,
                    dur: dur,
                    l10n: l10n,
                    canEdit: canEdit,
                    onTap: () => onCardTap(entry.value),
                    onEditTime: canEdit
                        ? () => onEditTime(entry.key, entry.value)
                        : null,
                    onAdjustDuration: canEdit
                        ? (delta) =>
                              onChangeDuration(entry.key, entry.value, delta)
                        : null,
                    onResizeLeft: canEdit
                        ? (delta) => onResizeLeft(entry.key, entry.value, delta)
                        : null,
                    onResizeRight: canEdit
                        ? (delta) =>
                              onResizeRight(entry.key, entry.value, delta)
                        : null,
                  ),
                ),
              );

              if (!canEdit) return card;

              return Positioned(
                left: xPos,
                top: 4,
                bottom: 4,
                child: SizedBox(
                  width: cardWidth,
                  child: LongPressDraggable<_OrderDragData>(
                    data: _OrderDragData(
                      key: entry.key,
                      order: entry.value,
                      masterKey: master,
                    ),
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.85,
                        child: _OrderCard(
                          entry: entry,
                          cardWidth: cardWidth.clamp(120, 260),
                          color: color,
                          status: status,
                          scheduled: scheduled,
                          dur: dur,
                          l10n: l10n,
                          canEdit: canEdit,
                          onTap: null,
                          onEditTime: null,
                          onAdjustDuration: null,
                          onResizeLeft: null,
                          onResizeRight: null,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _OrderCard(
                        entry: entry,
                        cardWidth: cardWidth,
                        color: color,
                        status: status,
                        scheduled: scheduled,
                        dur: dur,
                        l10n: l10n,
                        canEdit: canEdit,
                        onTap: null,
                        onEditTime: null,
                        onAdjustDuration: null,
                        onResizeLeft: null,
                        onResizeRight: null,
                      ),
                    ),
                    child: _OrderCard(
                      entry: entry,
                      cardWidth: cardWidth,
                      color: color,
                      status: status,
                      scheduled: scheduled,
                      dur: dur,
                      l10n: l10n,
                      canEdit: canEdit,
                      onTap: () => onCardTap(entry.value),
                      onEditTime: () => onEditTime(entry.key, entry.value),
                      onAdjustDuration: (delta) =>
                          onChangeDuration(entry.key, entry.value, delta),
                      onResizeLeft: (delta) =>
                          onResizeLeft(entry.key, entry.value, delta),
                      onResizeRight: (delta) =>
                          onResizeRight(entry.key, entry.value, delta),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Order card ──────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final MapEntry<dynamic, Map<String, dynamic>> entry;
  final double cardWidth;
  final Color color;
  final OrderStatus status;
  final DateTime scheduled;
  final int dur;
  final AppLocalizations l10n;
  final bool canEdit;
  final VoidCallback? onTap;
  final VoidCallback? onEditTime;
  final void Function(int delta)? onAdjustDuration;
  final void Function(int delta)? onResizeLeft;
  final void Function(int delta)? onResizeRight;

  const _OrderCard({
    required this.entry,
    required this.cardWidth,
    required this.color,
    required this.status,
    required this.scheduled,
    required this.dur,
    required this.l10n,
    required this.canEdit,
    required this.onTap,
    required this.onEditTime,
    required this.onAdjustDuration,
    required this.onResizeLeft,
    required this.onResizeRight,
  });

  @override
  Widget build(BuildContext context) {
    final order = entry.value;
    final endTime = scheduled.add(Duration(minutes: dur));
    final timeLabel =
        '${DateFormat('HH:mm').format(scheduled)}-${DateFormat('HH:mm').format(endTime)}';
    final compact = cardWidth < 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 7, vertical: 4),
        child: Row(
          children: [
            if (canEdit && cardWidth >= 130)
              _ResizeHandle(onStepMinutes: onResizeLeft),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      order['car'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((order['client'] ?? '').toString().isNotEmpty)
                      Text(
                        order['client'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Flexible(
                      child: Text(
                        orderServicesSummary(order),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white38,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canEdit && cardWidth >= 130) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          InkWell(
                            onTap: onEditTime,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                DateFormat('HH:mm').format(scheduled),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: onAdjustDuration == null
                                ? null
                                : () => onAdjustDuration!(-15),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Icon(Icons.remove, size: 14),
                            ),
                          ),
                          Text('$dur', style: const TextStyle(fontSize: 9)),
                          InkWell(
                            onTap: onAdjustDuration == null
                                ? null
                                : () => onAdjustDuration!(15),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Icon(Icons.add, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    Flexible(
                      child: Text(
                        order['car'] ?? '',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canEdit && cardWidth >= 130)
              _ResizeHandle(onStepMinutes: onResizeRight),
          ],
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  final void Function(int deltaMinutes)? onStepMinutes;

  const _ResizeHandle({required this.onStepMinutes});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double _accumulatedDx = 0;
  static const double _quarterHourPx = _kHourWidth / 4;

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.onStepMinutes == null) return;

    _accumulatedDx += details.delta.dx;
    while (_accumulatedDx.abs() >= _quarterHourPx) {
      final direction = _accumulatedDx > 0 ? 1 : -1;
      widget.onStepMinutes!(direction * 15);
      _accumulatedDx -= direction * _quarterHourPx;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => _accumulatedDx = 0,
      onHorizontalDragCancel: () => _accumulatedDx = 0,
      child: const SizedBox(
        width: 12,
        child: Icon(Icons.drag_indicator, size: 10, color: Colors.white30),
      ),
    );
  }
}

// ─── Drag data ───────────────────────────────────────────────────────

class _OrderDragData {
  final dynamic key;
  final Map<String, dynamic> order;
  final String masterKey;

  const _OrderDragData({
    required this.key,
    required this.order,
    required this.masterKey,
  });
}
