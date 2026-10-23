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

  EntryFormCubit form({Category? category, Entry? entry}) {
    final c = category ?? strom;
    return EntryFormCubit(repo, EntryFormArgs(category: c, tracker: c.trackers.single, entry: entry), now: now);
  }

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
    final cubit = form()
      ..setText(meter.id, '47100')
      ..setText(strom.trackers.single.fields[1].id, 'teuer');
    expect(cubit.state.invalid, {strom.trackers.single.fields[1].id});
    expect(cubit.state.canSave, isFalse);
  });

  test('Details (Anbieter, Vertragsende) gehören nicht ins Formular', () {
    final s = form().state;
    expect(s.fields.map((f) => f.id), isNot(contains('f-strom-anbieter')));
    expect(s.fields.map((f) => f.id), isNot(contains('f-strom-ende')));
    expect(s.fields.map((f) => f.id), containsAll(['f-strom-stand', 'f-strom-ap', 'f-strom-gp']));
  });

  test('nimmt nur gefüllte Felder in den Eintrag', () {
    final cubit = form()
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

  test('vorhandener Eintrag: Werte vorbelegt, mit Komma; alte Details bleiben beim Speichern', () {
    final price = strom.trackers.single.entries.firstWhere((e) => e.id == 'e-strom-p2');
    final cubit = form(entry: price);
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
}
