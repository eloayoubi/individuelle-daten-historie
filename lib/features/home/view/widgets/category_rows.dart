import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../../data/home_overview.dart';

/// Kategorien als gruppierte Liste: Symbol, Name, Kennzahl, Kosten seit Januar und Trend.
/// Gedrückt halten schaltet den Verschiebe-Modus ein ([onReorderStart]) und zieht die Zeile
/// gleich mit; im Modus ([reordering]) ziehen Zeile und Griff sofort, Antippen ist aus.
class CategoryRows extends StatelessWidget {
  const CategoryRows({super.key, required this.summaries, required this.onTap, this.reordering = false, this.onReorderStart, this.onReorder});

  final List<CategorySummary> summaries;
  final ValueChanged<Category> onTap;
  final bool reordering;
  final VoidCallback? onReorderStart;

  /// Wie `onReorderItem`: [newIndex] ist die Zielposition nach dem Herausnehmen.
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onReorder = this.onReorder;
    if (onReorder == null || summaries.length < 2) {
      return AppListGroup(children: [for (final s in summaries) _CategoryRow(summary: s, onTap: () => onTap(s.category))]);
    }
    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: summaries.length,
          onReorderStart: (_) {
            HapticFeedback.mediumImpact();
            onReorderStart?.call();
          },
          onReorderItem: onReorder,
          proxyDecorator: (child, _, _) => Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: c.surface,
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Radii.card)),
                shadows: [BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: child,
            ),
          ),
          itemBuilder: (context, i) {
            final s = summaries[i];
            final row = _CategoryRow(summary: s, onTap: reordering ? null : () => onTap(s.category), handle: reordering);
            return Column(
              key: ValueKey(s.category.id),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i > 0) Divider(height: 0.5, thickness: 0.5, indent: Spacing.l + Sizes.iconTile + Spacing.m, color: c.separator),
                if (reordering) ReorderableDragStartListener(index: i, child: row) else ReorderableDelayedDragStartListener(index: i, child: row),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.summary, required this.onTap, this.handle = false});

  /// Darunter gilt eine Kategorie als „ohne Kosten“ (z. B. Wasser über die Nebenkosten).
  static const _minCost = 0.5;

  final CategorySummary summary;
  final VoidCallback? onTap;

  /// Verschiebe-Modus: rechts der Griff statt des Pfeils.
  final bool handle;

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
                    label: l10n.homeSharedWith(context.memberNames(s.category.sharedWith)),
                    background: c.accentSoft,
                    foreground: c.accent,
                  ),
              ],
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.m,
        children: [
          Column(
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
          if (handle) Icon(CupertinoIcons.line_horizontal_3, color: c.textTertiary),
        ],
      ),
      onTap: onTap,
    );
  }
}
