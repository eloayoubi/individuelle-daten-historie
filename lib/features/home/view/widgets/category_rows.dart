import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../data/home_overview.dart';

/// Kategorien als gruppierte Liste: Symbol, Name, Kennzahl, Kosten seit Januar und Trend.
class CategoryRows extends StatelessWidget {
  const CategoryRows({super.key, required this.summaries, required this.onTap});

  final List<CategorySummary> summaries;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    return AppListGroup(children: [for (final s in summaries) _CategoryRow(summary: s, onTap: () => onTap(s.category))]);
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.summary, required this.onTap});

  /// Darunter gilt eine Kategorie als „ohne Kosten“ (z. B. Wasser über die Nebenkosten).
  static const _minCost = 0.5;

  final CategorySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final s = summary;
    final hasCost = s.costToDate >= _minCost;
    final usage = s.usage == null ? null : context.amount(s.usage!, s.usageUnit);
    final detail = switch ((hasCost, usage)) {
      (true, final String u) => l10n.homeConsumptionToDate(u),
      (true, null) => l10n.homePerMonth(context.euros(s.monthlyAverage)),
      (false, _) => null,
    };
    final change = hasCost ? context.change(s.costChange) : null;
    final trend = s.costChange.trend;
    return AppListRow(
      leading: AppIconTile(icon: s.category.icon.data, color: c.swatch(s.category.swatch)),
      title: s.category.name,
      subtitleWidget: detail == null && !s.category.isShared
          ? null
          : Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (detail != null) AppText(detail, style: (t) => t.footnote, color: c.textSecondary),
                if (s.category.isShared)
                  AppChip(
                    icon: CupertinoIcons.person_2_fill,
                    label: l10n.homeSharedWith(s.category.sharedWith.map((m) => m.name).join(', ')),
                    background: c.accentSoft,
                    foreground: c.accent,
                  ),
              ],
            ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          AppText(hasCost ? context.euros(s.costToDate) : usage ?? '', style: (t) => t.numberM),
          if (change != null)
            AppText(
              change,
              style: (t) => t.captionEmphasized,
              color: switch (trend) {
                1 => c.danger,
                -1 => c.success,
                _ => c.textSecondary,
              },
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
