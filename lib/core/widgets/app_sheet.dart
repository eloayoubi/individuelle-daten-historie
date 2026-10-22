import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_icon_button.dart';
import 'app_text.dart';

/// Sheet von unten wie auf iOS: Griff, Titel, Schließen-Knopf, Inhalt darunter.
///
/// `AppSheet.show(context, title: …, child: …)`; das Ergebnis kommt über `Navigator.pop(context, x)`.
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  static Future<T?> show<T>(BuildContext context, {required String title, required Widget child}) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.sheet,
    barrierColor: context.colors.shadow,
    shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    clipBehavior: Clip.antiAlias,
    builder: (_) => AppSheet(title: title, child: child),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Textfelder im Sheet: Inhalt über die Tastatur schieben.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: Spacing.s),
                width: Sizes.grabber.width,
                height: Sizes.grabber.height,
                decoration: ShapeDecoration(color: c.separator, shape: const StadiumBorder()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.m, Spacing.l, Spacing.m),
              child: Row(
                spacing: Spacing.m,
                children: [
                  Expanded(child: AppText(title, style: (t) => t.title3)),
                  AppIconButton(
                    icon: CupertinoIcons.xmark,
                    semanticLabel: context.l10n.actionClose,
                    size: 32,
                    background: c.fill,
                    foreground: c.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
