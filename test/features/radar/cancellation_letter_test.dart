import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/features/radar/data/cancellation_letter.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  final today = DateTime.utc(2026, 10, 22);
  final de = lookupAppLocalizations(const Locale('de'));

  const price = FieldDefinition(id: 'price', name: 'Monatspreis', kind: FieldKind.currency, role: FieldRole.recurringCost);
  const provider = FieldDefinition(id: 'provider', name: 'Anbieter', kind: FieldKind.text);
  const number = FieldDefinition(id: 'number', name: 'Vertragsnummer', kind: FieldKind.text);
  const type = FieldDefinition(id: 'type', name: 'Art', kind: FieldKind.choice, choices: ['Festnetz']);
  const end = FieldDefinition(id: 'end', name: 'Mindestlaufzeit bis', kind: FieldKind.date, role: FieldRole.deadline);

  Tracker tracker({String name = 'Glasfaser', Map<String, Object> details = const {'provider': 'Stadtwerke', 'number': '4711', 'type': 'Festnetz'}}) => Tracker(
    id: 't',
    name: name,
    fields: const [price, provider, number, type, end],
    entries: [
      Entry(id: 'e1', date: DateTime.utc(2025), values: const {'price': 39.99}),
      Entry(id: 'e2', date: DateTime.utc(2025), values: {...details, 'end': DateTime.utc(2026, 11, 30)}),
    ],
  );

  Category category(Tracker t, {String name = 'Internet'}) => Category(id: 'c', name: name, icon: CategoryIcon.wifi, swatch: CategorySwatch.purple, trackers: [t]);

  String letter(Tracker t, {String categoryName = 'Internet', AppLocalizations? l}) =>
      CancellationLetter.build(l ?? de, category: category(t, name: categoryName), tracker: t, today: today);

  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  test('nennt Vertrag, Datum und die Text-Details – und kündigt zum nächstmöglichen Zeitpunkt', () {
    final lines = letter(tracker()).split('\n');
    expect(lines, contains('22.10.2026'));
    expect(lines, contains('Kündigung: Glasfaser (Internet)'));
    expect(lines, contains('Anbieter: Stadtwerke'));
    expect(lines, contains('Vertragsnummer: 4711'));
    expect(lines, contains('hiermit kündige ich den oben genannten Vertrag fristgerecht zum nächstmöglichen Zeitpunkt.'));
    // Platzhalter statt erfundener Angaben: Name und Anschrift kennt die App nicht.
    expect(lines.first, '[Vorname Nachname]');
    expect(lines.last, '[Vorname Nachname]');
  });

  test('Auswahl, Datum und Beträge stehen nicht im Schreiben, leere Details auch nicht', () {
    final text = letter(tracker(details: const {'provider': '  ', 'type': 'Festnetz'}));
    expect(text, isNot(contains('Art')));
    expect(text, isNot(contains('Anbieter')));
    expect(text, isNot(contains('Vertragsnummer')));
    expect(text, isNot(contains('39')));
    expect(text, isNot(contains('30.11.2026')));
  });

  test('heißt die Kategorie wie der Tracker, steht der Name nur einmal', () {
    expect(letter(tracker(name: 'Internet')), contains('Kündigung: Internet\n'));
  });

  test('Zeilenumbrüche und Richtungszeichen aus Namen und Details werden zu Leerzeichen', () {
    final rlo = String.fromCharCode(0x202E), lineSeparator = String.fromCharCode(0x2028);
    final text = letter(tracker(name: 'Glas\nfaser$rlo', details: {'provider': 'Stadtwerke\n\nSehr geehrte${lineSeparator}Damen', 'number': '47\t11'}));
    final lines = text.split('\n');
    expect(lines, contains('Kündigung: Glas faser (Internet)'));
    expect(lines, contains('Anbieter: Stadtwerke  Sehr geehrte Damen'));
    expect(lines, contains('Vertragsnummer: 47 11'));
    expect(text.runes.where((r) => r == 0x202E || r == 0x2028 || r == 0x09), isEmpty);
    // Der Brief selbst hat genau eine Anrede.
    expect('Sehr geehrte Damen und Herren'.allMatches(text), hasLength(1));
  });

  test('unsichtbare Zeichen verschwinden, überlange Angaben werden gekürzt', () {
    final hidden = [0x200B, 0x200D, 0x2060, 0xFEFF, 0x00AD, 0xE0041].map(String.fromCharCode).join();
    final text = letter(tracker(details: {'provider': 'Stadt${hidden}werke', 'number': 'x' * 5000}));
    for (final rune in hidden.runes) {
      expect(text.runes, isNot(contains(rune)));
    }
    final number = text.split('\n').firstWhere((l) => l.startsWith('Vertragsnummer: '));
    expect(number.length, 'Vertragsnummer: '.length + CancellationLetter.maxLineLength);
  });

  test('nennt höchstens zehn Details', () {
    final fields = [for (var i = 0; i < 15; i++) FieldDefinition(id: 'f$i', name: 'Feld $i', kind: FieldKind.text)];
    final many = Tracker(id: 't', name: 'Vertrag', fields: fields, entries: [Entry(id: 'e', date: DateTime.utc(2025), values: {for (final f in fields) f.id: 'Wert'})]);
    expect(CancellationLetter.details(many), hasLength(CancellationLetter.maxDetails));
  });

  test('auf Englisch mit englischem Datum', () {
    final text = letter(tracker(), l: lookupAppLocalizations(const Locale('en')));
    expect(text, contains('Cancellation: Glasfaser (Internet)'));
    expect(text, contains('10/22/2026'));
    expect(text, contains('earliest possible date'));
  });
}
