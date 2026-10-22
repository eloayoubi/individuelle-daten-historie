import 'package:flutter/cupertino.dart';

import '../../../core/core.dart';
import '../cubit/shell_cubit.dart';

/// Schwebende Tab-Leiste aus Glas, wie in iOS 26: Kapsel über dem Inhalt, aktiver Tab getönt.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current, required this.onSelect});

  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(ShellTab, IconData, String)>[
      (ShellTab.overview, CupertinoIcons.house_fill, l10n.tabOverview),
      (ShellTab.categories, CupertinoIcons.square_grid_2x2_fill, l10n.tabCategories),
      (ShellTab.insights, CupertinoIcons.chart_bar_alt_fill, l10n.tabInsights),
      (ShellTab.settings, CupertinoIcons.gear_alt_fill, l10n.tabSettings),
    ];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Spacing.s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: GlassSurface(
          child: SizedBox(
            height: Sizes.tabBarHeight,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xs),
              child: Row(
                children: [
                  for (final (tab, icon, label) in items)
                    Expanded(
                      child: _TabItem(icon: icon, label: label, selected: tab == current, onTap: () => onSelect(tab)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.textSecondary;
    return Semantics(
      selected: selected,
      child: AppPressable(
        onTap: onTap,
        semanticLabel: label,
        scale: 0.92,
        child: AnimatedContainer(
          duration: Motion.normal,
          curve: Motion.curve,
          decoration: ShapeDecoration(color: selected ? c.accentSoft : c.accentSoft.withValues(alpha: 0), shape: const StadiumBorder()),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              Icon(icon, size: 22, color: color),
              AppText(label, style: (t) => selected ? t.caption2Emphasized : t.caption2, color: color, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}
