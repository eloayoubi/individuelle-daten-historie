import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../models/tracking.dart';

/// Zahlen, Beträge und Daten im Format der App-Sprache (`1.234 €` / `€1,234`).
extension FormatX on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// Ganze Euro, für Übersichten.
  String euros(double value) => NumberFormat.currency(locale: _locale, symbol: '€', decimalDigits: 0).format(value);

  /// Euro mit Cent, für einzelne Beträge.
  String eurosExact(double value) => NumberFormat.currency(locale: _locale, symbol: '€', decimalDigits: 2).format(value);

  /// Preis aus dem Store in seiner Währung (`1,67 €`), z. B. das Jahresabo je Monat.
  String price(double value, String? currency) => NumberFormat.simpleCurrency(locale: _locale, name: currency ?? 'EUR').format(value);

  /// Menge mit Einheit, z. B. `1.912 kWh`.
  String amount(double value, String unit, {int decimals = 0}) {
    final number = NumberFormat.decimalPatternDigits(locale: _locale, decimalDigits: decimals).format(value);
    return unit.isEmpty ? number : '$number $unit';
  }

  /// Veränderung als Anteil (0.042 → `+4,2 %`); `null`, wenn es nichts zu vergleichen gibt.
  String? change(double? ratio) {
    if (ratio == null || !ratio.isFinite) return null;
    final text = NumberFormat.decimalPercentPattern(locale: _locale, decimalDigits: 1).format(ratio.abs());
    return switch (ratio.trend) {
      1 => '+$text',
      -1 => '−$text',
      _ => text,
    };
  }

  /// Dateigröße: `840 KB`, `2,4 MB`, `1,2 GB`.
  String fileSize(int bytes) {
    const kb = 1024, mb = kb * 1024, gb = mb * 1024;
    return switch (bytes) {
      < mb => amount(bytes / kb, 'KB'),
      < gb => amount(bytes / mb, 'MB', decimals: 1),
      _ => amount(bytes / gb, 'GB', decimals: 1),
    };
  }

  /// `Donnerstag, 22. Oktober`
  String weekdayDate(DateTime date) => DateFormat.MMMMEEEEd(_locale).format(date);

  /// `31.03.2027`
  String shortDate(DateTime date) => DateFormat.yMd(_locale).format(date);

  /// `Okt. 2026`
  String monthYear(DateTime date) => DateFormat.yMMM(_locale).format(date);

  /// Monatskürzel für Achsen (`Jan`, `Mär`, `Okt`), immer drei Zeichen ohne Punkt, damit zwölf nebeneinander passen.
  String monthShort(DateTime date) => DateFormat.LLL(_locale).format(date);

  /// `Do., 22. Okt.`
  String shortWeekdayDate(DateTime date) => DateFormat.MMMEd(_locale).format(date);

  /// Dezimaltrenner der App-Sprache für Eingaben (`,` oder `.`).
  String get decimalSeparator => NumberFormat.decimalPattern(_locale).symbols.DECIMAL_SEP;

  /// Gespeicherter Wert eines Felds mit Einheit, z. B. `47.100 kWh`, `0,329 €/kWh`, `Ja`.
  String fieldValue(FieldDefinition field, Object value) {
    final l10n = AppLocalizations.of(this);
    return switch (value) {
      final num n when field.kind == FieldKind.percent => '${NumberFormat.decimalPatternDigits(locale: _locale, decimalDigits: _decimals(n, max: 2)).format(n)} %',
      final num n when field.kind == FieldKind.currency =>
        field.unit == null || field.unit == '€' ? eurosExact(n.toDouble()) : amount(n.toDouble(), field.unit!, decimals: _decimals(n, max: 4, min: 2)),
      final num n => amount(n.toDouble(), field.unit ?? '', decimals: _decimals(n, max: 3)),
      final DateTime d => shortDate(d),
      final bool b => b ? l10n.toggleYes : l10n.toggleNo,
      _ => value.toString(),
    };
  }

  /// So viele Nachkommastellen, wie der Wert braucht (höchstens [max]).
  static int _decimals(num n, {required int max, int min = 0}) {
    for (var d = min; d < max; d++) {
      final scaled = n * _pow10(d);
      if ((scaled.round() - scaled).abs() < 1e-6) return d;
    }
    return max;
  }

  static num _pow10(int d) => [1, 10, 100, 1000, 10000][d];

  /// Teile einer Zeile mit Mittelpunkt verbinden: `Zählerstand · kWh`. Leere Teile fallen weg.
  String joinParts(Iterable<String?> parts) => parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');

  /// Namen als Aufzählung: „Anna“, „Anna und Ben“, „Anna, Ben und Carla“.
  String joinNames(List<String> names) => switch (names) {
    [] => '',
    [final only] => only,
    [...final init, final last] => '${init.join(', ')} ${AppLocalizations.of(this).wordAnd} $last',
  };
}

extension TrendX on double? {
  /// 1 steigend, -1 fallend, 0 unverändert (unter 0,05 % oder ohne Vergleich).
  int get trend {
    final r = this;
    if (r == null || !r.isFinite || r.abs() < 0.0005) return 0;
    return r > 0 ? 1 : -1;
  }
}
