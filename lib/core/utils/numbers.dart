/// Zahl aus einer Eingabe in der App-Sprache lesen.
///
/// - Der Dezimaltrenner der Sprache ([decimalSeparator]) gilt immer als Komma-Stelle, der andere
///   Trenner als Tausenderpunkt: `47.100,5` → 47100.5.
/// - Steht nur der andere Trenner da, entscheidet die Form: `47.100` und `1.250` sind Tausender
///   (Gruppen zu drei Ziffern, ohne führende Null), `0.329` und `10.5` sind Dezimalzahlen –
///   auf Android-Tastaturen gibt es beide Zeichen.
double? parseNumber(String text, {required String decimalSeparator}) {
  var t = text.trim().replaceAll(RegExp(r'[\s  ]'), '');
  if (t.isEmpty) return null;
  final other = decimalSeparator == ',' ? '.' : ',';
  if (t.contains(decimalSeparator)) {
    // Beide Trenner, der Dezimaltrenner zuerst (`1,234.5` in einer deutschen App): nicht eindeutig –
    // lieber keine Zahl als stillschweigend 1,2345.
    if (t.contains(other) && t.indexOf(decimalSeparator) < t.lastIndexOf(other)) return null;
    t = t.replaceAll(other, '').replaceAll(decimalSeparator, '.');
  } else if (t.contains(other)) {
    final grouped = RegExp('^-?[1-9]\\d{0,2}(${RegExp.escape(other)}\\d{3})+\$').hasMatch(t);
    t = grouped ? t.replaceAll(other, '') : t.replaceAll(other, '.');
  }
  // `Infinity`, `NaN` und `1e999` liest double.tryParse als Zahl – speichern und rechnen lässt sich
  // damit nicht.
  final value = double.tryParse(t);
  return value != null && value.isFinite ? value : null;
}

/// Zahl für ein Eingabefeld, ohne Tausenderpunkte und ohne überflüssige Nullen (`0,329`, `47100`).
String formatNumberInput(num value, {required String decimalSeparator}) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString().replaceAll('.', decimalSeparator);
}
