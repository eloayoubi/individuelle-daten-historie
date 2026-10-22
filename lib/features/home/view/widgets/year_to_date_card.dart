import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/home_overview.dart';

/// Kosten seit Januar mit Aufteilung nach Kategorien als Balken.
class YearToDateCard extends StatelessWidget {
  const YearToDateCard({super.key, required this.overview});

  /// So viele Kategorien bekommen eine eigene Legende, der Rest läuft unter „…“ mit.
  static const legendCount = 4;

  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final change = context.change(overview.costChange);
    final parts = [for (final s in overview.categories) if (s.costToDate > 0) s];
    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(l10n.homeYearToDate('${overview.year}').toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.textSecondary),
            const SizedBox(height: Spacing.xs),
            AppText(context.euros(overview.costToDate), style: (t) => t.numberL),
            if (change != null) ...[
              const SizedBox(height: 2),
              AppText(l10n.homeYearToDateCompare(change), style: (t) => t.footnote, color: c.textSecondary),
            ],
            if (parts.isNotEmpty) ...[
              const SizedBox(height: Spacing.l),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: SizedBox(
                  height: Sizes.shareBarHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 2,
                    children: [
                      for (final s in parts)
                        Expanded(
                          flex: (s.costToDate / overview.costToDate * 1000).round().clamp(1, 1000),
                          child: ColoredBox(color: c.swatch(s.category.swatch)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.m),
              Wrap(
                spacing: Spacing.l,
                runSpacing: Spacing.xs,
                children: [
                  for (final s in parts.take(legendCount))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: Spacing.xs,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: c.swatch(s.category.swatch), shape: BoxShape.circle)),
                        AppText(s.category.name, style: (t) => t.caption, color: c.textSecondary),
                        AppText(context.euros(s.costToDate), style: (t) => t.captionEmphasized),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
