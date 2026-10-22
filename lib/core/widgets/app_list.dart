import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_card.dart';
import 'app_pressable.dart';
import 'app_text.dart';

/// Gruppierte Liste wie in den iOS-Einstellungen: eine Karte, Zeilen mit eingerückten Trennern.
class AppListGroup extends StatelessWidget {
  const AppListGroup({super.key, required this.children, this.dividerIndent = Spacing.l + Sizes.iconTile + Spacing.m, this.footer, this.color});

  final List<Widget> children;

  /// Trenner beginnen hinter dem Icon, wie bei Apple.
  final double dividerIndent;

  /// Erklärtext unter der Gruppe.
  final String? footer;

  /// Kartenfarbe; in Sheets `context.colors.surfaceRaised`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 0.5, thickness: 0.5, indent: dividerIndent, color: context.colors.separator));
      rows.add(children[i]);
    }
    return Padding(
      padding: Spacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.s,
        children: [
          AppCard(padding: EdgeInsets.zero, color: color, child: Column(children: rows)),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
              child: AppText(footer!, style: (t) => t.footnote, color: context.colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// Zeile einer [AppListGroup]: Icon links, Titel und Untertitel, rechts Wert und Pfeil.
class AppListRow extends StatelessWidget {
  const AppListRow({super.key, required this.title, this.leading, this.subtitle, this.subtitleWidget, this.trailing, this.onTap, this.chevron = true});

  final String title;
  final Widget? leading;
  final String? subtitle;

  /// Statt [subtitle] etwas Eigenes unter dem Titel (z. B. Chips).
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Pfeil rechts, nur wenn die Zeile antippbar ist.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      onTap: onTap,
      scale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.s + 2),
          child: Row(
            spacing: Spacing.m,
            children: [
              ?leading,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    AppText(title, style: (t) => t.body, maxLines: 1),
                    if (subtitleWidget != null)
                      subtitleWidget!
                    else if (subtitle != null)
                      AppText(subtitle!, style: (t) => t.footnote, color: c.textSecondary, maxLines: 2),
                  ],
                ),
              ),
              ?trailing,
              if (onTap != null && chevron) Icon(CupertinoIcons.chevron_right, size: 15, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
