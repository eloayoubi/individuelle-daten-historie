import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/cubit/field_editor_cubit.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';

void main() {
  late MockCategoriesRepository repo;
  setUp(() => repo = MockCategoriesRepository());

  Future<Tracker> tracker(String id) async => (await repo.loadCategories()).expand((c) => c.trackers).firstWhere((t) => t.id == id);

  group('Regeln', () {
    test('ein neuer Typ ohne passendes Zeitverhalten springt aufs erste passende', () {
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't-strom'))
        ..setKind(FieldKind.number)
        ..setRole(FieldRole.meterReading)
        ..setKind(FieldKind.date);
      expect(cubit.state.role, FieldRole.deadline);
      cubit.setKind(FieldKind.text);
      expect(cubit.state.role, FieldRole.info);
    });

    test('Zeitverhalten, das nicht zum Typ passt, wird ignoriert', () {
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't-strom'))
        ..setKind(FieldKind.text)
        ..setRole(FieldRole.meterReading);
      expect(cubit.state.role, FieldRole.info);
    });

    test('mit gespeicherten Werten nur Typen derselben Wertspalte', () {
      const field = FieldDefinition(id: 'f', name: 'Stand', kind: FieldKind.number, role: FieldRole.meterReading);
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't', field: field, hasValues: true));
      expect(cubit.state.canPick(FieldKind.currency), isTrue);
      expect(cubit.state.canPick(FieldKind.text), isFalse);
      cubit.setKind(FieldKind.text);
      expect(cubit.state.kind, FieldKind.number);
    });

    test('Formel: speicherbar erst mit gültigem Ausdruck aus bekannten Namen', () {
      final golf = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-auto').trackers.single;
      final cubit = FieldEditorCubit(repo, FieldEditorArgs(trackerId: golf.id, tracker: golf))
        ..setName('Kosten je km')
        ..setKind(FieldKind.formula);
      expect(cubit.state.kind, FieldKind.formula);
      expect(cubit.state.role, FieldRole.snapshot);
      expect(cubit.state.canSave, isFalse);
      cubit.setFormula('tanken / strecke');
      expect(cubit.state.formulaCheck.isValid, isFalse);
      expect(cubit.state.canSave, isFalse);
      cubit.setFormula('tanken / verbrauch');
      expect(cubit.state.canSave, isTrue);
      expect(cubit.state.draft.formula, 'tanken / verbrauch');
    });

    test('Feld mit Werten wird keine Formel (Formeln speichern nichts)', () {
      const field = FieldDefinition(id: 'f', name: 'Stand', kind: FieldKind.number, role: FieldRole.meterReading);
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't', field: field, hasValues: true));
      expect(cubit.state.canPick(FieldKind.formula), isFalse);
    });

    test('Abschlag ist ein Zeitverhalten für Beträge', () {
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't'))
        ..setName('Abschlag')
        ..setKind(FieldKind.currency)
        ..setRole(FieldRole.instalment);
      expect(cubit.state.draft.role, FieldRole.instalment);
    });

    test('Auswahl braucht mindestens einen Wert, doppelte zählen nicht', () {
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't'))
        ..setName('Kündigungsfrist')
        ..setKind(FieldKind.choice);
      expect(cubit.state.canSave, isFalse);
      cubit
        ..addChoice(' 1 Monat ')
        ..addChoice('1 Monat')
        ..addChoice('3 Monate');
      expect(cubit.state.choices, ['1 Monat', '3 Monate']);
      expect(cubit.state.canSave, isTrue);
      cubit.removeChoice('1 Monat');
      expect(cubit.state.draft.choices, ['3 Monate']);
    });

    test('Umrechnungsfaktor mit Komma, nur für Zählerstände', () {
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't'))
        ..setName('Gas')
        ..setKind(FieldKind.number)
        ..setRole(FieldRole.meterReading)
        ..setUnit('m³')
        ..setConsumptionUnit('kWh')
        ..setFactor('10,35');
      expect(cubit.state.draft.factor, 10.35);
      expect(cubit.state.draft.consumptionUnit, 'kWh');
      cubit.setFactor('0');
      expect(cubit.state.canSave, isFalse);
      cubit.setRole(FieldRole.snapshot);
      expect(cubit.state.canSave, isTrue);
      expect(cubit.state.draft.factor, 1);
      expect(cubit.state.draft.consumptionUnit, isNull);
    });

    test('Intervall gilt nur für wiederkehrende Beträge', () {
      final cubit = FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't'))
        ..setName('Versicherung')
        ..setKind(FieldKind.currency)
        ..setRole(FieldRole.recurringCost)
        ..setInterval(12);
      expect(cubit.state.draft.intervalMonths, 12);
      cubit.setRole(FieldRole.oneOffCost);
      expect(cubit.state.draft.intervalMonths, 1);
    });
  });

  blocTest<FieldEditorCubit, FieldEditorState>(
    'legt ein neues Feld am Ende des Trackers an',
    build: () => FieldEditorCubit(repo, const FieldEditorArgs(trackerId: 't-wasser', sort: 1)),
    act: (cubit) => cubit
      ..setName('Warmwasser-Anteil')
      ..setKind(FieldKind.percent)
      ..save(),
    skip: 2,
    expect: () => [
      isA<FieldEditorState>().having((s) => s.saving, 'saving', isTrue),
      isA<FieldEditorState>().having((s) => s.event?.kind, 'event', FieldEditorEventKind.saved),
    ],
    verify: (_) async => expect((await tracker('t-wasser')).fields.last.name, 'Warmwasser-Anteil'),
  );

  blocTest<FieldEditorCubit, FieldEditorState>(
    'ändert ein vorhandenes Feld',
    build: () => FieldEditorCubit(
      repo,
      FieldEditorArgs(trackerId: 't-strom', field: MockCategoriesRepository.categories.first.trackers.first.fields.first, hasValues: true),
    ),
    act: (cubit) => cubit
      ..setName('Stand Hauptzähler')
      ..save(),
    skip: 1,
    expect: () => [
      isA<FieldEditorState>().having((s) => s.saving, 'saving', isTrue),
      isA<FieldEditorState>().having((s) => s.event?.kind, 'event', FieldEditorEventKind.saved),
    ],
    verify: (_) async {
      final field = (await tracker('t-strom')).fields.first;
      expect((field.name, field.role, field.unit), ('Stand Hauptzähler', FieldRole.meterReading, 'kWh'));
    },
  );

  blocTest<FieldEditorCubit, FieldEditorState>(
    'entfernt ein Feld',
    build: () => FieldEditorCubit(repo, FieldEditorArgs(trackerId: 't-strom', field: MockCategoriesRepository.categories.first.trackers.first.fields.last)),
    act: (cubit) => cubit.archive(),
    expect: () => [
      isA<FieldEditorState>().having((s) => s.saving, 'saving', isTrue),
      isA<FieldEditorState>().having((s) => s.event?.kind, 'event', FieldEditorEventKind.archived),
    ],
    verify: (_) async => expect((await tracker('t-strom')).fields.map((f) => f.name), isNot(contains('Anbieter'))),
  );

  group('Rechnungen brauchen den Arbeitspreis', () {
    const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³');
    const price = FieldDefinition(id: 'preis', name: 'Preis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/m³');
    final bill = Entry(id: 'b', date: DateTime.utc(2025, 12, 31), values: const {'stand': 84}, periodStart: DateTime.utc(2025), periodEnd: DateTime.utc(2025, 12, 31));

    FieldEditorCubit edit(List<Entry> entries) {
      final t = Tracker(id: 't', name: 'Wasser', fields: const [meter, price], entries: entries);
      return FieldEditorCubit(repo, FieldEditorArgs(trackerId: 't', tracker: t, field: price, hasValues: true));
    }

    test('mit Rechnungen: nicht archivierbar, Zeitverhalten bleibt', () async {
      final cubit = edit([bill]);
      expect(cubit.state.keepsBills, isTrue);
      expect(cubit.state.canArchive, isFalse);
      cubit.setRole(FieldRole.recurringCost);
      expect(cubit.state.canSave, isFalse);
      await cubit.archive();
      expect(cubit.state.event, isNull);
    });

    test('ohne Rechnungen: wie bisher', () {
      final cubit = edit([]);
      expect(cubit.state.keepsBills, isFalse);
      expect(cubit.state.canArchive, isTrue);
      cubit.setRole(FieldRole.recurringCost);
      expect(cubit.state.canSave, isTrue);
    });
  });
}
