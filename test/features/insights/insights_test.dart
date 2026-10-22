import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/insights/cubit/insights_cubit.dart';
import 'package:kostenkurve/features/insights/data/insights.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);
  final categories = MockCategoriesRepository.categories;

  group('Insights', () {
    final i = Insights.build(categories, now, 2026);

    test('vergleicht kein volles Jahr mit einem unterjährig angefangenen', () {
      const rent = FieldDefinition(id: 'miete', name: 'Miete', kind: FieldKind.currency, role: FieldRole.recurringCost);
      final wohnung = Category(
        id: 'c',
        name: 'Wohnung',
        icon: CategoryIcon.house,
        swatch: CategorySwatch.brown,
        trackers: [
          Tracker(id: 't', name: 'Miete', fields: const [rent], entries: [Entry(id: 'e', date: DateTime.utc(2026, 10, 1), values: const {'miete': 1400})]),
        ],
      );
      final next = Insights.build([wohnung], DateTime(2027, 6, 1), 2027);
      final row = next.comparisons.single;
      expect(row.previous, closeTo(3 * 1400, 1e-6));
      expect(row.change, isNull);
      expect(next.change, isNull);
      expect(Insights.build([wohnung], DateTime(2026, 10, 22), 2026).firstMonth, 9);
      expect(next.firstMonth, 0);
    });

    test('Jahresvergleich nach Kosten, Summe aus den Monaten', () {
      expect(i.comparisons.first.category.id, 'c-miete');
      expect(i.total, closeTo([for (var m = 0; m < 12; m++) i.monthTotal(m)].fold(0.0, (a, b) => a + b), 1e-6));
      expect(i.previousTotal, greaterThan(0));
      expect(i.isProjected(10), isTrue);
      expect(i.isProjected(9), isFalse);
    });

    test('Kosten aus anderen Kategorien zählen nicht doppelt, werden aber genannt', () {
      expect(i.comparisons.map((c) => c.category.id), isNot(contains('c-wasser')));
      final note = i.included.single;
      expect((note.tracker.id, note.into.id), ('t-wasser', 'c-miete'));
      expect(note.cost, greaterThan(300));
      expect(i.consumption.map((c) => c.tracker.id), contains('t-wasser'));
    });

    test('Prognose mit Spanne und Aufteilung, Trend der Zähler', () {
      expect(i.forecast, closeTo(i.forecastParts.total, 1e-6));
      expect(i.forecastRange, greaterThan(0));
      expect(i.forecastParts.fixed, greaterThan(i.forecastParts.meter));
      expect(i.categoryForecasts.first.category.id, 'c-miete');
      expect(i.trends.map((t) => t.tracker.id), containsAll(['t-strom', 't-gas']));
      expect(i.trends.every((t) => t.trend < 1), isTrue);
    });

    test('Abschlags-Check für Strom und Gas', () {
      final strom = i.instalments.firstWhere((c) => c.tracker.id == 't-strom');
      expect(strom.paid, closeTo(12 * 85, 1e-6));
      expect(strom.balance, closeTo(strom.paid - strom.cost, 1e-9));
      expect(strom.suggestedMonthly, (strom.cost / 12).ceilToDouble());
      expect(i.instalments.map((c) => c.tracker.id), containsAll(['t-strom', 't-gas']));
    });

    test('früheres Jahr: ganze Jahre, keine Prognose', () {
      final last = Insights.build(categories, now, 2025);
      expect(last.forecast, isNull);
      expect(last.isProjected(11), isFalse);
      expect(last.total, greaterThan(0));
    });

    test('Jahre mit Daten', () {
      expect(Insights.yearsOf(categories, now), [2024, 2025, 2026]);
      expect(Insights.yearsOf(const [], now), [2026]);
    });
  });

  group('InsightsCubit', () {
    blocTest<InsightsCubit, InsightsState>(
      'lädt das laufende Jahr',
      build: () => InsightsCubit(MockCategoriesRepository(), now: () => now),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<InsightsState>().having((s) => s.year, 'year', 2026).having((s) => s.years, 'years', [2024, 2025, 2026]).having((s) => s.insights?.forecast, 'forecast', isNotNull),
      ],
    );

    blocTest<InsightsCubit, InsightsState>(
      'wechselt das Jahr',
      build: () => InsightsCubit(MockCategoriesRepository(), now: () => now),
      act: (cubit) async {
        await cubit.load();
        cubit
          ..selectYear(2025)
          ..selectYear(1999);
      },
      skip: 1,
      expect: () => [isA<InsightsState>().having((s) => s.insights?.year, 'year', 2025).having((s) => s.insights?.forecast, 'forecast', isNull)],
    );

    blocTest<InsightsCubit, InsightsState>(
      'archivierte Kategorien fehlen',
      build: () => InsightsCubit(MockCategoriesRepository(seed: [categories.first.copyWith(archivedAt: () => DateTime.utc(2026)), ...categories.skip(1)]), now: () => now),
      act: (cubit) => cubit.load(),
      expect: () => [isA<InsightsState>().having((s) => s.insights?.comparisons.map((c) => c.category.id), 'ids', isNot(contains('c-strom')))],
    );
  });
}
