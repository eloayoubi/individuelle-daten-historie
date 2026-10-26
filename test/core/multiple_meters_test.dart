import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/models/tracking_codec.dart';
import 'package:kostenkurve/core/utils/cost_engine.dart';
import 'package:kostenkurve/core/utils/dashboard_figures.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const badKalt = FieldDefinition(id: 'bk', name: 'Bad kalt', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', meterGroup: 'Kaltwasser');
const badWarm = FieldDefinition(id: 'bw', name: 'Bad warm', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', meterGroup: 'Warmwasser');
const wcKalt = FieldDefinition(id: 'wk', name: 'WC kalt', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', meterGroup: 'Kaltwasser');
const price = FieldDefinition(id: 'ap', name: 'Wasser & Abwasser', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/m³');
const base = FieldDefinition(id: 'gp', name: 'Grundgebühr', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat');

Entry e(String id, DateTime date, Map<String, Object> values) => Entry(id: id, date: date, values: values);

/// Drei Zähler, je 1.1. und 31.1. abgelesen (30 Tage): Bad kalt 3 m³, Bad warm 1,5 m³, WC kalt 0,6 m³.
/// 4 €/m³ und 10 €/Monat Grundgebühr.
Tracker wasser({List<FieldDefinition> meters = const [badKalt, badWarm, wcKalt]}) => Tracker(
  id: 't-wasser',
  name: 'Wasserzähler',
  fields: [...meters, price, base],
  entries: [
    e('p', d(2026, 1, 1), {'ap': 4, 'gp': 10}),
    e('r1', d(2026, 1, 1), {'bk': 100, 'bw': 50, 'wk': 20, 'a': 1, 'b': 1}),
    e('r2', d(2026, 1, 31), {'bk': 103, 'bw': 51.5, 'wk': 20.6, 'a': 2, 'b': 2}),
  ],
);

Category category(List<Tracker> trackers, {CategoryDashboard dashboard = const CategoryDashboard()}) =>
    Category(id: 'c', name: 'Wasser', icon: CategoryIcon.drop, swatch: CategorySwatch.blue, trackers: trackers, dashboard: dashboard);

void main() {
  final january = DateSpan(d(2026, 1, 1), d(2026, 1, 31));

  group('Rechnung mit mehreren Zählern', () {
    test('Verbrauch ist die Summe, der Arbeitspreis gilt für die Summe, die Grundgebühr einmal', () {
      final engine = CostEngine(wasser(), today: d(2026, 1, 31));
      expect(engine.consumption(january.from, january.to), closeTo(5.1, 1e-9));
      expect(engine.consumptionOf('bw', january.from, january.to), closeTo(1.5, 1e-9));
      expect(engine.consumptionOf('gibt-es-nicht', january.from, january.to), 0);
      expect(engine.cost(january.from, january.to), closeTo(5.1 * 4 + 10 * 30 / 31, 1e-9));
    });

    test('ein Zähler ohne zwei Stände zählt nicht, die anderen schon', () {
      final t = wasser().copyWith(
        entries: [
          e('r1', d(2026, 1, 1), {'bk': 100, 'bw': 50}),
          e('r2', d(2026, 1, 31), {'bk': 103}),
        ],
      );
      final engine = CostEngine(t, today: d(2026, 1, 31));
      expect(engine.hasMeter, isTrue);
      expect(engine.measuresField('bk'), isTrue);
      expect(engine.measuresField('bw'), isFalse);
      expect(engine.consumption(january.from, january.to), closeTo(3, 1e-9));
    });

    test('ein Stand nur des zweiten Zählers ist ein Zählerstand', () {
      final t = wasser();
      expect(t.isReading(e('x', d(2026, 2, 1), {'bw': 52})), isTrue);
      expect(t.isReading(e('y', d(2026, 2, 1), {'ap': 5})), isFalse);
    });
  });

  group('Kennzahlen mit mehreren Zählern', () {
    test('ohne Wahl: Kosten, dann je Gruppe eine Karte – Kalt- und Warmwasser getrennt', () {
      final c = category([wasser()]);
      expect(DashboardFigures.shown(c), const [
        DashboardMetric.cost(),
        DashboardMetric.meters(group: 'Kaltwasser'),
        DashboardMetric.meters(group: 'Warmwasser'),
      ]);
      final figures = DashboardFigures.build(c, january, today: d(2026, 1, 31));
      expect(figures[1].value, closeTo(3.6, 1e-9));
      expect(figures[1].meterCount, 2);
      expect(figures[1].isConsumption, isTrue);
      expect(figures[2].value, closeTo(1.5, 1e-9));
    });

    test('zur Wahl stehen alle Zähler zusammen, je Gruppe und jeder Zähler einzeln', () {
      final options = DashboardFigures.options(category([wasser()]));
      expect(
        options,
        containsAll(const [
          DashboardMetric.meters(),
          DashboardMetric.meters(group: 'Kaltwasser'),
          DashboardMetric.meters(group: 'Warmwasser'),
          DashboardMetric.field(trackerId: 't-wasser', fieldId: 'bw'),
        ]),
      );
    });

    test('alle Zähler zusammen und eine eigene Summe', () {
      final c = category(
        [wasser()],
        dashboard: const CategoryDashboard(
          metrics: [
            DashboardMetric.meters(),
            DashboardMetric.meters(fieldIds: ['bk', 'bw'], label: 'Bad'),
            DashboardMetric.field(trackerId: 't-wasser', fieldId: 'wk'),
          ],
        ),
      );
      final figures = DashboardFigures.build(c, january, today: d(2026, 1, 31));
      expect([for (final f in figures) f.value], [closeTo(5.1, 1e-9), closeTo(4.5, 1e-9), closeTo(0.6, 1e-9)]);
      expect([for (final f in figures) f.meterCount], [3, 2, 0]);
    });

    test('eine eigene Summe ohne vorhandene Zähler fällt weg', () {
      final c = category(
        [wasser()],
        dashboard: const CategoryDashboard(
          metrics: [
            DashboardMetric.meters(fieldIds: ['weg'], label: 'Alt'),
          ],
        ),
      );
      expect(DashboardFigures.shown(c), isEmpty);
    });

    test('ohne Gruppen: mehrere Zähler eines Trackers als eine Karte, Zähler verschiedener Tracker einzeln', () {
      const a = FieldDefinition(id: 'a', name: 'Bad', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³');
      const b = FieldDefinition(id: 'b', name: 'WC', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³');
      expect(DashboardFigures.shown(category([wasser(meters: const [a, b])])), const [DashboardMetric.cost(), DashboardMetric.meters()]);

      const other = Tracker(id: 't-2', name: 'Garten', fields: [b]);
      expect(DashboardFigures.shown(category([wasser(meters: const [a]), other])), const [
        DashboardMetric.cost(),
        DashboardMetric.field(trackerId: 't-wasser', fieldId: 'a'),
        DashboardMetric.field(trackerId: 't-2', fieldId: 'b'),
      ]);
    });

    test('zusammen zählen nur Zähler mit der Einheit des ersten', () {
      const gas = FieldDefinition(id: 'g', name: 'Gas', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', consumptionUnit: 'kWh');
      final c = category([wasser(meters: const [badKalt, gas])]);
      expect(DashboardFigures.metersOf(c, const DashboardMetric.meters()).map((m) => m.$2.id), ['bk']);
    });
  });

  group('Speichern', () {
    test('Gruppe und Summen überstehen JSON, Umzug ordnet Zähler neu zu', () {
      const dashboard = CategoryDashboard(
        metrics: [
          DashboardMetric.meters(),
          DashboardMetric.meters(group: 'Warmwasser'),
          DashboardMetric.meters(fieldIds: ['bk', 'bw'], label: 'Bad'),
        ],
      );
      expect(CategoryDashboard.fromJson(dashboard.toJson()), dashboard);
      final c = category([wasser()], dashboard: dashboard);
      expect(TrackingCodec.categoryFrom(TrackingCodec.category(c)), c);

      expect(dashboard.remap({}, {'bk': 'neu-bk'}).metrics, const [
        DashboardMetric.meters(),
        DashboardMetric.meters(group: 'Warmwasser'),
        DashboardMetric.meters(fieldIds: ['neu-bk'], label: 'Bad'),
      ]);
      expect(const DashboardMetric.meters(fieldIds: ['weg']).remap({}, {}), isNull);
    });
  });
}
