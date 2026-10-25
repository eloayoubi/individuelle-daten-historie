import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_text.dart';

/// Seite mit Hauptaktion unten: [content] darüber, darunter eine feste Leiste mit [action] (meist ein
/// gefüllter `AppButton`) – die Aktion ist immer in Daumenreichweite und geht nicht in der Liste unter.
/// [hint] steht klein über dem Button (z. B. warum er noch gesperrt ist). Ohne [action] nur [content].
///
/// Die Leiste liegt unter dem Inhalt, nicht darüber: Bei offener Tastatur rückt sie mit nach oben,
/// und ein Textfeld scrollt nie unter sie. Ein weicher Verlauf lässt den Inhalt zur Leiste hin auslaufen.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.content, this.action, this.hint});

  final Widget content;
  final Widget? action;
  final String? hint;

  /// Abstand, den eine Liste unter [AppActionBar] unten frei lassen sollte (Platz für den Verlauf).
  static double inset(BuildContext context) => Spacing.xxl;

  /// Höhe des Verlaufs über der Leiste.
  static const _fade = Spacing.xxl;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    if (action == null) return content;
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _fade,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.background.withValues(alpha: 0), c.background],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ColoredBox(
          color: c.background,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Spacing.l, Spacing.xs, Spacing.l, bottom > 0 ? bottom : Spacing.l),
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
      ],
    );
  }
}
