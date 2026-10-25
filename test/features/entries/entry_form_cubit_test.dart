import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/entries/cubit/entry_form_cubit.dart';

void main() {
  final strom = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-strom');
  final gas = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-heizung');
  final meter = strom.trackers.single.fields.first;
  DateTime now() => DateTime(2026, 10, 22, 19, 5);

  late MockCategoriesRepository repo;
  setUp(() => repo = MockCategoriesRepository());

  EntryFormCubit form({Category? category, Tracker? tracker, Entry? entry, bool contract = false}) {
    final c = category ?? strom;
    return EntryFormCubit(repo, EntryFormArgs(category: c, tracker: tracker ?? c.trackers.single, entry: entry, contract: contract), now: now);
  }

  Entry bill(DateTime from, DateTime to, num value) => Entry(id: 'b$from', date: to, values: {meter.id: value}, periodStart: from, periodEnd: to);

  test('neuer Eintrag: heute, neue Id, noch nicht speicherbar', () {
    final s = form().state;
    expect(s.date, DateTime.utc(2026, 10, 22));
    expect(s.isNew, isTrue);
    expect(s.entryId, hasLength(36));
    expect(s.canSave, isFalse);
  });

  test('zeigt den letzten Stand und den Verbrauch seitdem', () {
    final cubit = form()..setText(meter.id, '47.250');
    final previous = cubit.state.previous(meter)!;
    expect(previous.$1, DateTime.utc(2026, 9, 12));
    expect(cubit.state.valueOf(meter), 47250);
    expect(cubit.state.meterDelta(meter), closeTo(47250 - (previous.$2 as num), 1e-9));
    expect(cubit.state.canSave, isTrue);
  });

  test('Gas: Verbrauch seit dem letzten Stand in kWh (mit Brennwert)', () {
    final gasMeter = gas.trackers.single.fields.first;
    final cubit = form(category: gas);
    final last = cubit.state.previous(gasMeter)!.$2 as num;
    cubit.setText(gasMeter.id, '${last + 10}');
    expect(cubit.state.meterDelta(gasMeter), closeTo(10 * gasMeter.factor, 1e-6));
  });

  test('kleinerer Stand: Hinweis auf Zählerwechsel, mit Schalter weg', () {
    final cubit = form()..setText(meter.id, '100');
    expect(cubit.state.meterBelow(meter), isTrue);
    cubit.setMeterChange(true);
    expect(cubit.state.meterBelow(meter), isFalse);
    expect(cubit.state.meterDelta(meter), isNull);
    expect(cubit.state.toEntry().meterChange, isTrue);
  });

  test('ungültige Zahl blockiert das Speichern', () {
    final cubit = form(contract: true)
      ..setText('f-strom-gp', '12')
      ..setText('f-strom-ap', 'teuer');
    expect(cubit.state.invalid, {'f-strom-ap'});
    expect(cubit.state.canSave, isFalse);
  });

  test('Strom startet als Zählerstand, weil zuletzt abgelesen wurde: nur der Stand, keine Preise und Details', () {
    final s = form().state;
    expect(s.mode, EntryFormMode.reading);
    expect(s.fields.map((f) => f.id), ['f-strom-stand']);
    expect(s.canSwitchMode, isTrue);
  });

  test('nimmt nur gefüllte Felder in den Eintrag', () {
    final cubit = form(contract: true)
      ..setText('f-strom-ap', ' 0,35 ')
      ..setText('f-strom-gp', '')
      ..setNote('  ')
      ..setDate(DateTime(2026, 10, 1, 14));
    final entry = cubit.state.toEntry();
    expect(entry.values, {'f-strom-ap': 0.35});
    expect(entry.date, DateTime.utc(2026, 10, 1));
    expect(entry.note, isNull);
    expect(entry.meterChange, isFalse);
  });

  test('vorhandene Preisänderung: Vertragsmodus, Werte vorbelegt mit Komma', () {
    final price = strom.trackers.single.entries.firstWhere((e) => e.id == 'e-strom-p2');
    final cubit = form(entry: price);
    expect(cubit.state.mode, EntryFormMode.contract);
    expect(cubit.state.canSwitchMode, isFalse);
    expect(cubit.state.isNew, isFalse);
    expect(cubit.state.entryId, 'e-strom-p2');
    expect(cubit.state.inputs['f-strom-ap'], '0,329');
    expect(cubit.state.values.keys, isNot(contains('f-strom-anbieter')));
    expect(cubit.state.toEntry().values, price.values);
    cubit.setText('f-strom-ap', '0,341');
    expect(cubit.state.toEntry().values, {...price.values, 'f-strom-ap': 0.341});
  });

  test('nur Preise und Beträge: Datum heißt „Gilt ab“', () {
    final internet = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-internet');
    final contract = EntryFormCubit(repo, EntryFormArgs(category: internet, tracker: internet.trackers.first), now: now);
    expect(contract.state.validFrom, isTrue);
    expect(form().state.validFrom, isFalse);
  });

  blocTest<EntryFormCubit, EntryFormState>(
    'speichert den Eintrag im Repository',
    build: () => form(),
    act: (cubit) => cubit
      ..setText(meter.id, '47250')
      ..save(),
    skip: 1,
    expect: () => [
      isA<EntryFormState>().having((s) => s.saving, 'saving', isTrue),
      isA<EntryFormState>().having((s) => s.event?.kind, 'event', EntryFormEventKind.saved),
    ],
    verify: (cubit) async {
      final entries = (await repo.loadCategory('c-strom'))!.trackers.single.entries;
      expect(entries.firstWhere((e) => e.id == cubit.state.entryId).values, {meter.id: 47250});
    },
  );

  group('Rechnung', () {
    final empty = strom.trackers.single.copyWith(entries: []);

    test('ohne Zählereinträge startet die Rechnung mit Vorbelegung', () {
      final cubit = form(tracker: empty);
      expect(cubit.state.mode, EntryFormMode.bill);
      expect(cubit.state.fields.map((f) => f.id), ['f-strom-stand']);
      expect(cubit.state.periodStart, DateTime.utc(2026, 4, 22));
      expect(cubit.state.periodEnd, DateTime.utc(2026, 10, 22));
      expect(cubit.state.canSave, isFalse);
      cubit.setText(meter.id, '508');
      expect(cubit.state.canSave, isTrue);
      final entry = cubit.state.toEntry();
      expect(entry.date, DateTime.utc(2026, 10, 22));
      expect(entry.periodStart, DateTime.utc(2026, 4, 22));
      expect(entry.periodEnd, DateTime.utc(2026, 10, 22));
      expect(entry.values, {meter.id: 508});
      expect(empty.isBill(entry), isTrue);
    });

    test('nächste Rechnung beginnt nach der letzten', () {
      final cubit = form(tracker: empty.copyWith(entries: [bill(DateTime.utc(2025, 10), DateTime.utc(2026, 3, 31), 900)]));
      expect(cubit.state.mode, EntryFormMode.bill);
      expect(cubit.state.periodStart, DateTime.utc(2026, 4));
      expect(cubit.state.periodEnd, DateTime.utc(2026, 10, 22));
    });

    test('Verbrauch je Monat und Überschneidung', () {
      final cubit = form(tracker: empty.copyWith(entries: [bill(DateTime.utc(2026, 9), DateTime.utc(2026, 12, 31), 400)]))
        ..setPeriodStart(DateTime(2026, 4))
        ..setPeriodEnd(DateTime(2026, 9, 30))
        ..setText(meter.id, '508');
      expect(cubit.state.billPerMonth, closeTo(508 / 183 * 365 / 12, 1e-9));
      expect(cubit.state.billOverlaps, isTrue);
      cubit.setPeriodEnd(DateTime(2026, 8, 31));
      expect(cubit.state.billOverlaps, isFalse);
    });

    test('Zählerstand nach Rechnung vergleicht mit dem letzten Stand', () {
      final t = empty.copyWith(entries: [Entry(id: 'r', date: DateTime.utc(2026), values: {meter.id: 1000}), bill(DateTime.utc(2026, 1, 2), DateTime.utc(2026, 6, 30), 500)]);
      final cubit = form(tracker: t)..setMode(EntryFormMode.reading);
      expect(cubit.state.previous(meter), (DateTime.utc(2026), 1000));
    });

    test('Umschalten auf Zählerstand nimmt den Zeitraum weg, zurück setzt ihn neu', () {
      final cubit = form(tracker: empty)
        ..setText(meter.id, '508')
        ..setMode(EntryFormMode.reading);
      expect(cubit.state.mode, EntryFormMode.reading);
      expect(cubit.state.toEntry().hasPeriod, isFalse);
      expect(cubit.state.toEntry().date, DateTime.utc(2026, 10, 22));
      cubit.setMode(EntryFormMode.bill);
      expect(cubit.state.periodStart, DateTime.utc(2026, 4, 22));
    });

    test('vorhandene Rechnung öffnet als Rechnung mit ihrem Zeitraum', () {
      final b = bill(DateTime.utc(2026, 4), DateTime.utc(2026, 9, 30), 508);
      final cubit = form(tracker: empty.copyWith(entries: [b]), entry: b);
      expect(cubit.state.mode, EntryFormMode.bill);
      expect(cubit.state.canSwitchMode, isFalse);
      expect(cubit.state.periodStart, DateTime.utc(2026, 4));
      expect(cubit.state.toEntry().periodEnd, DateTime.utc(2026, 9, 30));
    });
  });

  group('Vertrag', () {
    test('Vertragsmodus: nur Preise, Gilt ab', () {
      final cubit = form(contract: true);
      expect(cubit.state.mode, EntryFormMode.contract);
      expect(cubit.state.fields.map((f) => f.id), ['f-strom-ap', 'f-strom-gp', 'f-strom-abschlag']);
      expect(cubit.state.validFrom, isTrue);
      expect(cubit.state.hasMeter, isFalse);
      cubit.setText('f-strom-ap', '0,35');
      final entry = cubit.state.toEntry();
      expect(entry.values, {'f-strom-ap': 0.35});
      expect(entry.hasPeriod, isFalse);
      expect(entry.meterChange, isFalse);
    });

    test('Preisänderung bearbeiten: geleertes Feld fällt weg', () {
      final price = strom.trackers.single.entries.firstWhere((e) => e.id == 'e-strom-p2');
      final cubit = form(entry: price)..setText('f-strom-gp', '');
      expect(cubit.state.toEntry().values.keys, isNot(contains('f-strom-gp')));
      expect(cubit.state.toEntry().values['f-strom-ap'], 0.329);
    });

    test('Auto bleibt im Standardformular', () {
      final auto = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-auto');
      final s = form(category: auto).state;
      expect(s.mode, EntryFormMode.standard);
      expect(s.canSwitchMode, isFalse);
      expect(s.hasOneOff, isTrue);
    });
  });

  group('Abrechnungszeitraum', () {
    final miete = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-miete');
    final wohnung = miete.trackers.single;
    EntryFormCubit rent({Entry? entry}) => EntryFormCubit(repo, EntryFormArgs(category: miete, tracker: wohnung, entry: entry), now: now);

    test('nur mit Einmalkosten-Feld; an = Vorjahr', () {
      expect(form().state.hasOneOff, isFalse);
      final cubit = rent()..setPeriodEnabled(true);
      expect(cubit.state.hasOneOff, isTrue);
      expect(cubit.state.periodStart, DateTime.utc(2025));
      expect(cubit.state.periodEnd, DateTime.utc(2025, 12, 31));
      cubit.setPeriodEnabled(false);
      expect(cubit.state.hasPeriod, isFalse);
    });

    test('landet im Eintrag, Ende vor Anfang blockiert', () {
      final cubit = rent()
        ..setText('f-miete-abrechnung', '-62')
        ..setPeriodEnabled(true)
        ..setPeriodStart(DateTime(2025, 3, 1));
      expect(cubit.state.toEntry().periodStart, DateTime.utc(2025, 3));
      expect(cubit.state.toEntry().periodEnd, DateTime.utc(2025, 12, 31));
      expect(cubit.state.canSave, isTrue);
      cubit.setPeriodEnd(DateTime(2025, 2, 1));
      expect(cubit.state.periodInvalid, isTrue);
      expect(cubit.state.canSave, isFalse);
    });

    test('Bearbeiten behält den gespeicherten Zeitraum', () {
      final settlement = wohnung.entries.firstWhere((e) => e.id == 'e-miete-2');
      final cubit = rent(entry: settlement)..setNote('geprüft');
      expect(cubit.state.toEntry().periodStart, settlement.periodStart);
      expect(cubit.state.toEntry().periodEnd, settlement.periodEnd);
    });
  });

  blocTest<EntryFormCubit, EntryFormState>(
    'löscht einen vorhandenen Eintrag',
    build: () => form(entry: strom.trackers.single.entries.last),
    act: (cubit) => cubit.delete(),
    expect: () => [
      isA<EntryFormState>().having((s) => s.saving, 'saving', isTrue),
      isA<EntryFormState>().having((s) => s.event?.kind, 'event', EntryFormEventKind.deleted),
    ],
    verify: (_) async {
      final entries = (await repo.loadCategory('c-strom'))!.trackers.single.entries;
      expect(entries.map((e) => e.id), isNot(contains(strom.trackers.single.entries.last.id)));
    },
  );

  test('erster Vertrag gilt ab dem ersten bekannten Verbrauch, spätere ab heute', () {
    final empty = strom.trackers.single.copyWith(entries: []);
    final withBill = empty.copyWith(entries: [bill(DateTime.utc(2025, 10), DateTime.utc(2026, 9, 30), 3000)]);
    expect(form(tracker: withBill, contract: true).state.date, DateTime.utc(2025, 10));
    expect(form(tracker: empty, contract: true).state.date, DateTime.utc(2026, 10, 22));
    expect(form(contract: true).state.date, DateTime.utc(2026, 10, 22));
  });

  group('Feinschliff', () {
    final empty = strom.trackers.single.copyWith(entries: []);

    test('Vorbelegung der Rechnung am Monatsende läuft nicht über', () {
      final cubit = EntryFormCubit(repo, EntryFormArgs(category: strom, tracker: empty), now: () => DateTime(2026, 8, 31, 10));
      expect(cubit.state.periodStart, DateTime.utc(2026, 2, 28));
      final october = EntryFormCubit(repo, EntryFormArgs(category: strom, tracker: empty), now: () => DateTime(2026, 10, 31, 10));
      expect(october.state.periodStart, DateTime.utc(2026, 4, 30));
    });

    test('Moduswechsel leert den Zählerwert und behält den eigenen Zeitraum', () {
      final cubit = form(tracker: empty)
        ..setText(meter.id, '508')
        ..setPeriodStart(DateTime(2026, 1, 1))
        ..setMode(EntryFormMode.reading);
      expect(cubit.state.valueOf(meter), isNull);
      cubit
        ..setText(meter.id, '47000')
        ..setMode(EntryFormMode.bill);
      expect(cubit.state.valueOf(meter), isNull);
      expect(cubit.state.periodStart, DateTime.utc(2026, 1, 1));
    });

    test('Werte von Feldern, die der Modus nicht zeigt, bleiben beim Speichern', () {
      final mixed = Entry(id: 'm', date: DateTime.utc(2026, 1, 1), values: {meter.id: 1000, 'f-strom-gp': 12});
      final cubit = form(tracker: empty.copyWith(entries: [mixed]), entry: mixed)..setText(meter.id, '1001');
      expect(cubit.state.mode, EntryFormMode.reading);
      expect(cubit.state.toEntry().values, {meter.id: 1001, 'f-strom-gp': 12});
    });

    test('neueste mögliche Daten: Rechnung und Stand bis heute, Preise auch später', () {
      expect(form().state.latestDate, DateTime.utc(2026, 10, 22));
      expect(form(contract: true).state.latestDate, isNull);
    });
  });

  test('aus dem Preisverlauf: gemischter Eintrag öffnet im Vertragsmodus, der Stand bleibt', () {
    final mixed = Entry(id: 'm', date: DateTime.utc(2026, 1, 1), values: {meter.id: 1000, 'f-strom-ap': 0.3});
    final t = strom.trackers.single.copyWith(entries: [mixed]);
    final cubit = form(tracker: t, entry: mixed, contract: true)..setText('f-strom-ap', '0,31');
    expect(cubit.state.mode, EntryFormMode.contract);
    expect(cubit.state.toEntry().values, {meter.id: 1000, 'f-strom-ap': 0.31});
  });

  test('Löschen im Vertragsmodus entfernt nur die Preise eines gemischten Eintrags', () async {
    final mixed = Entry(id: 'm-del', date: DateTime.utc(2026, 1, 1), values: {meter.id: 1000, 'f-strom-ap': 0.3});
    await repo.saveEntry('t-strom', mixed);
    final t = (await repo.loadCategory('c-strom'))!.trackers.single;
    await form(tracker: t, entry: mixed, contract: true).delete();
    final after = (await repo.loadCategory('c-strom'))!.trackers.single.entries.firstWhere((e) => e.id == 'm-del');
    expect(after.values, {meter.id: 1000});
  });
}
