import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
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

  test('Kosten, die in einer fehlenden oder archivierten Kategorie stecken sollen, zählen hier', () {
    final miete = MockCategoriesRepository.categories.firstWhere((c) => c.id == 'c-miete');
    final archived = Category(id: miete.id, name: miete.name, icon: miete.icon, swatch: miete.swatch, trackers: miete.trackers, archivedAt: today);
    final others = [for (final c in MockCategoriesRepository.categories) if (c.id != 'c-miete') c];
    for (final categories in [others, [...others, archived]]) {
      final wasser = HomeOverview.build(categories, today).categories.firstWhere((s) => s.category.id == 'c-wasser');
      expect(wasser.costToDate, greaterThan(0));
    }
  });

  test('erinnert an nahe Stichtage zuerst, dann an lange nicht abgelesene Zähler', () {
    final r = overview.reminders;
    expect([for (final x in r.where((x) => x.kind == ReminderKind.deadline)) x.trackerName], ['Glasfaser 250', 'Golf', 'Hauptzähler']);
    expect(r.first.days, 70);
    expect([for (final x in r.where((x) => x.kind == ReminderKind.readMeter)) (x.trackerName, x.days)], [('Kaltwasser', 113), ('Gaszähler', 47), ('Hauptzähler', 40)]);
  });

  group('unterjährig angefangen', () {
    const rent = FieldDefinition(id: 'miete', name: 'Miete', kind: FieldKind.currency, role: FieldRole.recurringCost);
    Category wohnung(DateTime since) => Category(
      id: 'c',
      name: 'Wohnung',
      icon: CategoryIcon.house,
      swatch: CategorySwatch.brown,
      trackers: [
        Tracker(id: 't', name: 'Miete', fields: const [rent], entries: [Entry(id: 'e', date: since, values: const {'miete': 1400})]),
      ],
    );

    test('vergleicht die Prognose nicht mit einem halb leeren Jahr', () {
      final o = HomeOverview.build([wohnung(DateTime.utc(2026, 10, 1))], today);
      expect(o.forecast, closeTo(12 * 1400, 1e-6));
      expect(o.forecastChange, isNull);
      expect(o.costChange, isNull);
      expect(o.firstTrackedMonth, 9);
    });

    test('nimmt als Monatsschnitt die Prognose, solange das Jahr nicht voll erfasst ist', () {
      final o = HomeOverview.build([wohnung(DateTime.utc(2026, 10, 1))], today);
      expect(o.categories.single.monthlyAverage, closeTo(1400, 1e-6));
    });

    test('vergleicht, sobald das ganze Jahr erfasst ist', () {
      final o = HomeOverview.build([wohnung(DateTime.utc(2025, 10, 1))], today);
      expect(o.forecastChange, closeTo(0, 1e-9));
      expect(o.firstTrackedMonth, 0);
      // Vorjahr erst ab Oktober erfasst: kein Vergleich „bis heute“.
      expect(o.costChange, isNull);
    });
  });

  test('leere Daten ergeben eine leere Übersicht', () {
    final empty = HomeOverview.build(const [], today);
    expect(empty.isEmpty, isTrue);
    expect(empty.forecast, 0);
    expect(empty.costChange, isNull);
  });

  test('keine Ablese-Erinnerung, wenn der Verbrauch aus Rechnungen kommt', () {
    const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
    const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice);
    final category = Category(
      id: 'c',
      name: 'Strom',
      icon: CategoryIcon.bolt,
      swatch: CategorySwatch.orange,
      trackers: [
        Tracker(
          id: 't',
          name: 'Zähler',
          fields: const [meter, price],
          entries: [Entry(id: 'b', date: DateTime.utc(2026, 8, 23), values: const {'stand': 508}, periodStart: DateTime.utc(2026, 2, 23), periodEnd: DateTime.utc(2026, 8, 23))],
        ),
      ],
    );
    final r = HomeOverview.build([category], today).reminders;
    expect(r.where((x) => x.kind == ReminderKind.readMeter), isEmpty);
    expect(HomeOverview.build([category], today).categories.single.usage, greaterThan(0));
  });
}
