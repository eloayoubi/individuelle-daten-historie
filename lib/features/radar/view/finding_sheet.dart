import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../data/cancellation_letter.dart';
import '../data/radar.dart';
import 'radar_rows.dart';

/// Was der Nutzer mit einem Fund tun will.
enum FindingAction { open, letter, dismiss }

/// Ein Fund des Radars: wie er gerechnet ist und was sich tun lässt. Das Ergebnis kommt als
/// [FindingAction] zurück, die Übersicht führt es aus.
class FindingSheet extends StatelessWidget {
  const FindingSheet({super.key, required this.finding});

  final Finding finding;

  static Future<FindingAction?> show(BuildContext context, Finding finding) =>
      AppSheet.show<FindingAction>(context, title: context.findingTitle(finding), child: FindingSheet(finding: finding));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deadline = finding.kind == FindingKind.deadline;
    void done(FindingAction action) => Navigator.of(context).pop(action);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.s,
        children: [
          AppText(l10n.radarHow, style: (t) => t.footnote, color: context.colors.textSecondary),
          AppText(context.findingExplanation(finding), style: (t) => t.body),
          const SizedBox(height: Spacing.s),
          if (deadline) AppButton(label: l10n.radarLetter, icon: CupertinoIcons.doc_text, onPressed: () => done(FindingAction.letter)),
          AppButton(label: l10n.radarOpen, variant: deadline ? AppButtonVariant.tinted : AppButtonVariant.filled, onPressed: () => done(FindingAction.open)),
          AppButton(label: l10n.radarDismiss, variant: AppButtonVariant.plain, onPressed: () => done(FindingAction.dismiss)),
        ],
      ),
    );
  }
}

/// Kündigungsschreiben als Vorlage zum Teilen oder Kopieren. Der Text entsteht auf dem Gerät
/// ([CancellationLetter]); die App verschickt nichts selbst.
class CancellationSheet extends StatelessWidget {
  const CancellationSheet({super.key, required this.text});

  final String text;

  /// `true`, wenn der Text kopiert wurde – die Übersicht bestätigt es dann.
  static Future<bool> show(BuildContext context, {required Category category, required Tracker tracker, required DateTime today}) async {
    final text = CancellationLetter.build(context.l10n, category: category, tracker: tracker, today: today);
    return await AppSheet.show<bool>(context, title: context.l10n.radarLetterTitle, child: CancellationSheet(text: text)) ?? false;
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          AppText(l10n.radarLetterHint, style: (t) => t.footnote, color: c.textSecondary),
          Flexible(
            child: AppCard(
              color: c.surfaceRaised,
              child: SingleChildScrollView(child: AppText(text, style: (t) => t.subheadline)),
            ),
          ),
          // Eigener Context: Das Teilen-Sheet braucht auf dem iPad den Knopf als Ursprung.
          Builder(
            builder: (button) => AppButton(label: l10n.radarLetterShare, icon: CupertinoIcons.share, onPressed: () => AppShare.text(button, text)),
          ),
          AppButton(label: l10n.radarLetterCopy, icon: CupertinoIcons.doc_on_doc, variant: AppButtonVariant.tinted, onPressed: () => _copy(context)),
        ],
      ),
    );
  }
}
