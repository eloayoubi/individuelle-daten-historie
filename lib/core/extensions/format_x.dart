import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Zahlen, Beträge und Daten im Format der App-Sprache (`1.234 €` / `€1,234`).
extension FormatX on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// Ganze Euro, für Übersichten.
  String euros(double value) => NumberFormat.currency(locale: _locale, symbol: '€', decimalDigits: 0).format(value);

  /// Euro mit Cent, für einzelne Beträge.
  String eurosExact(double value) => NumberFormat.currency(locale: _locale, symbol: '€', decimalDigits: 2).format(value);

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

  /// `Donnerstag, 22. Oktober`
  String weekdayDate(DateTime date) => DateFormat.MMMMEEEEd(_locale).format(date);

  /// `31.03.2027`
  String shortDate(DateTime date) => DateFormat.yMd(_locale).format(date);
}

extension TrendX on double? {
  /// 1 steigend, -1 fallend, 0 unverändert (unter 0,05 % oder ohne Vergleich).
  int get trend {
    final r = this;
    if (r == null || !r.isFinite || r.abs() < 0.0005) return 0;
    return r > 0 ? 1 : -1;
  }
}
