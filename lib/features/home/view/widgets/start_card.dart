import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';

/// Statt leerer Prognose: Kategorien sind angelegt, aber es gibt noch keinen Eintrag.
/// Zeigt die drei Schritte bis zur Kostenkurve und führt direkt zum ersten Eintrag.
class StartCard extends StatelessWidget {
  const StartCard({super.key, required this.year, this.onAdd});

  final int year;

  /// `null`, wenn nichts erfassbar ist (z. B. nur geteilte Kategorien zum Ansehen).
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        color: c.spotlight,
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: Spacing.s,
              children: [
                Icon(CupertinoIcons.sparkles, size: 16, color: c.spotlightAccent),
                Expanded(
                  child: AppText(l10n.homeStartOverline.toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.onSpotlightSecondary, maxLines: 1),
                ),
              ],
            ),
            const SizedBox(height: Spacing.m),
            AppText(l10n.homeStartTitle, style: (t) => t.title3, color: c.onSpotlight),
            const SizedBox(height: Spacing.xs),
            AppText(l10n.homeStartBody, style: (t) => t.footnote, color: c.onSpotlightSecondary),
            const SizedBox(height: Spacing.xl),
            _Step(label: l10n.homeStartStepCategories, state: _StepState.done),
            _Step(label: l10n.homeStartStepEntry, state: _StepState.current),
            _Step(label: l10n.homeStartStepForecast('${year + 1}'), state: _StepState.next, last: true),
            if (onAdd != null) ...[
              const SizedBox(height: Spacing.xl),
              AppButton(label: l10n.homeStartAction, icon: CupertinoIcons.plus, onPressed: onAdd),
            ],
          ],
        ),
      ),
    );
  }
}

enum _StepState { done, current, next }

/// Ein Schritt mit Punkt links; die Punkte verbindet eine feine Linie.
class _Step extends StatelessWidget {
  const _Step({required this.label, required this.state, this.last = false});

  static const _dot = 22.0;

  final String label;
  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = Container(
      width: _dot,
      height: _dot,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == _StepState.done ? c.spotlightSuccess : null,
        border: state == _StepState.done ? null : Border.all(color: state == _StepState.current ? c.spotlightAccent : c.spotlightLine, width: 2),
      ),
      child: switch (state) {
        _StepState.done => Icon(CupertinoIcons.checkmark, size: 13, color: c.spotlight),
        _StepState.current => Center(
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.spotlightAccent, shape: BoxShape.circle)),
        ),
        _StepState.next => null,
      },
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          Column(
            children: [
              dot,
              if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: c.spotlightLine)),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: last ? 0 : Spacing.l),
              child: AppText(
                label,
                style: (t) => state == _StepState.current ? t.headline : t.body,
                color: state == _StepState.current ? c.onSpotlight : c.onSpotlightSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
