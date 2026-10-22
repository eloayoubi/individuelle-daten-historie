import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/home/data/home_overview.dart';

void main() {
  final today = DateTime.utc(2026, 10, 22);
  final overview = HomeOverview.build(MockCategoriesRepository.categories, today);

  test('sortiert Kategorien nach Kosten seit Januar', () {
    final costs = [for (final s in overview.categories) s.costToDate];
    expect(costs, [...costs]..sort((a, b) => b.compareTo(a)));
    expect(overview.categories.first.category.id, 'c-miete');
    expect(overview.costToDate, closeTo(costs.fold(0.0, (a, b) => a + b), 1e-6));
  });

  test('rechnet eine Prognose fürs nächste Jahr aus zwölf Monaten', () {
    expect(overview.monthsThisYear, hasLength(12));
    expect(overview.monthsNextYear, hasLength(12));
    expect(overview.forecast, greaterThan(overview.costToDate));
    expect(overview.forecastChange, isNotNull);
    expect(overview.forecastRange, inExclusiveRange(0, overview.forecast * 0.1));
  });

  test('Kosten, die in einer anderen Kategorie stecken, zählen nicht doppelt – es bleibt der Verbrauch', () {
    final wasser = overview.categories.firstWhere((s) => s.category.id == 'c-wasser');
    expect(wasser.costToDate, 0);
    expect(wasser.usage, greaterThan(0));
    expect(wasser.usageUnit, 'm³');
  });

  test('erinnert an nahe Stichtage zuerst, dann an lange nicht abgelesene Zähler', () {
    final r = overview.reminders;
    expect([for (final x in r.where((x) => x.kind == ReminderKind.deadline)) x.trackerName], ['Glasfaser 250', 'Golf', 'Hauptzähler']);
    expect(r.first.days, 70);
    expect([for (final x in r.where((x) => x.kind == ReminderKind.readMeter)) (x.trackerName, x.days)], [('Kaltwasser', 113), ('Gaszähler', 47), ('Hauptzähler', 40)]);
  });

  test('leere Daten ergeben eine leere Übersicht', () {
    final empty = HomeOverview.build(const [], today);
    expect(empty.isEmpty, isTrue);
    expect(empty.forecast, 0);
    expect(empty.costChange, isNull);
  });
}
