import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  static const _privacyUrl =
      'https://detailing-pro.web.app/privacy-policy.html';
  static const _termsUrl = 'https://detailing-pro.web.app/terms.html';

  Future<void> _openUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.legalOpenLinkError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.legalTitle),
          backgroundColor: AppColors.surface,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.legalPrivacyTab),
              Tab(text: l10n.legalTermsTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LegalTextView(
              header: _LegalHeader(
                title: l10n.legalPrivacySummaryTitle,
                subtitle: l10n.legalSummarySubtitle,
                actionLabel: l10n.legalOpenFullPrivacy,
                onTap: () => _openUrl(context, _privacyUrl),
              ),
              sections: _privacySections(l10n),
            ),
            _LegalTextView(
              header: _LegalHeader(
                title: l10n.legalTermsSummaryTitle,
                subtitle: l10n.legalSummarySubtitle,
                actionLabel: l10n.legalOpenFullTerms,
                onTap: () => _openUrl(context, _termsUrl),
              ),
              sections: _termsSections(l10n),
            ),
          ],
        ),
      ),
    );
  }

  List<_LegalSection> _privacySections(AppLocalizations l10n) {
    return [
      _LegalSection(
        title: l10n.legalPrivacySection1Title,
        body: l10n.legalPrivacySection1Body,
      ),
      _LegalSection(
        title: l10n.legalPrivacySection2Title,
        body: l10n.legalPrivacySection2Body,
      ),
      _LegalSection(
        title: l10n.legalPrivacySection3Title,
        body: l10n.legalPrivacySection3Body,
      ),
      _LegalSection(
        title: l10n.legalPrivacySection4Title,
        body: l10n.legalPrivacySection4Body,
      ),
      _LegalSection(
        title: l10n.legalPrivacySection5Title,
        body: l10n.legalPrivacySection5Body,
      ),
      _LegalSection(
        title: l10n.legalPrivacySection6Title,
        body: l10n.legalPrivacySection6Body,
      ),
      _LegalSection(
        title: l10n.legalPrivacySection7Title,
        body: l10n.legalPrivacySection7Body,
      ),
    ];
  }

  List<_LegalSection> _termsSections(AppLocalizations l10n) {
    return [
      _LegalSection(
        title: l10n.legalTermsSection1Title,
        body: l10n.legalTermsSection1Body,
      ),
      _LegalSection(
        title: l10n.legalTermsSection2Title,
        body: l10n.legalTermsSection2Body,
      ),
      _LegalSection(
        title: l10n.legalTermsSection3Title,
        body: l10n.legalTermsSection3Body,
      ),
      _LegalSection(
        title: l10n.legalTermsSection4Title,
        body: l10n.legalTermsSection4Body,
      ),
      _LegalSection(
        title: l10n.legalTermsSection5Title,
        body: l10n.legalTermsSection5Body,
      ),
      _LegalSection(
        title: l10n.legalTermsSection6Title,
        body: l10n.legalTermsSection6Body,
      ),
      _LegalSection(
        title: l10n.legalTermsSection7Title,
        body: l10n.legalTermsSection7Body,
      ),
    ];
  }
}

class _LegalTextView extends StatelessWidget {
  const _LegalTextView({required this.sections, this.header});

  final List<_LegalSection> sections;
  final _LegalHeader? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (header != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    header!.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(header!.subtitle),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: header!.onTap,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(header!.actionLabel),
                  ),
                ],
              ),
            ),
          ),
        if (header != null) const SizedBox(height: 12),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(section.body),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalHeader {
  const _LegalHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
