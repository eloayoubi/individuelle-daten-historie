import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_icon_button.dart';
import 'app_text.dart';

/// Seitenkopf mit großem Titel wie in iOS-Apps: optionale Zeile darüber ([overline], z. B. das
/// Datum), Aktionen rechts, mit [onBack] ein Zurück-Button. Erwartet, unter der Statusleiste zu
/// sitzen (Seite liegt in einer `SafeArea`).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.overline, this.onBack, this.actions = const []});

  final String title;
  final String? overline;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, Spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.s,
        children: [
          if (onBack != null)
            AppIconButton(icon: CupertinoIcons.chevron_left, semanticLabel: context.l10n.actionBack, onPressed: onBack),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: Spacing.s,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.xxs,
                  children: [
                    if (overline != null)
                      AppText(overline!.toUpperCase(), style: (t) => t.footnoteEmphasized, color: context.colors.textSecondary, maxLines: 1),
                    AppText(title, style: (t) => t.largeTitle, maxLines: 1),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ],
      ),
    );
  }
}
