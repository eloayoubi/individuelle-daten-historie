import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';

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
