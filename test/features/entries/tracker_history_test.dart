import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/memory_categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/entries/cubit/tracker_cubit.dart';
import 'package:kostenkurve/features/entries/data/tracker_history.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  Tracker tracker(String categoryId) => MockCategoriesRepository.categories.firstWhere((c) => c.id == categoryId).trackers.first;

  group('TrackerHistory', () {
    test('Zähler mit Preis: Kosten und Verbrauch, Zähler ohne Preis: nur Verbrauch, Verträge: nur Kosten', () {
      expect(TrackerHistory.metricsFor(tracker('c-strom')), [HistoryMetric.cost, HistoryMetric.consumption]);
      expect(TrackerHistory.metricsFor(tracker('c-wasser')), [HistoryMetric.cost, HistoryMetric.consumption]);
      expect(TrackerHistory.metricsFor(tracker('c-abos')), [HistoryMetric.cost]);
      expect(TrackerHistory.metricsFor(const Tracker(id: 't', name: 'Leer')), isEmpty);
    });

    test('beginnt erst mit dem Monat des ersten Eintrags', () {
      const price = FieldDefinition(id: 'p', name: 'Preis', kind: FieldKind.currency, role: FieldRole.oneOffCost);
      final t = Tracker(id: 't', name: 'Spiele', fields: const [price], entries: [Entry(id: 'e', date: DateTime.utc(2026, 9, 3), values: const {'p': 80})]);
      final h = TrackerHistory.build(t, now, HistoryMetric.cost);
      expect([for (final m in h.months) m.month], [DateTime.utc(2026, 9), DateTime.utc(2026, 10)]);
      expect(h.months.first.value, closeTo(80, 1e-9));
    });

    test('zwölf Monate bis zum laufenden, mit Vorjahr und Prognose', () {
      final h = TrackerHistory.build(tracker('c-heizung'), now, HistoryMetric.consumption);
      expect(h.months, hasLength(12));
      expect(h.months.first.month, DateTime.utc(2025, 11));
      expect(h.months.last.month, DateTime.utc(2026, 10));
      expect(h.unit, 'kWh');
      expect(h.hasData, isTrue);
      // Heizung: Winter deutlich über Sommer.
      final january = h.months.firstWhere((m) => m.month.month == 1).value;
      final july = h.months.firstWhere((m) => m.month.month == 7).value;
      expect(january, greaterThan(july * 4));
      expect(h.months.firstWhere((m) => m.month.month == 1).previousYear, isNotNull);
      expect(h.lastYearToDate, isNotNull);
      expect(h.forecastNextYear, greaterThan(h.thisYear));
    });

    test('aktuelle Werte mit schon eingetragener Änderung', () {
      final internet = tracker('c-internet');
      final values = TrackerHistory.currentValuesOf(internet, DateTime.utc(2026, 1, 15));
      final price = values.firstWhere((v) => v.field.role == FieldRole.recurringCost);
      expect(price.value, 39.99);
      expect(price.upcoming, 44.99);
      expect(price.upcomingFrom, DateTime.utc(2026, 2, 1));
    });
  });

  group('TrackerCubit', () {
    blocTest<TrackerCubit, TrackerState>(
      'lädt Tracker, Kennzahlen und Verlauf',
      build: () => TrackerCubit(MockCategoriesRepository(), const TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'), now: () => now),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<TrackerState>()
            .having((s) => s.status, 'status', TrackerStatus.ready)
            .having((s) => s.metric, 'metric', HistoryMetric.cost)
            .having((s) => s.entries.first.date.isAfter(s.entries.last.date), 'neueste zuerst', isTrue),
      ],
    );

    blocTest<TrackerCubit, TrackerState>(
      'wechselt auf Verbrauch',
      build: () => TrackerCubit(MockCategoriesRepository(), const TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom'), now: () => now),
      act: (cubit) async {
        await cubit.load();
        cubit.selectMetric(HistoryMetric.consumption);
      },
      skip: 1,
      expect: () => [isA<TrackerState>().having((s) => s.history?.unit, 'unit', 'kWh')],
    );

    blocTest<TrackerCubit, TrackerState>(
      'öffnet im gewünschten Reiter',
      build: () => TrackerCubit(
        MockCategoriesRepository(),
        const TrackerArgs(categoryId: 'c-strom', trackerId: 't-strom', metric: HistoryMetric.consumption),
        now: () => now,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [isA<TrackerState>().having((s) => s.metric, 'metric', HistoryMetric.consumption).having((s) => s.history?.unit, 'unit', 'kWh')],
    );

    blocTest<TrackerCubit, TrackerState>(
      'meldet einen fehlenden Tracker',
      build: () => TrackerCubit(MockCategoriesRepository(), const TrackerArgs(categoryId: 'c-strom', trackerId: 'weg'), now: () => now),
      act: (cubit) => cubit.load(),
      expect: () => [isA<TrackerState>().having((s) => s.status, 'status', TrackerStatus.missing)],
    );

    final waterRepo = MockCategoriesRepository();
    blocTest<TrackerCubit, TrackerState>(
      'zeigt einen neuen Eintrag nach dem Speichern',
      build: () => TrackerCubit(waterRepo, const TrackerArgs(categoryId: 'c-wasser', trackerId: 't-wasser'), now: () => now),
      act: (cubit) async {
        await cubit.load();
        await waterRepo.saveEntry('t-wasser', Entry(id: 'neu', date: DateTime.utc(2026, 10, 21), values: const {'f-wasser-stand': 600}));
        await pumpEventQueue();
      },
      skip: 1,
      expect: () => [isA<TrackerState>().having((s) => s.entries.first.id, 'neu', 'neu')],
    );
  });

  group('Rechnungen', () {
    const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
    const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);
    final bill = Entry(id: 'b', date: DateTime.utc(2026, 9, 30), values: const {'stand': 508}, periodStart: DateTime.utc(2026, 4), periodEnd: DateTime.utc(2026, 9, 30));

    test('zwei Stände am selben Tag ergeben noch keinen Verbrauch', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter, price],
        entries: [
          Entry(id: 'a', date: DateTime.utc(2026, 9, 1), values: const {'stand': 100}),
          Entry(id: 'b', date: DateTime.utc(2026, 9, 1), values: const {'stand': 120}),
        ],
      );
      expect(TrackerHistory.metricsFor(t), isEmpty);
    });

    test('eine Rechnung reicht für Verbrauch und Kosten', () {
      expect(TrackerHistory.metricsFor(Tracker(id: 't', name: 'Strom', fields: const [meter, price], entries: [bill])), [HistoryMetric.cost, HistoryMetric.consumption]);
    });

    test('Preisänderung von heute gilt schon kurz nach Mitternacht, nicht erst später', () {
      final t = Tracker(
        id: 't',
        name: 'Strom',
        fields: const [meter, price],
        entries: [Entry(id: 'p1', date: DateTime.utc(2026), values: const {'ap': 0.3}), Entry(id: 'p2', date: DateTime.utc(2026, 10, 25), values: const {'ap': 0.35})],
      );
      final contract = TrackerHistory.contractOf(t, DateTime(2026, 10, 25, 0, 30)).single;
      expect((contract.value, contract.upcoming), (0.35, null));
      const rent = FieldDefinition(id: 'miete', name: 'Miete', kind: FieldKind.currency, role: FieldRole.recurringCost);
      final wohnung = Tracker(
        id: 'w',
        name: 'Miete',
        fields: const [rent],
        entries: [Entry(id: 'm1', date: DateTime.utc(2026), values: const {'miete': 900}), Entry(id: 'm2', date: DateTime(2026, 10, 25, 12), values: const {'miete': 950})],
      );
      final value = TrackerHistory.currentValuesOf(wohnung, DateTime(2026, 10, 25, 8)).single;
      expect((value.value, value.upcoming), (950, null));
    });

    test('Versorgungszähler: aktuelle Werte ohne Preise, Zählerstand ohne Rechnungen', () {
      expect(TrackerHistory.currentValuesOf(tracker('c-strom'), now).where((v) => v.field.isRate), isEmpty);
      final onlyBill = Tracker(id: 't', name: 'Strom', fields: const [meter, price], entries: [bill, Entry(id: 'p', date: DateTime.utc(2026), values: const {'ap': 0.3})]);
      expect(TrackerHistory.currentValuesOf(onlyBill, now), isEmpty);
    });
  });

  group('Vertrag', () {
    Future<TrackerState> load(CategoriesRepository repo, String categoryId, String trackerId) async {
      final cubit = TrackerCubit(repo, TrackerArgs(categoryId: categoryId, trackerId: trackerId), now: () => now);
      await cubit.load();
      final state = cubit.state;
      await cubit.close();
      return state;
    }

    test('Strom: Vertrag zeigt Arbeitspreis, Grundpreis und Abschlag', () async {
      final s = await load(MockCategoriesRepository(), 'c-strom', 't-strom');
      expect(s.contract.map((v) => v.field.id), ['f-strom-ap', 'f-strom-gp', 'f-strom-abschlag']);
      expect(s.contract.first.value, 0.329);
      expect(s.contract.first.since, DateTime.utc(2025, 4, 1));
      expect(s.missingPrice, isFalse);
    });

    test('Preisänderungen stehen nicht in den Einträgen', () async {
      final s = await load(MockCategoriesRepository(), 'c-strom', 't-strom');
      expect(s.entries.map((e) => e.id), isNot(contains('e-strom-p1')));
      expect(s.entries.map((e) => e.id), isNot(contains('e-strom-p2')));
      expect(s.entries, isNotEmpty);
    });

    test('Preisverlauf neueste zuerst', () async {
      final s = await load(MockCategoriesRepository(), 'c-strom', 't-strom');
      final ap = s.tracker!.fields.firstWhere((f) => f.id == 'f-strom-ap');
      expect(s.priceHistory(ap).map((e) => e.id), ['e-strom-p2', 'e-strom-p1']);
    });

    test('Auto: kein Vertrag', () async {
      final s = await load(MockCategoriesRepository(), 'c-auto', 't-golf');
      expect(s.contract, isEmpty);
      expect(s.missingPrice, isFalse);
    });

    test('Rechnung ohne Arbeitspreis: Hinweis', () async {
      const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
      const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);
      final repo = MemoryCategoriesRepository(
        seed: [
          Category(
            id: 'c',
            name: 'Strom',
            icon: CategoryIcon.bolt,
            swatch: CategorySwatch.orange,
            trackers: [
              Tracker(
                id: 't',
                name: 'Zähler',
                fields: const [meter, price],
                entries: [Entry(id: 'b', date: DateTime.utc(2026, 9, 30), values: const {'stand': 508}, periodStart: DateTime.utc(2026, 4), periodEnd: DateTime.utc(2026, 9, 30))],
              ),
            ],
          ),
        ],
      );
      final s = await load(repo, 'c', 't');
      expect(s.missingPrice, isTrue);
      expect(s.metric, HistoryMetric.consumption);
      expect(s.contract, isEmpty);
      expect(s.entries.map((e) => e.id), ['b']);
    });
  });
}
