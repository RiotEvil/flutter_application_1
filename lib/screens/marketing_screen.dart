import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/access_guard.dart';
import '../core/constants.dart';
import '../core/subscription_texts.dart';
import '../widgets/stat_card.dart';

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!AccessGuard.canUseMarketingTools()) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.navMarketing)),
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
                      SubscriptionTexts.marketingProTitle(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(SubscriptionTexts.marketingProMessage(context)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => AccessGuard.showUpgradePrompt(
                          context,
                          title: SubscriptionTexts.marketingProTitle(context),
                          message: SubscriptionTexts.marketingProMessage(
                            context,
                          ),
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

    final cBox = Hive.box(HiveBoxes.clients);
    final oBox = Hive.box(HiveBoxes.orders);

    // Анализ клиентов
    final clients = cBox.values.toList();
    final orders = oBox.values.toList();

    // Клиенты, которые давно не были
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final inactiveClients = <String>[];
    for (var client in clients) {
      final clientName = client['name'] ?? '';
      final lastOrder = orders.where((o) => o['client'] == clientName).toList();
      if (lastOrder.isEmpty) {
        inactiveClients.add(clientName);
      } else {
        lastOrder.sort((a, b) {
          final ta = a['timestamp'] ?? 0;
          final tb = b['timestamp'] ?? 0;
          return tb.compareTo(ta);
        });
        final lastDate = DateTime.fromMillisecondsSinceEpoch(
          lastOrder.first['timestamp'] ?? 0,
        );
        if (lastDate.isBefore(thirtyDaysAgo)) {
          inactiveClients.add(clientName);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.navMarketing)),

      // ... (внутри build метода MarketingScreen)
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Статистика (Компактная версия)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio:
                2.1, // Увеличили, чтобы карточки стали в два раза ниже
            children: [
              StatCard(
                title: l10n.statsTotalClients,
                value: '${clients.length}',
                icon: Icons.people,
                color: AppColors.info,
              ),
              StatCard(
                title: l10n.inactiveClients,
                value: '${inactiveClients.length}',
                icon: Icons.person_off,
                color: AppColors.warning,
              ),
            ],
          ),
          // ... (остальной код без изменений),
          const SizedBox(height: 16),
          _MarketingCard(
            icon: Icons.campaign,
            title: l10n.promotions,
            description: l10n.promotionsDescription,
            onTap: () => _showPromoDialog(context),
          ),
          _MarketingCard(
            icon: Icons.card_giftcard,
            title: l10n.loyaltyProgram,
            description: l10n.loyaltyDescription,
            onTap: () => _showLoyaltyDialog(context),
          ),
          _MarketingCard(
            icon: Icons.sms,
            title: l10n.smsBroadcast,
            description: l10n.smsDescription,
            onTap: () => _showSmsDialog(context),
          ),
          _MarketingCard(
            icon: Icons.reviews,
            title: l10n.reviews,
            description: l10n.reviewsDescription,
            onTap: () => _showReviewsDialog(context),
          ),
        ],
      ),
    );
  }

  void _showPromoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _showComingSoonDialog(context, l10n.promotions);
  }

  void _showLoyaltyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _showComingSoonDialog(context, l10n.loyaltyProgram);
  }

  void _showSmsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _showComingSoonDialog(context, l10n.smsBroadcast);
  }

  void _showReviewsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _showComingSoonDialog(context, l10n.reviews);
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(feature),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }
}

class _MarketingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MarketingCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
