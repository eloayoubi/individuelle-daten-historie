import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/entries/cubit/tracker_cubit.dart';
import 'package:kostenkurve/features/entries/data/tracker_history.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  Tracker tracker(String categoryId) => MockCategoriesRepository.categories.firstWhere((c) => c.id == categoryId).trackers.first;

  group('TrackerHistory', () {
    test('Zähler mit Preis: Kosten und Verbrauch, Zähler ohne Preis: nur Verbrauch, Verträge: nur Kosten', () {
      expect(TrackerHistory.metricsFor(tracker('c-strom')), [HistoryMetric.cost, HistoryMetric.consumption]);
      expect(TrackerHistory.metricsFor(tracker('c-wasser')), [HistoryMetric.consumption]);
      expect(TrackerHistory.metricsFor(tracker('c-abos')), [HistoryMetric.cost]);
      expect(TrackerHistory.metricsFor(const Tracker(id: 't', name: 'Leer')), isEmpty);
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
}
