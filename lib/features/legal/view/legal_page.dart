import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../data/legal_document.dart';

/// Datenschutz, Nutzungsbedingungen oder Impressum aus `assets/legal/` – funktioniert offline,
/// wie es Apple für die Links auf der Abo-Seite verlangt.
class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.document});

  final LegalDocument document;

  static Future<void> open(BuildContext context, LegalDocument document) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => LegalPage(document: document)));

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  String? _asset;
  late Future<String> _text;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final asset = widget.document.asset(Localizations.localeOf(context).languageCode);
    if (asset == _asset) return;
    _asset = asset;
    // Ohne Cache: selten geöffnet, und so bleibt kein Future aus einer früheren Zone hängen.
    _text = DefaultAssetBundle.of(context).loadString(asset, cache: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final title = switch (widget.document) {
      LegalDocument.privacy => l10n.legalPrivacy,
      LegalDocument.terms => l10n.legalTerms,
      LegalDocument.imprint => l10n.legalImprint,
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder(
          future: _text,
          builder: (context, snap) {
            final blocks = parseLegal(snap.data ?? '');
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
              children: [
                AppHeader(title: title, onBack: () => Navigator.of(context).pop()),
                if (!snap.hasData) const Center(child: CupertinoActivityIndicator()),
                for (final block in blocks)
                  switch (block) {
                    // Der Titel steht schon im Kopf.
                    LegalTitle() => const SizedBox.shrink(),
                    LegalHeading(:final text) => Padding(
                      padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xl, Spacing.l, Spacing.xs),
                      child: AppText(text, style: (t) => t.headline),
                    ),
                    LegalParagraph(:final text) => Padding(
                      padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xs, Spacing.l, Spacing.xs),
                      child: AppText(text, style: (t) => t.subheadline, color: c.textSecondary),
                    ),
                    LegalBullet(:final text) => Padding(
                      padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxs, Spacing.l, Spacing.xxs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spacing.s,
                        children: [
                          AppText('•', style: (t) => t.subheadline, color: c.textSecondary),
                          Expanded(child: AppText(text, style: (t) => t.subheadline, color: c.textSecondary)),
                        ],
                      ),
                    ),
                  },
              ],
            );
          },
        ),
      ),
    );
  }
}
