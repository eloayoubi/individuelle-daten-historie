import 'package:flutter/widgets.dart';

import '../../../../core/core.dart';
import '../../data/categories_repository.dart';

/// Ein Feld als Listenzeile: Typ-Symbol, Name, Zeitverhalten und Einheit.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.field, required this.swatch, this.partOf, this.trailing, this.onTap});

  /// Aus einer Vorlage (ohne Id) oder einem vorhandenen Feld.
  factory FieldRow.of(FieldDefinition field, {Key? key, required CategorySwatch swatch, String? partOf, Widget? trailing, VoidCallback? onTap}) =>
      FieldRow(key: key, field: FieldDraft.of(field), swatch: swatch, partOf: partOf, trailing: trailing, onTap: onTap);

  final FieldDraft field;
  final CategorySwatch swatch;

  /// Name des Gesamtfelds bei einem Teilbetrag.
  final String? partOf;
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
      subtitle: context.joinParts([
        field.role == FieldRole.info ? field.kind.label(context.l10n) : field.role.label(context.l10n),
        unit,
        if (partOf case final total?) context.l10n.fieldPartOfName(total),
        // Nur eine selbst gewählte Auswertung; der Standard folgt aus dem Zeitverhalten.
        if (field.summary case final summary? when field.withId('').effectiveSummary == summary) summary.label(context.l10n),
      ]),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
