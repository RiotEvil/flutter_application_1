import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/cloud_profile_sync.dart';
import '../core/access_guard.dart';
import '../core/constants.dart';
import '../core/invite_service.dart';
import '../core/subscription_texts.dart';
import '../widgets/confirm_dialog.dart';
import 'add_client_screen.dart';
import 'booking_requests_screen.dart';
import 'legal_documents_screen.dart';
import 'pricing_screen.dart';
import 'services_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Весь мировой запас валют для твоего детейлинга
  final List<String> _currencies = ['€', 'zł', '\$', '₽', '₺', 'R', '¥', '₴'];

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box box, _) {
        final String currentCurr = box.get('currency', defaultValue: '€');
        final String currentLocale = box.get('locale', defaultValue: 'en');
        final businessMode = BusinessMode.fromStorage(
          box.get('businessMode')?.toString(),
        );
        final authUserLabel =
            box.get('authUserLabel')?.toString() ?? l10n.authGuestName;
        final authMode = box
            .get('authMode', defaultValue: 'firebase')
            ?.toString();
        final appRole = AppRole.fromStorage(
          box.get('appRole')?.toString(),
          mode: businessMode,
        );
        final appPlan = AppPlan.fromStorage(box.get('appPlan')?.toString());
        final planStatus = PlanStatus.fromStorage(
          box.get('planStatus')?.toString(),
        );
        final canManageBusinessData = appRole.canManageBusinessData;
        final companyName =
            box.get('companyName', defaultValue: '')?.toString() ?? '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- СЕКЦИЯ ОСНОВНЫХ НАСТРОЕК ---
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.account_circle_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.settingsProfileAndOrgTitle),
                    subtitle: Text(
                      l10n.settingsProfileAndOrgSubtitle(
                        authMode == 'firebase'
                            ? l10n.settingsAuthModeFirebase
                            : l10n.settingsAuthModeGuest,
                        authUserLabel,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Выбор валюты
                  ListTile(
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.currencyLabel),
                    trailing: DropdownButton<String>(
                      value: currentCurr,
                      underline: const SizedBox(),
                      items: _currencies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => settingsBox.put('currency', v),
                    ),
                  ),
                  const Divider(height: 1),

                  // Выбор языка (Все 10 языков)
                  ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.languageLabel),
                    trailing: DropdownButton<String>(
                      value: currentLocale,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'ru',
                          child: Text("🇷🇺 ${l10n.languageRussian}"),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text("🇺🇸 ${l10n.languageEnglish}"),
                        ),
                        const DropdownMenuItem(
                          value: 'uk',
                          child: Text("🇺🇦 Українська"),
                        ),
                        DropdownMenuItem(
                          value: 'pl',
                          child: const Text("🇵🇱 Polski"),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: const Text("🇩🇪 Deutsch"),
                        ),
                        DropdownMenuItem(
                          value: 'it',
                          child: const Text("🇮🇹 Italiano"),
                        ),
                        DropdownMenuItem(
                          value: 'es',
                          child: const Text("🇪🇸 Español"),
                        ),
                        DropdownMenuItem(
                          value: 'pt',
                          child: const Text("🇵🇹 Português"),
                        ),
                        DropdownMenuItem(
                          value: 'tr',
                          child: const Text("🇹🇷 Türkçe"),
                        ),
                        DropdownMenuItem(
                          value: 'zh',
                          child: const Text("🇨🇳 简体中文"),
                        ),
                      ],
                      onChanged: (v) => settingsBox.put('locale', v),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.business_center_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(l10n.settingsBusinessModeTitle),
                    subtitle: Text(_businessModeLabel(businessMode, l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: canManageBusinessData
                        ? () => _changeBusinessMode(context, settingsBox)
                        : () => _showAccessDenied(context),
                  ),
                  if (businessMode == BusinessMode.team &&
                      canManageBusinessData) ...[
                    const Divider(height: 1),
                    // Кнопка генерации инвайта — видна только директору
                    if (appRole == AppRole.director) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.group_add_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(l10n.settingsInviteMasterTitle),
                        subtitle: Text(l10n.settingsInviteMasterSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _generateInviteCode(context, settingsBox),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: l10n.quickActions.toUpperCase()),
            const SizedBox(height: 12),

            // Кнопки быстрых действий
            _ActionButton(
              icon: Icons.person_add,
              label: l10n.newClient,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddClientScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.design_services_outlined,
              label: l10n.settingsServicesSection,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.link,
              label: l10n.settingsBookingLinkTitle,
              onTap: () {
                if (!AccessGuard.canUseOnlineBooking()) {
                  AccessGuard.showUpgradePrompt(
                    context,
                    title: SubscriptionTexts.bookingProTitle(context),
                    message: SubscriptionTexts.bookingProMessage(context),
                    requiredPlan: AppPlan.pro,
                  );
                  return;
                }
                _showBookingLinkDialog(context);
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.inbox_outlined,
              label: l10n.settingsBookingRequestsTitle,
              onTap: () {
                if (!AccessGuard.canUseOnlineBooking()) {
                  AccessGuard.showUpgradePrompt(
                    context,
                    title: SubscriptionTexts.bookingProTitle(context),
                    message: SubscriptionTexts.bookingProMessage(context),
                    requiredPlan: AppPlan.pro,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingRequestsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            _SectionHeader(title: l10n.invoiceCompanyDataTitle.toUpperCase()),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.invoiceCompanyDataTitle),
                subtitle: Text(
                  companyName.isEmpty
                      ? l10n.invoiceCompanyDataSubtitle
                      : companyName,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editCompanyData(context, settingsBox),
              ),
            ),

            const Divider(height: 40, color: Colors.white24),
            _SectionHeader(
              title: SubscriptionTexts.releaseSectionTitle(context),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(SubscriptionTexts.plansAndPricing(context)),
                    subtitle: Text(
                      SubscriptionTexts.currentPlanLine(
                        context,
                        appPlan,
                        planStatus,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PricingScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.gavel_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(SubscriptionTexts.legalDocumentsTitle(context)),
                    subtitle: Text(
                      SubscriptionTexts.legalDocumentsSubtitle(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalDocumentsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _logout(context, settingsBox),
              icon: const Icon(Icons.logout_outlined),
              label: Text(l10n.settingsLogoutButton),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            // Кнопка опасной зоны
            OutlinedButton.icon(
              onPressed: canManageBusinessData
                  ? () => _resetData(context, l10n)
                  : () => _showAccessDenied(context),
              icon: const Icon(Icons.delete_sweep, color: AppColors.error),
              label: Text(
                l10n.delete,
                style: const TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        );
      },
    );
  }

  String _businessModeLabel(BusinessMode? mode, AppLocalizations l10n) {
    if (mode == BusinessMode.team) {
      return l10n.settingsBusinessModeTeam;
    }
    return l10n.settingsBusinessModeSolo;
  }

  Future<void> _changeBusinessMode(
    BuildContext context,
    Box settingsBox,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedMode = await showDialog<BusinessMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsSelectModeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.settingsModeSoloTitle),
              subtitle: Text(l10n.settingsModeSoloSubtitle),
              onTap: () => Navigator.pop(ctx, BusinessMode.solo),
            ),
            ListTile(
              leading: const Icon(Icons.groups_2_outlined),
              title: Text(l10n.settingsModeTeamTitle),
              subtitle: Text(l10n.settingsModeTeamSubtitle),
              onTap: () => Navigator.pop(ctx, BusinessMode.team),
            ),
          ],
        ),
      ),
    );

    if (selectedMode == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    if (selectedMode == BusinessMode.team &&
        !AccessGuard.canUseTeamWorkspace()) {
      await AccessGuard.showUpgradePrompt(
        context,
        title: SubscriptionTexts.businessPlanRequiredTitle(context),
        message: SubscriptionTexts.teamWorkspaceBusinessMessage(context),
        requiredPlan: AppPlan.business,
      );
      return;
    }

    await settingsBox.put('businessMode', selectedMode.name);
    final role = selectedMode == BusinessMode.team
        ? AppRole.director
        : AppRole.masterOwner;
    await settingsBox.put('appRole', role.name);
    await CloudProfileSync.syncBusinessMode(selectedMode);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsModeUpdated)));
  }

  Future<void> _generateInviteCode(
    BuildContext context,
    Box settingsBox,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final orgId = settingsBox.get('orgId')?.toString();
    if (orgId == null || orgId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsOrgNotFound)));
      }
      return;
    }

    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user == null) return;

    String code;
    try {
      code = await InviteService.generateInviteCode(
        orgId: orgId,
        directorUid: user.uid,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsInviteGenerateError(e.toString())),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsInviteDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.settingsInviteDialogDescription),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: l10n.settingsCopy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(l10n.settingsCodeCopied)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.settingsInviteRegistrationHint,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  Future<void> _editCompanyData(BuildContext context, Box settingsBox) async {
    final l10n = AppLocalizations.of(context)!;
    final locale =
        settingsBox.get('locale', defaultValue: 'en')?.toString() ?? 'en';
    final invoicePrimaryIdLabel = _invoicePrimaryIdLabel(locale);
    final invoiceSecondaryIdLabel = _invoiceSecondaryIdLabel(locale);
    final nameCtrl = TextEditingController(
      text: settingsBox.get('companyName', defaultValue: '') as String,
    );
    final nipCtrl = TextEditingController(
      text: settingsBox.get('companyNip', defaultValue: '') as String,
    );
    final regonCtrl = TextEditingController(
      text: settingsBox.get('companyRegon', defaultValue: '') as String,
    );
    final addrCtrl = TextEditingController(
      text: settingsBox.get('companyAddress', defaultValue: '') as String,
    );
    final postalCtrl = TextEditingController(
      text: settingsBox.get('companyPostalCode', defaultValue: '') as String,
    );
    final cityCtrl = TextEditingController(
      text: settingsBox.get('companyCity', defaultValue: '') as String,
    );
    final vatRateCtrl = TextEditingController(
      text: ((settingsBox.get('companyVatRate') as num?)?.toDouble() ?? 23.0)
          .toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.invoiceCompanyDataTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.invoiceCompanyName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nipCtrl,
                decoration: InputDecoration(labelText: invoicePrimaryIdLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: regonCtrl,
                decoration: InputDecoration(labelText: invoiceSecondaryIdLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addrCtrl,
                decoration: InputDecoration(
                  labelText: l10n.invoiceCompanyAddress,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: postalCtrl,
                decoration: InputDecoration(
                  labelText: l10n.invoiceCompanyPostalCode,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cityCtrl,
                decoration: InputDecoration(labelText: l10n.invoiceCompanyCity),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vatRateCtrl,
                decoration: InputDecoration(
                  labelText: l10n.invoiceVatRate,
                  suffixText: '%',
                ),
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
          TextButton(
            onPressed: () async {
              await settingsBox.put('companyName', nameCtrl.text.trim());
              await settingsBox.put('companyNip', nipCtrl.text.trim());
              await settingsBox.put('companyRegon', regonCtrl.text.trim());
              await settingsBox.put('companyAddress', addrCtrl.text.trim());
              await settingsBox.put(
                'companyPostalCode',
                postalCtrl.text.trim(),
              );
              await settingsBox.put('companyCity', cityCtrl.text.trim());
              final parsedVat = double.tryParse(
                vatRateCtrl.text.trim().replaceAll(',', '.'),
              );
              if (parsedVat != null && parsedVat > 0) {
                await settingsBox.put('companyVatRate', parsedVat);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    nipCtrl.dispose();
    regonCtrl.dispose();
    addrCtrl.dispose();
    postalCtrl.dispose();
    cityCtrl.dispose();
    vatRateCtrl.dispose();
  }

  Future<void> _showBookingLinkDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsBookingLinkAuthRequired)),
        );
      }
      return;
    }

    final locale =
        Hive.box(
          HiveBoxes.settings,
        ).get('locale', defaultValue: 'en')?.toString() ??
        'en';
    final settings = Hive.box(HiveBoxes.settings);
    final companyName = settings.get('companyName')?.toString().trim();
    final bookingName = companyName != null && companyName.isNotEmpty
        ? companyName
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : (user.email?.trim().isNotEmpty == true
                    ? user.email!.trim()
                    : 'Detailing Pro'));
    final link = Uri.https('detailing-pro.web.app', '/book.html', {
      'uid': user.uid,
      'locale': locale,
      'name': bookingName,
    }).toString();

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsBookingLinkDialogTitle),
        content: SelectableText(link),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.settingsBookingLinkCopied)),
                );
              }
            },
            child: Text(l10n.settingsCopy),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(link);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(l10n.settingsBookingLinkOpen),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  String _invoicePrimaryIdLabel(String locale) {
    switch (locale) {
      case 'pl':
        return 'NIP';
      case 'de':
        return 'USt-IdNr.';
      case 'it':
        return 'Partita IVA';
      case 'es':
        return 'NIF/CIF';
      case 'pt':
        return 'NIF';
      case 'tr':
        return 'Vergi No';
      case 'zh':
        return '税号';
      case 'ru':
        return 'ИНН';
      default:
        return 'Tax ID';
    }
  }

  String _invoiceSecondaryIdLabel(String locale) {
    switch (locale) {
      case 'pl':
        return 'REGON';
      case 'de':
        return 'Handelsregisternr.';
      case 'it':
        return 'Codice fiscale';
      case 'es':
        return 'Registro mercantil';
      case 'pt':
        return 'Registo comercial';
      case 'tr':
        return 'Şirket sicil no';
      case 'zh':
        return '工商注册号';
      case 'ru':
        return 'ОГРН';
      default:
        return 'Business ID';
    }
  }

  Future<void> _logout(BuildContext context, Box settingsBox) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.settingsLogoutTitle,
      message: l10n.settingsLogoutMessage,
      confirmText: l10n.settingsLogoutConfirm,
    );

    if (confirmed != true) {
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }

    await settingsBox.put('isLoggedIn', false);
    await settingsBox.put('authMode', 'firebase');
    await settingsBox.delete('authUserLabel');
    await settingsBox.delete('authUid');
    await settingsBox.delete('businessMode');
    await settingsBox.delete('appRole');
    await settingsBox.delete('orgId');
    await settingsBox.put('appPlan', AppPlan.free.name);
    await settingsBox.put('planStatus', PlanStatus.inactive.name);
    await settingsBox.delete('billingProvider');

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsLoggedOut)));
  }

  void _showAccessDenied(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsAccessDenied)));
  }

  Future<void> _resetData(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.deleteItemTitle,
      message: l10n.settingsResetWarning,
      confirmText: l10n.delete,
      confirmColor: AppColors.error,
    );
    if (confirmed == true) {
      await Hive.box(HiveBoxes.orders).clear();
      await Hive.box(HiveBoxes.services).clear();
      await Hive.box(HiveBoxes.inventory).clear();
      await Hive.box(HiveBoxes.clients).clear();
    }
  }
}

// --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
