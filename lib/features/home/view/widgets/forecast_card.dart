import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../data/home_overview.dart';
import 'cost_curve.dart';

/// Dunkle Hervorhebung oben: Prognose fürs nächste Jahr mit der Kostenkurve.
class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key, required this.overview});

  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final change = context.change(overview.forecastChange);
    final trend = overview.forecastChange.trend;
    final next = '${overview.year + 1}';
    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        color: c.spotlight,
        padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.xl, Spacing.xl, Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: Spacing.s,
              children: [
                Icon(CupertinoIcons.sparkles, size: 16, color: c.spotlightAccent),
                Expanded(
                  child: AppText(l10n.homeForecastTitle(next).toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.onSpotlightSecondary, maxLines: 1),
                ),
                if (change != null)
                  AppChip(
                    label: l10n.homeForecastDelta(change, '${overview.year}'),
                    icon: switch (trend) {
                      1 => CupertinoIcons.arrow_up_right,
                      -1 => CupertinoIcons.arrow_down_right,
                      _ => CupertinoIcons.arrow_right,
                    },
                    background: c.spotlightLine,
                    // Steigende Kosten sind schlecht, fallende gut.
                    foreground: switch (trend) {
                      1 => c.spotlightDanger,
                      -1 => c.spotlightSuccess,
                      _ => c.onSpotlightSecondary,
                    },
                  ),
              ],
            ),
            const SizedBox(height: Spacing.s),
            AppText(context.euros(overview.forecast), style: (t) => t.numberXL, color: c.onSpotlight, maxLines: 1),
            const SizedBox(height: Spacing.xxs),
            if (overview.forecastRange > 0.5)
              AppText(
                l10n.forecastRange(context.euros(overview.forecast - overview.forecastRange), context.euros(overview.forecast + overview.forecastRange)),
                style: (t) => t.footnoteEmphasized,
                color: c.spotlightAccent,
              ),
            AppText(l10n.homeForecastHint, style: (t) => t.footnote, color: c.onSpotlightSecondary),
            const SizedBox(height: Spacing.l),
            SizedBox(
              height: Sizes.curveHeight,
              child: CostCurve(
                months: [...overview.monthsThisYear, ...overview.monthsNextYear],
                currentIndex: overview.today.month - 1,
                lineColor: c.spotlightAccent,
                forecastColor: c.onSpotlightSecondary,
                gridColor: c.spotlightLine,
              ),
            ),
            const SizedBox(height: Spacing.m),
            Row(
              spacing: Spacing.l,
              children: [
                _Legend(color: c.spotlightAccent, label: l10n.homeCurveActual('${overview.year}')),
                _Legend(color: c.onSpotlightSecondary, label: l10n.homeCurveForecast(next), dashed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [for (var i = 0; i < (dashed ? 3 : 1); i++) Container(width: dashed ? 4 : 14, height: 2.5, color: color)],
        ),
        AppText(label, style: (t) => t.caption, color: context.colors.onSpotlightSecondary),
      ],
    );
  }
}
