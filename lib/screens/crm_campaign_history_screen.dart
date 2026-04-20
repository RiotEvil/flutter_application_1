import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/access_guard.dart';
import '../core/app_data_service.dart';
import '../core/constants.dart';
import '../core/subscription_texts.dart';

enum _HistoryFilter { all, single, bulk }

class CrmCampaignHistoryScreen extends StatefulWidget {
  const CrmCampaignHistoryScreen({super.key});

  @override
  State<CrmCampaignHistoryScreen> createState() =>
      _CrmCampaignHistoryScreenState();
}

class _CrmCampaignHistoryScreenState extends State<CrmCampaignHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('00')) {
      digits = '+${digits.substring(2)}';
    }
    if (!digits.startsWith('+') && digits.isNotEmpty) {
      digits = '+$digits';
    }
    return digits;
  }

  Future<void> _repeatLastCampaign(
    BuildContext context,
    Box clientsBox,
    Box settingsBox,
    AppLocalizations l10n,
  ) async {
    final lastCampaignAt = (settingsBox.get('crmLastCampaignAt') as num?)
        ?.toInt();
    if (lastCampaignAt == null || lastCampaignAt <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.orderHistoryEmpty)));
      return;
    }

    final recipients = <Map<String, dynamic>>[];

    for (final key in clientsBox.keys) {
      final raw = clientsBox.get(key);
      if (raw is! Map) continue;

      final ts = (raw['lastReminderAt'] as num?)?.toInt();
      final type = raw['lastReminderType']?.toString();
      if (ts != lastCampaignAt || type != 'bulk') {
        continue;
      }

      final phone = _normalizePhone(raw['phone']?.toString() ?? '');
      if (phone.isEmpty) {
        continue;
      }

      recipients.add({
        'key': key,
        'name': raw['name']?.toString() ?? '-',
        'phone': phone,
      });
    }

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.crmBulkReminderEmpty)));
      return;
    }

    final selected = <dynamic>{for (final item in recipients) item['key']};
    final savedBody = settingsBox.get('crmLastCampaignBody')?.toString();
    final bodyController = TextEditingController(
      text: savedBody?.isNotEmpty == true
          ? savedBody!
          : l10n.crmBulkReminderTemplate,
    );

    final sendPressed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.8,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.crmBulkReminderTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (selected.length == recipients.length) {
                                  selected.clear();
                                } else {
                                  selected
                                    ..clear()
                                    ..addAll(recipients.map((e) => e['key']));
                                }
                              });
                            },
                            child: Text(l10n.crmBulkReminderToggleAll),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: TextField(
                        controller: bodyController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.message,
                          prefixIcon: const Icon(Icons.sms_outlined),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: recipients.length,
                        itemBuilder: (context, index) {
                          final item = recipients[index];
                          final checked = selected.contains(item['key']);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(item['key']);
                                } else {
                                  selected.remove(item['key']);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(item['name']?.toString() ?? '-'),
                            subtitle: Text(item['phone']?.toString() ?? ''),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selected.isEmpty
                              ? null
                              : () => Navigator.pop(sheetContext, true),
                          icon: const Icon(Icons.send_outlined),
                          label: Text(l10n.crmBulkReminderSendSelected),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (sendPressed != true) {
      bodyController.dispose();
      return;
    }

    final phones = <String>{};
    final recipientKeys = <dynamic>[];
    for (final item in recipients) {
      if (!selected.contains(item['key'])) continue;
      final phone = item['phone']?.toString() ?? '';
      if (phone.isEmpty) continue;
      phones.add(phone);
      recipientKeys.add(item['key']);
    }

    if (phones.isEmpty) {
      bodyController.dispose();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.crmBulkReminderEmpty)));
      return;
    }

    final uri = Uri(
      scheme: 'sms',
      path: phones.join(','),
      queryParameters: {'body': bodyController.text.trim()},
    );

    bodyController.dispose();

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.openWhatsAppFailed)));
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    var sentCount = 0;
    for (final key in recipientKeys) {
      final raw = clientsBox.get(key);
      if (raw is! Map) continue;
      final updated = Map<String, dynamic>.from(raw)
        ..['lastReminderAt'] = now
        ..['lastReminderChannel'] = 'sms'
        ..['lastReminderType'] = 'bulk';
      await clientsBox.put(key, updated);
      unawaited(AppDataService.syncClientToCloud(updated));
      sentCount += 1;
    }

    await settingsBox.put('crmLastCampaignAt', now);
    await settingsBox.put('crmLastCampaignCount', sentCount);
    await settingsBox.put(
      'crmLastCampaignBody',
      uri.queryParameters['body'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientsBox = Hive.box(HiveBoxes.clients);
    final settingsBox = Hive.box(HiveBoxes.settings);

    if (!AccessGuard.canUseCrmCampaigns()) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.crmBulkReminderButton)),
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
                      SubscriptionTexts.crmProTitle(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(SubscriptionTexts.crmProMessage(context)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => AccessGuard.showUpgradePrompt(
                          context,
                          title: SubscriptionTexts.crmProTitle(context),
                          message: SubscriptionTexts.crmProMessage(context),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.crmBulkReminderButton)),
      body: ValueListenableBuilder(
        valueListenable: clientsBox.listenable(),
        builder: (context, Box clients, _) {
          final entries = <Map<String, dynamic>>[];

          for (final key in clients.keys) {
            final raw = clients.get(key);
            if (raw is! Map) continue;

            final ts = (raw['lastReminderAt'] as num?)?.toInt();
            if (ts == null || ts <= 0) continue;

            entries.add({
              'name': raw['name']?.toString() ?? '-',
              'phone': raw['phone']?.toString() ?? '',
              'at': ts,
              'type': raw['lastReminderType']?.toString() ?? 'single',
              'channel': raw['lastReminderChannel']?.toString() ?? 'sms',
            });
          }

          entries.sort((a, b) => (b['at'] as int).compareTo(a['at'] as int));

          final filteredEntries = entries.where((entry) {
            switch (_filter) {
              case _HistoryFilter.all:
                return true;
              case _HistoryFilter.single:
                return entry['type'] == 'single';
              case _HistoryFilter.bulk:
                return entry['type'] == 'bulk';
            }
          }).toList();

          final lastCampaignAt = (settingsBox.get('crmLastCampaignAt') as num?)
              ?.toInt();
          final lastCampaignCount =
              (settingsBox.get('crmLastCampaignCount') as num?)?.toInt() ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.crmBulkReminderTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HistoryRow(
                        label: l10n.crmLastVisitLabel,
                        value: _formatDateTime(lastCampaignAt),
                      ),
                      const SizedBox(height: 8),
                      _HistoryRow(
                        label: l10n.visits,
                        value: '$lastCampaignCount',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _repeatLastCampaign(
                    context,
                    clientsBox,
                    settingsBox,
                    l10n,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.crmBulkReminderButton),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.crmFilterAll),
                      selected: _filter == _HistoryFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _HistoryFilter.all),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.crmReminderButton),
                      selected: _filter == _HistoryFilter.single,
                      onSelected: (_) =>
                          setState(() => _filter = _HistoryFilter.single),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l10n.crmBulkReminderButton),
                      selected: _filter == _HistoryFilter.bulk,
                      onSelected: (_) =>
                          setState(() => _filter = _HistoryFilter.bulk),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.orderHistoryTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (filteredEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    l10n.orderHistoryEmpty,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...filteredEntries.take(40).map((entry) {
                  final type = entry['type'] == 'bulk'
                      ? l10n.crmBulkReminderButton
                      : l10n.crmReminderButton;
                  final subtitle = _formatDateTime(entry['at'] as int);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.sms_outlined),
                      title: Text(entry['name']?.toString() ?? '-'),
                      subtitle: Text(
                        '${entry['phone']?.toString() ?? ''}\n$subtitle',
                      ),
                      isThreeLine: true,
                      trailing: Text(type),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  static String _formatDateTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year} $hh:$min';
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
