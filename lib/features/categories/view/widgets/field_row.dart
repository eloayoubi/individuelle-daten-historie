import 'package:flutter/widgets.dart';

import '../../../../core/core.dart';
import '../../data/categories_repository.dart';

/// Ein Feld als Listenzeile: Typ-Symbol, Name, Zeitverhalten und Einheit.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.field, required this.swatch, this.trailing, this.onTap});

  /// Aus einer Vorlage (ohne Id) oder einem vorhandenen Feld.
  factory FieldRow.of(FieldDefinition field, {Key? key, required CategorySwatch swatch, Widget? trailing, VoidCallback? onTap}) =>
      FieldRow(key: key, field: FieldDraft.of(field), swatch: swatch, trailing: trailing, onTap: onTap);

  final FieldDraft field;
  final CategorySwatch swatch;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unit = switch ((field.unit, field.consumptionUnit)) {
      (final String u, final String c) when field.role == FieldRole.meterReading && c != u => '$u → $c',
      (final String u, _) => u,
      _ => null,
    };
    return AppListRow(
      leading: AppIconTile(icon: field.kind.icon, color: context.colors.swatch(swatch)),
      title: field.name,
      subtitle: context.joinParts([field.role == FieldRole.info ? field.kind.label(context.l10n) : field.role.label(context.l10n), unit]),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
