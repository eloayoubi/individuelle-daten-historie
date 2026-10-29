import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Symbol und Farbe als zwei aufklappbare Zeilen: Zu sehen ist erst nur die Wahl, die ganze
/// Auswahl klappt beim Antippen auf – immer nur eine, damit sie nicht den Bildschirm füllt.
class AppearancePicker extends StatefulWidget {
  const AppearancePicker({super.key, required this.icon, required this.swatch, required this.onIcon, required this.onSwatch, this.color});

  final CategoryIcon icon;
  final CategorySwatch swatch;
  final ValueChanged<CategoryIcon> onIcon;
  final ValueChanged<CategorySwatch> onSwatch;

  /// Kartenfarbe; in Sheets `context.colors.surfaceRaised`.
  final Color? color;

  @override
  State<AppearancePicker> createState() => _AppearancePickerState();
}

enum _Section { icon, swatch }

class _AppearancePickerState extends State<AppearancePicker> {
  _Section? _open;

  void _toggle(_Section section) => setState(() => _open = _open == section ? null : section);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return AppCard(
      padding: EdgeInsets.zero,
      color: widget.color,
      child: Column(
        children: [
          _ExpandableRow(
            title: l10n.setupSymbol,
            value: AppIconTile(icon: widget.icon.data, color: c.swatch(widget.swatch)),
            open: _open == _Section.icon,
            onTap: () => _toggle(_Section.icon),
            child: IconPicker(selected: widget.icon, swatch: widget.swatch, onSelect: widget.onIcon),
          ),
          Divider(height: 0.5, thickness: 0.5, indent: Spacing.l, color: c.separator),
          _ExpandableRow(
            title: l10n.setupColor,
            value: Container(
              width: Sizes.iconTile - 6,
              height: Sizes.iconTile - 6,
              decoration: BoxDecoration(color: c.swatch(widget.swatch), shape: BoxShape.circle),
            ),
            open: _open == _Section.swatch,
            onTap: () => _toggle(_Section.swatch),
            child: SwatchPicker(selected: widget.swatch, onSelect: widget.onSwatch),
          ),
        ],
      ),
    );
  }
}

/// Zeile mit der aktuellen Wahl rechts; aufgeklappt steht [child] darunter.
class _ExpandableRow extends StatelessWidget {
  const _ExpandableRow({required this.title, required this.value, required this.open, required this.onTap, required this.child});

  final String title;
  final Widget value;
  final bool open;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: open,
          child: AppListRow(
            title: title,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.m,
              children: [
                value,
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(CupertinoIcons.chevron_right, size: 15, color: c.textTertiary),
                ),
              ],
            ),
            chevron: false,
            onTap: onTap,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xs, Spacing.l, Spacing.l), child: child)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Symbolwahl: alle Kategorie-Symbole, das gewählte in der Kategoriefarbe.
class IconPicker extends StatelessWidget {
  const IconPicker({super.key, required this.selected, required this.swatch, required this.onSelect});

  static const _size = 44.0;

  final CategoryIcon selected;
  final CategorySwatch swatch;
  final ValueChanged<CategoryIcon> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: Spacing.m,
      runSpacing: Spacing.m,
      children: [
        for (final icon in CategoryIcon.values)
          Semantics(
            selected: icon == selected,
            child: AppPressable(
              onTap: () => onSelect(icon),
              semanticLabel: context.l10n.setupSymbol,
              scale: 0.9,
              child: icon == selected
                  ? AppIconTile(icon: icon.data, color: c.swatch(swatch), size: _size)
                  : Container(
                      width: _size,
                      height: _size,
                      decoration: ShapeDecoration(color: c.fill, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(_size * 0.28))),
                      child: Icon(icon.data, size: _size * 0.5, color: c.textSecondary),
                    ),
            ),
          ),
      ],
    );
  }
}

/// Farbwahl: Apples Systemfarben als Punkte, die gewählte mit Ring und Haken.
class SwatchPicker extends StatelessWidget {
  const SwatchPicker({super.key, required this.selected, required this.onSelect});

  static const _size = 36.0;

  final CategorySwatch selected;
  final ValueChanged<CategorySwatch> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: Spacing.m,
      runSpacing: Spacing.m,
      children: [
        for (final swatch in CategorySwatch.values)
          Semantics(
            selected: swatch == selected,
            child: AppPressable(
              onTap: () => onSelect(swatch),
              semanticLabel: context.l10n.setupColor,
              scale: 0.9,
              child: Container(
                width: _size,
                height: _size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: swatch == selected ? c.swatch(swatch) : c.swatch(swatch).withValues(alpha: 0), width: 2),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.swatch(swatch), shape: BoxShape.circle),
                  child: swatch == selected ? Icon(CupertinoIcons.checkmark, size: 16, color: c.onAccent) : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
