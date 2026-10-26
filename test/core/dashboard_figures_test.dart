import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/models/tracking_codec.dart';
import 'package:kostenkurve/core/utils/dashboard_figures.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const meter = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
const price = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh');
const base = FieldDefinition(id: 'gp', name: 'Grundpreis', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat');
const fuel = FieldDefinition(id: 'tank', name: 'Tanken', kind: FieldKind.currency, role: FieldRole.oneOffCost);
const km = FieldDefinition(id: 'km', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.snapshot, unit: 'km');
const provider = FieldDefinition(id: 'anbieter', name: 'Anbieter', kind: FieldKind.text);

Entry e(String id, DateTime date, Map<String, Object> values) => Entry(id: id, date: date, values: values);

/// Strom: 10 kWh am Tag ab 1.1.2026, 0,30 €/kWh, 12 €/Monat Grundpreis.
Tracker strom() => Tracker(
  id: 't-strom',
  name: 'Stromzähler',
  fields: const [meter, price, base, provider],
  entries: [
    e('p', d(2026, 1, 1), {'ap': 0.30, 'gp': 12}),
    e('r1', d(2026, 1, 1), {'stand': 1000}),
    e('r2', d(2026, 3, 1), {'stand': 1590}),
    e('r3', d(2026, 5, 1), {'stand': 2200}),
  ],
);

void main() {
  final marchApril = DateSpan(d(2026, 3, 1), d(2026, 5, 1));

  group('Feld zusammenfassen', () {
    test('Zählerstand: Differenz ist der Verbrauch (neuer minus alter Stand)', () {
      expect(meter.effectiveSummary, FieldSummary.difference);
      expect(DashboardFigures.fieldValue(strom(), meter, marchApril), closeTo(610, 1e-9));
    });

    test('Zählerstand als letzter Wert: der Stand am Ende des Zeitraums', () {
      const latest = FieldDefinition(id: 'stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, summary: FieldSummary.latest);
      expect(DashboardFigures.fieldValue(strom(), latest, DateSpan(d(2026, 1, 1), d(2026, 4, 1))), 1590);
    });

    test('Differenz eines Momentwerts verteilt linear zwischen zwei Einträgen', () {
      const driven = FieldDefinition(id: 'km', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.snapshot, summary: FieldSummary.difference);
      final t = Tracker(
        id: 't',
        name: 'Auto',
        fields: const [driven],
        entries: [
          e('a', d(2026, 1, 1), {'km': 10000}),
          e('b', d(2026, 1, 11), {'km': 10500}),
        ],
      );
      expect(DashboardFigures.fieldValue(t, driven, DateSpan(d(2026, 1, 1), d(2026, 1, 6))), closeTo(250, 1e-9));
      // Vor dem ersten und nach dem letzten Eintrag ändert sich nichts.
      expect(DashboardFigures.fieldValue(t, driven, DateSpan(d(2025, 1, 1), d(2027, 1, 1))), closeTo(500, 1e-9));
    });

    test('Summe addiert einmalige Beträge im Zeitraum', () {
      final t = Tracker(
        id: 't',
        name: 'Auto',
        fields: const [fuel],
        entries: [
          e('a', d(2026, 2, 28), {'tank': 50}),
          e('b', d(2026, 3, 5), {'tank': 60}),
          e('c', d(2026, 4, 30), {'tank': 70}),
        ],
      );
      expect(fuel.effectiveSummary, FieldSummary.sum);
      expect(DashboardFigures.fieldValue(t, fuel, marchApril), closeTo(130, 1e-9));
    });

    test('Summe eines wiederkehrenden Betrags zählt je Monatserstem voll', () {
      // März und April: 2 × 12 €; Juni bis heute (15.): 12 €; 16. Juni bis 15. Juli: der Juli.
      expect(DashboardFigures.fieldValue(strom(), base, marchApril), closeTo(24, 1e-9));
      expect(DashboardFigures.fieldValue(strom(), base, DateSpan(d(2026, 6, 1), d(2026, 6, 16))), closeTo(12, 1e-9));
      expect(DashboardFigures.fieldValue(strom(), base, DateSpan(d(2026, 6, 16), d(2026, 7, 16))), closeTo(12, 1e-9));
      expect(DashboardFigures.fieldValue(strom(), base, DateSpan(d(2026, 6, 2), d(2026, 7, 1))), 0);
    });

    test('Durchschnitt, kleinster und größter Wert über die Einträge im Zeitraum', () {
      FieldDefinition summarized(FieldSummary s) => FieldDefinition(id: 'km', name: 'km', kind: FieldKind.number, role: FieldRole.snapshot, summary: s);
      final t = Tracker(
        id: 't',
        name: 'Auto',
        fields: [summarized(FieldSummary.average)],
        entries: [
          e('a', d(2026, 3, 1), {'km': 10}),
          e('b', d(2026, 3, 2), {'km': 30}),
          e('c', d(2026, 6, 1), {'km': 99}),
        ],
      );
      expect(DashboardFigures.fieldValue(t, summarized(FieldSummary.average), marchApril), 20);
      expect(DashboardFigures.fieldValue(t, summarized(FieldSummary.min), marchApril), 10);
      expect(DashboardFigures.fieldValue(t, summarized(FieldSummary.max), marchApril), 30);
      expect(DashboardFigures.fieldValue(t, summarized(FieldSummary.average), DateSpan(d(2025, 1, 1), d(2025, 2, 1))), isNull);
    });

    test('unpassende Wahl fällt auf den Standard des Zeitverhaltens zurück, Text hat keine', () {
      const wrong = FieldDefinition(id: 'ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, summary: FieldSummary.sum);
      expect(wrong.effectiveSummary, FieldSummary.latest);
      expect(provider.effectiveSummary, isNull);
      expect(km.effectiveSummary, FieldSummary.latest);
    });
  });

  group('Zeiträume', () {
    final today = d(2026, 10, 26);

    test('laufende Zeiträume reichen bis heute, Vergleich ist derselbe Abschnitt davor', () {
      final year = DashboardFigures.span(DashboardPeriod.thisYear, today);
      expect(year, DateSpan(d(2026, 1, 1), d(2026, 10, 27)));
      expect(DashboardFigures.previous(DashboardPeriod.thisYear, year), DateSpan(d(2025, 1, 1), d(2025, 10, 27)));

      final month = DashboardFigures.span(DashboardPeriod.thisMonth, today);
      expect(month, DateSpan(d(2026, 10, 1), d(2026, 10, 27)));
      expect(DashboardFigures.previous(DashboardPeriod.thisMonth, month), DateSpan(d(2026, 9, 1), d(2026, 9, 27)));
    });

    test('abgeschlossene, gleitende, eigene und gesamte Zeiträume', () {
      expect(DashboardFigures.span(DashboardPeriod.lastMonth, today), DateSpan(d(2026, 9, 1), d(2026, 10, 1)));
      expect(DashboardFigures.span(DashboardPeriod.lastYear, today), DateSpan(d(2025, 1, 1), d(2026, 1, 1)));
      expect(DashboardFigures.span(DashboardPeriod.last12Months, today), DateSpan(d(2025, 10, 27), d(2026, 10, 27)));
      final custom = DateSpan(d(2026, 3, 1), d(2026, 3, 11));
      expect(DashboardFigures.span(DashboardPeriod.custom, today, custom: custom), custom);
      expect(DashboardFigures.previous(DashboardPeriod.custom, custom), DateSpan(d(2026, 2, 19), d(2026, 3, 1)));
      expect(DashboardFigures.span(DashboardPeriod.all, today, firstDay: d(2024, 5, 1)).from, d(2024, 5, 1));
      expect(DashboardFigures.previous(DashboardPeriod.all, custom), isNull);
    });

    test('Monatsende bleibt beim Verschieben im Monat (31.3. → 28.2.)', () {
      expect(DashboardFigures.previous(DashboardPeriod.thisMonth, DateSpan(d(2026, 3, 1), d(2026, 3, 31))), DateSpan(d(2026, 2, 1), d(2026, 2, 28)));
    });
  });

  group('Kennzahlen der Kategorie', () {
    Category category({CategoryDashboard dashboard = const CategoryDashboard(), List<Tracker>? trackers}) =>
        Category(id: 'c', name: 'Strom', icon: CategoryIcon.bolt, swatch: CategorySwatch.orange, trackers: trackers ?? [strom()], dashboard: dashboard);

    test('ohne Wahl: Kosten und Verbrauch des Zählers', () {
      expect(DashboardFigures.shown(category()), const [DashboardMetric.cost(), DashboardMetric.field(trackerId: 't-strom', fieldId: 'stand')]);
    });

    test('Auswahl: nur Felder mit Zahlen, Kosten je Tracker erst ab zwei Trackern', () {
      expect(DashboardFigures.options(category()), const [
        DashboardMetric.cost(),
        DashboardMetric.field(trackerId: 't-strom', fieldId: 'stand'),
        DashboardMetric.field(trackerId: 't-strom', fieldId: 'ap'),
        DashboardMetric.field(trackerId: 't-strom', fieldId: 'gp'),
      ]);
    });

    test('gewählte Kennzahlen in ihrer Reihenfolge, verschwundene Felder fallen weg', () {
      const chosen = CategoryDashboard(
        metrics: [
          DashboardMetric.field(trackerId: 't-strom', fieldId: 'ap'),
          DashboardMetric.field(trackerId: 't-strom', fieldId: 'weg'),
          DashboardMetric.cost(),
        ],
      );
      expect(DashboardFigures.shown(category(dashboard: chosen)), const [DashboardMetric.field(trackerId: 't-strom', fieldId: 'ap'), DashboardMetric.cost()]);
    });

    test('rechnet Euro und kWh im Zeitraum, mit Vergleich', () {
      final figures = DashboardFigures.build(category(), marchApril, previous: DateSpan(d(2026, 1, 1), d(2026, 3, 1)), today: d(2026, 5, 1));
      final cost = figures.first, usage = figures.last;
      // 610 kWh × 0,30 € + 2 × 12 € Grundpreis.
      expect(cost.value, closeTo(610 * 0.30 + 24, 1e-6));
      expect(usage.isConsumption, isTrue);
      expect(usage.value, closeTo(610, 1e-9));
      expect(usage.previous, closeTo(590, 1e-9));
      expect(usage.change, closeTo(20 / 590, 1e-9));
    });

    test('Kosten, die in einer anderen aktiven Kategorie stecken, zählen in der Summe nicht', () {
      final inRent = Tracker(
        id: 't-wasser',
        name: 'Wasser',
        fields: const [base],
        entries: [
          e('w', d(2026, 1, 1), {'gp': 30}),
        ],
        includedIn: 'c-miete',
      );
      final c = category(trackers: [strom(), inRent]);
      double total(Set<String> elsewhere) => DashboardFigures.build(c, marchApril, today: d(2026, 5, 1), elsewhere: elsewhere).first.value!;
      expect(total({'c-miete'}), closeTo(610 * 0.30 + 24, 1e-6));
      expect(total({}), closeTo(610 * 0.30 + 24 + 60, 1e-6));
    });
  });

  group('Speichern', () {
    test('Dashboard und Auswertung überstehen JSON und Offline-Cache', () {
      const dashboard = CategoryDashboard(
        metrics: [
          DashboardMetric.cost(),
          DashboardMetric.field(trackerId: 't', fieldId: 'f'),
        ],
        showAddTracker: false,
      );
      expect(CategoryDashboard.fromJson(dashboard.toJson()), dashboard);
      expect(const CategoryDashboard().toJson(), isEmpty);
      expect(CategoryDashboard.fromJson({}), const CategoryDashboard());
      expect(CategoryDashboard.fromJson('kaputt'), const CategoryDashboard());

      const field = FieldDefinition(id: 'km', name: 'km', kind: FieldKind.number, role: FieldRole.snapshot, summary: FieldSummary.difference);
      const c = Category(
        id: 'c',
        name: 'Auto',
        icon: CategoryIcon.car,
        swatch: CategorySwatch.green,
        trackers: [
          Tracker(id: 't', name: 'Golf', fields: [field]),
        ],
        dashboard: dashboard,
      );
      expect(TrackingCodec.categoryFrom(TrackingCodec.category(c)), c);
    });

    test('Umzug ordnet Tracker und Felder neu zu, Kennzahlen ohne Gegenstück fallen weg', () {
      const dashboard = CategoryDashboard(
        metrics: [
          DashboardMetric.cost(),
          DashboardMetric.cost(trackerId: 'alt-t'),
          DashboardMetric.field(trackerId: 'alt-t', fieldId: 'alt-f'),
          DashboardMetric.field(trackerId: 'alt-t', fieldId: 'weg'),
        ],
      );
      expect(dashboard.remap({'alt-t': 'neu-t'}, {'alt-f': 'neu-f'}).metrics, const [
        DashboardMetric.cost(),
        DashboardMetric.cost(trackerId: 'neu-t'),
        DashboardMetric.field(trackerId: 'neu-t', fieldId: 'neu-f'),
      ]);
    });
  });
}
