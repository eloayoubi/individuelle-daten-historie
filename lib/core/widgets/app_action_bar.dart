import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_text.dart';

/// Seite mit Hauptaktion unten: [content] scrollt unter einer festen Leiste mit [action] (meist ein
/// gefüllter `AppButton`) – die Aktion ist immer in Daumenreichweite und geht nicht in der Liste unter.
/// [hint] steht klein über dem Button (z. B. warum er noch gesperrt ist). Ohne [action] nur [content].
///
/// [content] muss unten [AppActionBar.inset] Platz lassen, damit nichts unter der Leiste verschwindet.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.content, this.action, this.hint});

  final Widget content;
  final Widget? action;
  final String? hint;

  /// Abstand, den eine Liste unter [AppActionBar] unten frei lassen muss.
  static double inset(BuildContext context) => Sizes.buttonHeight + Spacing.xxl * 2 + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    if (action == null) return content;
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            // Weicher Übergang: Inhalt läuft unter der Leiste aus, statt hart abgeschnitten zu werden.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.background.withValues(alpha: 0), c.background, c.background],
                stops: const [0, 0.35, 1],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, bottom > 0 ? bottom : Spacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spacing.s,
                children: [
                  if (hint case final String text) AppText(text, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
                  action,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
