import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

import '../core/access_guard.dart';
import '../core/constants.dart';
import '../core/subscription_texts.dart';

class BusinessModeScreen extends StatelessWidget {
  final ValueChanged<BusinessMode> onModeSelected;

  const BusinessModeScreen({super.key, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.businessModeQuestion,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.businessModeSubtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  _ModeCard(
                    icon: Icons.person_outline,
                    title: l10n.businessModeSoloTitle,
                    subtitle: l10n.businessModeSoloSubtitle,
                    onTap: () => onModeSelected(BusinessMode.solo),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.groups_2_outlined,
                    title: l10n.businessModeTeamTitle,
                    subtitle: l10n.businessModeTeamSubtitle,
                    onTap: () {
                      if (!AccessGuard.canUseTeamWorkspace()) {
                        AccessGuard.showUpgradePrompt(
                          context,
                          title: SubscriptionTexts.businessPlanRequiredTitle(
                            context,
                          ),
                          message:
                              SubscriptionTexts.teamWorkspaceBusinessMessage(
                                context,
                              ),
                          requiredPlan: AppPlan.business,
                        );
                        return;
                      }
                      onModeSelected(BusinessMode.team);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
