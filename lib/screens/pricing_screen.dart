import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants.dart';
import '../core/revenuecat_config.dart';
import '../core/revenuecat_service.dart';
import '../core/subscription_texts.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box(HiveBoxes.settings);

    return Scaffold(
      appBar: AppBar(
        title: Text(SubscriptionTexts.pricingTitle(context)),
        backgroundColor: AppColors.surface,
      ),
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(
          keys: ['appPlan', 'planStatus'],
        ),
        builder: (context, Box box, _) {
          final currentPlan = AppPlan.fromStorage(
            box.get('appPlan')?.toString(),
          );
          final planStatus = PlanStatus.fromStorage(
            box.get('planStatus')?.toString(),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _IntroCard(currentPlan: currentPlan, planStatus: planStatus),
              const SizedBox(height: 16),
              _PlanCard(
                title: SubscriptionTexts.planName(context, AppPlan.free),
                price: SubscriptionTexts.planPrice(context, AppPlan.free),
                accent: AppColors.info,
                currentPlan: currentPlan,
                plan: AppPlan.free,
                description: SubscriptionTexts.planDescription(
                  context,
                  AppPlan.free,
                ),
                features: SubscriptionTexts.planFeatures(context, AppPlan.free),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                title: SubscriptionTexts.planName(context, AppPlan.pro),
                price: SubscriptionTexts.planPrice(context, AppPlan.pro),
                accent: AppColors.primary,
                currentPlan: currentPlan,
                plan: AppPlan.pro,
                highlighted: true,
                purchasable: true,
                description: SubscriptionTexts.planDescription(
                  context,
                  AppPlan.pro,
                ),
                features: SubscriptionTexts.planFeatures(context, AppPlan.pro),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                title: SubscriptionTexts.planName(context, AppPlan.business),
                price: SubscriptionTexts.planPrice(context, AppPlan.business),
                accent: AppColors.success,
                currentPlan: currentPlan,
                plan: AppPlan.business,
                purchasable: true,
                description: SubscriptionTexts.planDescription(
                  context,
                  AppPlan.business,
                ),
                features: SubscriptionTexts.planFeatures(
                  context,
                  AppPlan.business,
                ),
              ),
              const SizedBox(height: 20),
              const _NextStepCard(),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.currentPlan, required this.planStatus});

  final AppPlan currentPlan;
  final PlanStatus planStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SubscriptionTexts.pricingIntroTitle(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(SubscriptionTexts.pricingIntroBody(context)),
            const SizedBox(height: 12),
            Text(
              SubscriptionTexts.currentPlanLine(
                context,
                currentPlan,
                planStatus,
              ),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.description,
    required this.features,
    required this.accent,
    required this.plan,
    required this.currentPlan,
    this.highlighted = false,
    this.purchasable = false,
  });

  final String title;
  final String price;
  final String description;
  final List<String> features;
  final Color accent;
  final AppPlan plan;
  final AppPlan currentPlan;
  final bool highlighted;
  final bool purchasable;

  Future<void> _purchase(BuildContext context) async {
    if (!RevenueCatConfig.isEnabledForCurrentPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RevenueCat is not configured yet (add SDK key).'),
        ),
      );
      return;
    }

    try {
      await RevenueCatService.purchasePlan(plan);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan ${plan.name.toUpperCase()} activated.')),
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: highlighted ? accent : Colors.white12,
          width: highlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (currentPlan == plan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      SubscriptionTexts.currentBadge(context),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      SubscriptionTexts.recommendedBadge(context),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
            if (purchasable && currentPlan != plan) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _purchase(context),
                  child: Text('Choose ${title.toUpperCase()}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SubscriptionTexts.nextStepTitle(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(SubscriptionTexts.nextStepBody(context)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (!RevenueCatConfig.isEnabledForCurrentPlatform) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'RevenueCat is not configured yet (add SDK key).',
                        ),
                      ),
                    );
                    return;
                  }
                  try {
                    await RevenueCatService.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Purchases restored.')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restore failed: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.restore),
                label: const Text('Restore purchases'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
