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
    t = t.replaceAll(other, '').replaceAll(decimalSeparator, '.');
  } else if (t.contains(other)) {
    final grouped = RegExp('^-?[1-9]\\d{0,2}(${RegExp.escape(other)}\\d{3})+\$').hasMatch(t);
    t = grouped ? t.replaceAll(other, '') : t.replaceAll(other, '.');
  }
  return double.tryParse(t);
}

/// Zahl für ein Eingabefeld, ohne Tausenderpunkte und ohne überflüssige Nullen (`0,329`, `47100`).
String formatNumberInput(num value, {required String decimalSeparator}) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString().replaceAll('.', decimalSeparator);
}
