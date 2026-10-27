import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_pressable.dart';
import 'app_text.dart';
import 'glass_surface.dart';

/// Leiste über der Zahlentastatur (nur iOS): Zahlen- und Dezimalblock haben dort keine Eingabetaste,
/// ohne die Leiste ginge die Tastatur nicht mehr zu. Links springen Pfeile zum vorigen und nächsten
/// Textfeld, rechts schließt „Fertig“ die Tastatur.
///
/// Liegt einmal im `builder` des `MaterialApp` und gilt damit für jedes Zahlenfeld, auch in Sheets.
/// Solange sie zu sehen ist, zählt ihre Höhe zu `MediaQuery.viewInsets`: Seiten, Sheets und die Leiste
/// mit der Hauptaktion rücken über sie, statt unter ihr zu verschwinden.
class AppKeyboardBar extends StatefulWidget {
  const AppKeyboardBar({super.key, required this.child});

  final Widget child;

  /// Platz, den die Leiste über der Tastatur einnimmt.
  static const height = Sizes.tap + 2 * Spacing.xs;

  @override
  State<AppKeyboardBar> createState() => _AppKeyboardBarState();
}

class _AppKeyboardBarState extends State<AppKeyboardBar> {
  /// Das zuletzt fokussierte Textfeld hat einen Zahlenblock. Verliert es den Fokus, bleibt der Wert
  /// stehen: Die Leiste fährt dann mit der Tastatur nach unten, statt vorher zu verschwinden.
  var _numeric = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() {
    if (_editable(FocusManager.instance.primaryFocus) case final EditableText field) {
      _numeric = field.keyboardType.index == TextInputType.number.index;
    }
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final visible = _numeric && keyboard > 0 && defaultTargetPlatform == TargetPlatform.iOS;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        MediaQuery(
          data: visible ? media.copyWith(viewInsets: media.viewInsets.copyWith(bottom: keyboard + AppKeyboardBar.height)) : media,
          child: widget.child,
        ),
        if (visible)
          Positioned(left: 0, right: 0, bottom: keyboard, height: AppKeyboardBar.height, child: _Bar(focus: FocusManager.instance.primaryFocus)),
      ],
    );
  }
}

/// Das Textfeld, dem [node] gehört; `null`, wenn der Fokus woanders liegt.
EditableText? _editable(FocusNode? node) {
  final context = node?.context;
  if (context == null || !context.mounted) return null;
  final field = context.findAncestorWidgetOfExactType<EditableText>();
  return field?.focusNode == node ? field : null;
}

/// Textfelder auf derselben Seite bzw. im selben Sheet wie [current], von oben nach unten.
List<FocusNode> _fields(FocusNode current) => [
  for (final node in current.nearestScope?.traversalDescendants ?? const <FocusNode>[])
    if (node.context?.findRenderObject() case RenderBox(attached: true, hasSize: true) when _editable(node) != null) node,
]..sort((a, b) => a.rect.top != b.rect.top ? a.rect.top.compareTo(b.rect.top) : a.rect.left.compareTo(b.rect.left));

class _Bar extends StatelessWidget {
  const _Bar({required this.focus});

  /// Das fokussierte Feld; davon hängen die Ziele der Pfeile ab.
  final FocusNode? focus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final current = focus;
    final fields = current != null && _editable(current) != null ? _fields(current) : const <FocusNode>[];
    final index = fields.indexWhere((node) => node == current);
    // Zählt fürs Antippen zum Textfeld: Ein Tipp auf die Leiste schließt die Tastatur nicht vorab.
    // Material liefert die Textstile; die Leiste liegt über dem Navigator, ohne eigene Seite darunter.
    return TextFieldTapRegion(
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s, vertical: Spacing.xs),
          child: Row(
            children: [
              if (fields.length > 1)
                GlassSurface(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Arrow(icon: CupertinoIcons.chevron_up, semanticLabel: l10n.keyboardPrevious, target: index > 0 ? fields[index - 1] : null),
                      _Arrow(icon: CupertinoIcons.chevron_down, semanticLabel: l10n.keyboardNext, target: index < fields.length - 1 ? fields[index + 1] : null),
                    ],
                  ),
                ),
              const Spacer(),
              GlassSurface(
                child: AppPressable(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: Container(
                    height: Sizes.tap,
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                    alignment: Alignment.center,
                    child: AppText(l10n.actionDone, style: (t) => t.headline, color: c.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pfeil zum vorigen oder nächsten Textfeld; ohne [target] ausgegraut.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.semanticLabel, required this.target});

  final IconData icon;
  final String semanticLabel;
  final FocusNode? target;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      onTap: target?.requestFocus,
      semanticLabel: semanticLabel,
      scale: 0.92,
      child: SizedBox.square(
        dimension: Sizes.tap,
        child: Icon(icon, size: 20, color: target == null ? c.textTertiary : c.textPrimary),
      ),
    );
  }
}
