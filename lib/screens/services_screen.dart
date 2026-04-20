import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/app_data_service.dart';
import '../core/constants.dart';
import '../widgets/confirm_dialog.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsBox = Hive.box(HiveBoxes.settings);

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box box, _) {
        final appRole = AppRole.fromStorage(
          box.get('appRole')?.toString(),
          mode: BusinessMode.fromStorage(box.get('businessMode')?.toString()),
        );
        final canManageBusinessData = appRole.canManageBusinessData;
        final currentCurrency = box
            .get('currency', defaultValue: '€')
            .toString();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsServicesSection),
            actions: [
              IconButton(
                tooltip: l10n.addOrder,
                onPressed: canManageBusinessData
                    ? () => _addService(context, l10n)
                    : () => _showAccessDenied(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder(
              valueListenable: Hive.box(HiveBoxes.services).listenable(),
              builder: (context, Box serviceBox, _) {
                if (serviceBox.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l10n.noOrdersTitle,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  children: serviceBox.keys.map((key) {
                    final service = serviceBox.get(key);
                    return _ServiceCard(
                      service: service,
                      serviceKey: key,
                      currency: currentCurrency,
                      l10n: l10n,
                      canManageBusinessData: canManageBusinessData,
                      onEdit: () => _editService(context, key, service, l10n),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: canManageBusinessData
                ? () => _addService(context, l10n)
                : () => _showAccessDenied(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addOrder),
          ),
        );
      },
    );
  }

  void _showAccessDenied(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsAccessDenied)));
  }

  void _addService(BuildContext context, AppLocalizations l10n) {
    final invBox = Hive.box(HiveBoxes.inventory);
    String name = '';
    double? price = 0;
    int duration = 0;
    List<String> selectedChemistry = [];
    int chemAmount = 0;
    String? nameError;
    String? priceError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.addOrder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (v) {
                    name = v;
                    if (nameError != null) {
                      setDialogState(() => nameError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    errorText: nameError,
                  ),
                ),
                TextField(
                  onChanged: (v) {
                    price = double.tryParse(v);
                    if (priceError != null) {
                      setDialogState(() => priceError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.statsRevenue,
                    errorText: priceError,
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  onChanged: (v) => duration = int.tryParse(v) ?? 0,
                  decoration: InputDecoration(
                    labelText: '${l10n.serviceFieldLabel} (min)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const Divider(height: 30),
                Text(
                  l10n.chemicalsButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (invBox.isEmpty)
                  Text(
                    l10n.inventoryEmptyTitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: invBox.values.map((i) {
                      final String chemName = i['name'].toString();
                      final isSelected = selectedChemistry.contains(chemName);
                      return FilterChip(
                        label: Text(
                          chemName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedChemistry.add(chemName);
                            } else {
                              selectedChemistry.remove(chemName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                if (selectedChemistry.isNotEmpty)
                  TextField(
                    onChanged: (v) => chemAmount = int.tryParse(v) ?? 0,
                    decoration: InputDecoration(labelText: l10n.volumeLabel),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                String? ne;
                String? pe;
                if (name.trim().isEmpty) {
                  ne = l10n.enterServiceName;
                }
                if (price == null || price! < 0) {
                  pe = l10n.invalidPrice;
                }
                if (ne != null || pe != null) {
                  setDialogState(() {
                    nameError = ne;
                    priceError = pe;
                  });
                  return;
                }
                final serviceId = DateTime.now().microsecondsSinceEpoch
                    .toString();
                final serviceMap = <String, dynamic>{
                  'id': serviceId,
                  'name': name.trim(),
                  'price': price,
                  'duration': duration,
                  'chemistry': selectedChemistry,
                  'chemAmount': chemAmount,
                };
                Hive.box(HiveBoxes.services).add(serviceMap);
                unawaited(AppDataService.syncServiceToCloud(serviceMap));
                Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _editService(
    BuildContext context,
    dynamic key,
    Map service,
    AppLocalizations l10n,
  ) {
    final invBox = Hive.box(HiveBoxes.inventory);
    final nameCtrl = TextEditingController(
      text: service['name']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (service['price'] as num?)?.toString() ?? '0',
    );
    final durationCtrl = TextEditingController(
      text: (service['duration'] as num?)?.toString() ?? '0',
    );
    final chemAmountCtrl = TextEditingController(
      text: (service['chemAmount'] as num?)?.toString() ?? '0',
    );

    final List<String> selectedChemistry =
        ((service['chemistry'] as List?) ?? [])
            .map((e) => e.toString())
            .toList();

    String? nameError;
    String? priceError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.edit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  onChanged: (_) {
                    if (nameError != null) {
                      setDialogState(() => nameError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    errorText: nameError,
                  ),
                ),
                TextField(
                  controller: priceCtrl,
                  onChanged: (_) {
                    if (priceError != null) {
                      setDialogState(() => priceError = null);
                    }
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.statsRevenue,
                    errorText: priceError,
                  ),
                ),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${l10n.serviceFieldLabel} (min)',
                  ),
                ),
                const Divider(height: 30),
                Text(
                  l10n.chemicalsButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (invBox.isEmpty)
                  Text(
                    l10n.inventoryEmptyTitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: invBox.values.map((i) {
                      final String chemName = i['name'].toString();
                      final isSelected = selectedChemistry.contains(chemName);
                      return FilterChip(
                        label: Text(
                          chemName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedChemistry.add(chemName);
                            } else {
                              selectedChemistry.remove(chemName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                if (selectedChemistry.isNotEmpty)
                  TextField(
                    controller: chemAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.volumeLabel),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final parsedPrice = double.tryParse(priceCtrl.text);
                String? ne;
                String? pe;
                if (nameCtrl.text.trim().isEmpty) {
                  ne = l10n.enterServiceName;
                }
                if (parsedPrice == null || parsedPrice < 0) {
                  pe = l10n.invalidPrice;
                }
                if (ne != null || pe != null) {
                  setDialogState(() {
                    nameError = ne;
                    priceError = pe;
                  });
                  return;
                }
                final updated = Map<String, dynamic>.from(service);
                updated['name'] = nameCtrl.text.trim();
                updated['price'] = parsedPrice;
                updated['duration'] = int.tryParse(durationCtrl.text) ?? 0;
                updated['chemistry'] = selectedChemistry;
                updated['chemAmount'] = int.tryParse(chemAmountCtrl.text) ?? 0;
                updated['id'] = updated['id']?.toString().isNotEmpty == true
                    ? updated['id']
                    : DateTime.now().microsecondsSinceEpoch.toString();
                Hive.box(HiveBoxes.services).put(key, updated);
                unawaited(AppDataService.syncServiceToCloud(updated));
                Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map service;
  final dynamic serviceKey;
  final String currency;
  final AppLocalizations l10n;
  final bool canManageBusinessData;
  final VoidCallback onEdit;

  const _ServiceCard({
    required this.service,
    required this.serviceKey,
    required this.currency,
    required this.l10n,
    required this.canManageBusinessData,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(serviceKey.toString()),
      direction: canManageBusinessData
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) {
        if (!canManageBusinessData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsServiceDeleteDenied)),
          );
          return Future.value(false);
        }
        return ConfirmDialog.show(
          context: context,
          title: l10n.deleteItemTitle,
          message: l10n.deleteItemMessage(service['name']),
          confirmText: l10n.delete,
        );
      },
      onDismissed: (_) {
        if (canManageBusinessData) {
          final serviceId = service['id']?.toString();
          Hive.box(HiveBoxes.services).delete(serviceKey);
          unawaited(AppDataService.deleteServiceFromCloud(serviceId));
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            service['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${service['duration']} ${l10n.durationMinutesShort}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${service['price']} $currency',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: canManageBusinessData
                    ? onEdit
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.settingsServiceEditDenied),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
