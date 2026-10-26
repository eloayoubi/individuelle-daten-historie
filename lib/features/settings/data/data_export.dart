import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show XFile;

import '../../categories/data/categories_repository.dart';

/// Beschriftungen der CSV in der App-Sprache.
class ExportLabels {
  const ExportLabels({required this.header, required this.yes, required this.no, this.consumption = 'Verbrauch', this.decimalSeparator = ','});

  /// Kategorie, Tracker, Datum, Feld, Wert, Einheit, Notiz, Zeitraum von, Zeitraum bis.
  final List<String> header;
  final String yes;
  final String no;

  /// Feldname für den Verbrauch einer Rechnung (statt „Zählerstand“).
  final String consumption;
  final String decimalSeparator;
}

/// Alle Daten zum Mitnehmen (DSGVO Art. 20): CSV mit einer Zeile je Wert für Tabellen, JSON mit
/// allem (Felder, Einstellungen, Zeiträume) zum Weiterverarbeiten.
abstract final class DataExport {
  /// Komma als Dezimaltrenner → Semikolon als Spaltentrenner (wie Excel in Deutschland).
  static String csv(List<Category> categories, ExportLabels labels) {
    final sep = labels.decimalSeparator == ',' ? ';' : ',';
    String cell(String v) => v.contains(sep) || v.contains('"') || v.contains('\n') ? '"${v.replaceAll('"', '""')}"' : v;
    String value(Object v) => switch (v) {
      final num n => _number(n, labels.decimalSeparator),
      final DateTime d => _isoDay(d),
      final bool b => b ? labels.yes : labels.no,
      _ => v.toString(),
    };
    final lines = [labels.header.map(cell).join(sep)];
    for (final c in categories) {
      for (final t in c.trackers) {
        final entries = [...t.entries]..sort((a, b) => a.date.compareTo(b.date));
        for (final e in entries) {
          for (final f in t.fields) {
            final v = e.values[f.id];
            if (v == null) continue;
            // Rechnung: Der Wert im Zählerfeld ist der Verbrauch, in der Verbrauchseinheit.
            final consumption = t.isBill(e) && f.role == FieldRole.meterReading;
            lines.add(
              [
                c.name,
                t.name,
                _isoDay(e.date),
                consumption ? labels.consumption : f.name,
                value(v),
                consumption ? f.usageUnit : (f.kind == FieldKind.percent ? '%' : f.unit ?? ''),
                e.note ?? '',
                if (e.hasPeriod) ...[_isoDay(e.periodStart!), _isoDay(e.periodEnd!)] else ...['', ''],
              ].map(cell).join(sep),
            );
          }
        }
      }
    }
    return '${lines.join('\r\n')}\r\n';
  }

  static Map<String, Object?> json(List<Category> categories, DateTime now) => {
    'app': 'Kostenkurve',
    'format': 1,
    'exportedAt': now.toUtc().toIso8601String(),
    'categories': [
      for (final c in categories)
        {
          'name': c.name,
          'icon': c.icon.name,
          'color': c.swatch.name,
          'role': c.myRole.name,
          'archived': c.isArchived,
          'sharedWith': [for (final m in c.sharedWith) {'name': m.name, 'role': m.role.name}],
          'trackers': [
            for (final t in c.trackers)
              {
                'name': t.name,
                'fields': [
                  for (final f in t.fields)
                    {
                      'name': f.name,
                      'kind': f.kind.name,
                      'role': f.role.name,
                      'unit': f.unit,
                      'consumptionUnit': f.consumptionUnit,
                      'factor': f.factor,
                      'intervalMonths': f.intervalMonths,
                      if (f.choices.isNotEmpty) 'choices': f.choices,
                      if (f.formula != null) 'formula': f.formula,
                      if (f.summary != null) 'summary': f.summary!.name,
                    },
                ],
                'entries': [
                  for (final e in [...t.entries]..sort((a, b) => a.date.compareTo(b.date)))
                    {
                      'date': _isoDay(e.date),
                      'values': {
                        for (final f in t.fields)
                          if (e.values[f.id] case final Object v) f.name: v is DateTime ? _isoDay(v) : v,
                      },
                      if (e.note != null) 'note': e.note,
                      if (e.meterChange) 'meterChange': true,
                      if (t.isBill(e)) 'bill': true,
                      if (e.hasPeriod) 'period': {'from': _isoDay(e.periodStart!), 'to': _isoDay(e.periodEnd!)},
                    },
                ],
              },
          ],
        },
    ],
  };

  /// Beide Dateien im temporären Ordner, bereit zum Teilen.
  static Future<List<XFile>> files(CategoriesRepository repository, ExportLabels labels, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final categories = await repository.loadCategories();
    final dir = await getTemporaryDirectory();
    final name = 'kostenkurve-${_isoDay(at)}';
    final csvFile = File('${dir.path}/$name.csv');
    // BOM: Excel erkennt sonst die Umlaute nicht.
    await csvFile.writeAsString('﻿${csv(categories, labels)}', flush: true);
    final jsonFile = File('${dir.path}/$name.json');
    await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(json(categories, at)), flush: true);
    return [XFile(csvFile.path, mimeType: 'text/csv'), XFile(jsonFile.path, mimeType: 'application/json')];
  }

  static String _number(num n, String decimalSeparator) {
    final text = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
    return decimalSeparator == '.' ? text : text.replaceAll('.', decimalSeparator);
  }

  static String _isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
