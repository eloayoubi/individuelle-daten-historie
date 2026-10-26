import 'categories_repository.dart';
import 'memory_categories_repository.dart';

/// Beispieldaten aus dem Design: ein Haushalt mit Verläufen von Januar 2024 bis Oktober 2026.
/// Miete und Auto sind mit „Anna“ geteilt; die Wasserkosten stecken in den Nebenkosten (gezeigt,
/// nicht doppelt gezählt), Gas rechnet Kubikmeter mit dem Brennwert in kWh um, Strom und Gas haben
/// Abschläge für den Abschlags-Check, das Auto eine Formel für den Verbrauch je 100 km.
///
/// Änderungen bleiben im Speicher, bis die App neu startet – genug, um alle Abläufe ohne Backend
/// zu bedienen. Im Mock-Modus steht er für die Cloud; Teilen nimmt den Code [demoInvite] an.
class MockCategoriesRepository extends MemoryCategoriesRepository {
  MockCategoriesRepository({List<Category>? seed}) : super(seed: seed ?? categories, ids: _mockIds());

  static String Function(String) _mockIds() {
    var seq = 0;
    return (kind) => 'mock-$kind-${seq++}';
  }

  /// Ein Code, den der Mock-Modus annimmt: legt eine von Anna geteilte Kategorie an.
  static const demoInvite = 'K7Q2M9X4TA';

  @override
  Future<String> createInvite(String categoryId, MemberRole role) async => demoInvite;

  @override
  Future<String> acceptInvite(String code) async {
    if (code.trim().toUpperCase() != demoInvite) throw const WriteRejected('invalid_invite');
    final existing = items.where((c) => c.id == 'c-ferien').firstOrNull;
    if (existing != null) return existing.id;
    const owner = CategoryMember(userId: '00000000-0000-4000-8000-000000000002', name: 'Anna', role: MemberRole.owner);
    items.add(
      Category(
        id: 'c-ferien',
        name: 'Ferienwohnung',
        icon: CategoryIcon.house,
        swatch: CategorySwatch.teal,
        myRole: MemberRole.viewer,
        sharedWith: const [owner],
        trackers: [
          Tracker(
            id: 't-ferien',
            name: 'Strom Ostsee',
            fields: const [FieldDefinition(id: 'f-ferien-stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh')],
            entries: _readings('e-ferien', 'f-ferien-stand', start: 8120, yearly: const {2024: 900, 2025: 880, 2026: 870}, season: _flat, until: _d(2026, 9, 3)),
          ),
        ],
      ),
    );
    changed();
    return 'c-ferien';
  }

  @override
  Future<void> setMemberRole(String categoryId, String userId, MemberRole role) async => updateCategoryWith(
    categoryId,
    (c) => _withMembers(c, [for (final m in c.sharedWith) m.userId == userId ? CategoryMember(userId: m.userId, name: m.name, role: role) : m]),
  );

  @override
  Future<void> removeMember(String categoryId, String userId) async =>
      updateCategoryWith(categoryId, (c) => _withMembers(c, [...c.sharedWith.where((m) => m.userId != userId)]));

  @override
  Future<void> leaveCategory(String categoryId) async {
    items.removeWhere((c) => c.id == categoryId);
    changed();
  }

  static Category _withMembers(Category c, List<CategoryMember> members) => Category(
    id: c.id,
    name: c.name,
    icon: c.icon,
    swatch: c.swatch,
    trackers: c.trackers,
    myRole: c.myRole,
    templateKey: c.templateKey,
    archivedAt: c.archivedAt,
    dashboard: c.dashboard,
    sharedWith: members,
  );

  static const anna = CategoryMember(userId: '00000000-0000-4000-8000-000000000002', name: 'Anna', role: MemberRole.editor);

  static final categories = <Category>[
    Category(id: 'c-strom', name: 'Strom', icon: CategoryIcon.bolt, swatch: CategorySwatch.orange, trackers: [_strom]),
    Category(id: 'c-heizung', name: 'Heizung', icon: CategoryIcon.flame, swatch: CategorySwatch.red, trackers: [_gas]),
    Category(id: 'c-wasser', name: 'Wasser', icon: CategoryIcon.drop, swatch: CategorySwatch.blue, trackers: [_wasser]),
    Category(id: 'c-miete', name: 'Miete & Nebenkosten', icon: CategoryIcon.house, swatch: CategorySwatch.brown, trackers: [_wohnung], sharedWith: const [anna]),
    Category(id: 'c-auto', name: 'Auto', icon: CategoryIcon.car, swatch: CategorySwatch.green, trackers: [_golf], sharedWith: const [anna]),
    Category(id: 'c-internet', name: 'Internet & Mobilfunk', icon: CategoryIcon.wifi, swatch: CategorySwatch.purple, trackers: [_glasfaser, _handy]),
    Category(id: 'c-versicherung', name: 'Versicherungen', icon: CategoryIcon.shield, swatch: CategorySwatch.teal, trackers: [_haftpflicht, _hausrat]),
    Category(id: 'c-abos', name: 'Abos & Mitgliedschaften', icon: CategoryIcon.play, swatch: CategorySwatch.pink, trackers: [_streaming, _fitness, _ticket]),
  ];

  static DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

  /// Monatliche Zählerstände; [yearly] je Jahr, [season] verteilt ihn auf die Monate.
  static List<Entry> _readings(String prefix, String field, {required double start, required Map<int, double> yearly, required List<double> season, required DateTime until, int everyMonths = 1, int day = 3}) {
    final total = season.fold(0.0, (a, b) => a + b);
    final entries = <Entry>[];
    var value = start;
    var i = 0;
    for (var date = _d(2024, 1, day); !date.isAfter(until); date = _d(date.year, date.month + everyMonths, day)) {
      entries.add(Entry(id: '$prefix-$i', date: date, values: {field: (value * 10).round() / 10}));
      for (var m = 0; m < everyMonths; m++) {
        final month = DateTime.utc(date.year, date.month + m);
        value += yearly[month.year]! * season[month.month - 1] / total;
      }
      i++;
    }
    return entries;
  }

  static const _flat = [1.1, 1.0, 1.0, 0.95, 0.9, 0.85, 0.85, 0.85, 0.9, 1.0, 1.1, 1.2];
  static const _heating = [2.2, 1.9, 1.6, 1.0, 0.5, 0.25, 0.2, 0.2, 0.45, 1.0, 1.6, 2.1];

  // Strom: Anbieterwechsel im April 2025, Vertragsende März 2027.
  static final _strom = Tracker(
    id: 't-strom',
    name: 'Hauptzähler',
    fields: const [
      FieldDefinition(id: 'f-strom-stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh'),
      FieldDefinition(id: 'f-strom-ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh'),
      FieldDefinition(id: 'f-strom-gp', name: 'Grundpreis', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat'),
      FieldDefinition(id: 'f-strom-abschlag', name: 'Abschlag', kind: FieldKind.currency, role: FieldRole.instalment, unit: '€/Monat'),
      FieldDefinition(id: 'f-strom-ende', name: 'Vertragsende', kind: FieldKind.date, role: FieldRole.deadline),
      FieldDefinition(id: 'f-strom-anbieter', name: 'Anbieter', kind: FieldKind.text),
    ],
    entries: [
      Entry(id: 'e-strom-p1', date: _d(2024, 1, 1), values: const {'f-strom-ap': 0.389, 'f-strom-gp': 14.20, 'f-strom-abschlag': 98}),
      Entry(id: 'e-strom-d1', date: _d(2024, 1, 1), values: const {'f-strom-anbieter': 'Stadtwerke'}),
      Entry(id: 'e-strom-p2', date: _d(2025, 4, 1), values: const {'f-strom-ap': 0.329, 'f-strom-gp': 11.90, 'f-strom-abschlag': 85}),
      Entry(id: 'e-strom-d2', date: _d(2025, 4, 1), values: {'f-strom-anbieter': 'Ökostrom Plus', 'f-strom-ende': _d(2027, 3, 31)}),
      ..._readings('e-strom', 'f-strom-stand', start: 41230, yearly: const {2024: 2550, 2025: 2410, 2026: 2280}, season: _flat, until: _d(2026, 9, 12), day: 12),
    ],
  );

  // Gas: Stand in m³, Verbrauch in kWh (Brennwert × Zustandszahl ≈ 10,35), alle zwei Monate abgelesen.
  static final _gas = Tracker(
    id: 't-gas',
    name: 'Gaszähler',
    fields: const [
      FieldDefinition(id: 'f-gas-stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³', consumptionUnit: 'kWh', factor: 10.35),
      FieldDefinition(id: 'f-gas-ap', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh'),
      FieldDefinition(id: 'f-gas-gp', name: 'Grundpreis', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat'),
      FieldDefinition(id: 'f-gas-abschlag', name: 'Abschlag', kind: FieldKind.currency, role: FieldRole.instalment, unit: '€/Monat'),
    ],
    entries: [
      Entry(id: 'e-gas-p1', date: _d(2024, 1, 1), values: const {'f-gas-ap': 0.121, 'f-gas-gp': 16.50, 'f-gas-abschlag': 105}),
      Entry(id: 'e-gas-p2', date: _d(2026, 1, 1), values: const {'f-gas-ap': 0.109}),
      ..._readings('e-gas', 'f-gas-stand', start: 18450, yearly: const {2024: 1120, 2025: 1065, 2026: 1010}, season: _heating, until: _d(2026, 10, 5), everyMonths: 2, day: 5),
    ],
  );

  // Wasser: mit Preis, aber die Kosten stecken schon in den Nebenkosten – gezeigt, nicht doppelt gezählt.
  static final _wasser = Tracker(
    id: 't-wasser',
    name: 'Kaltwasser',
    includedIn: 'c-miete',
    fields: const [
      FieldDefinition(id: 'f-wasser-stand', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³'),
      FieldDefinition(id: 'f-wasser-preis', name: 'Wasser & Abwasser', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/m³'),
    ],
    entries: [
      Entry(id: 'e-wasser-p1', date: _d(2024, 1, 1), values: const {'f-wasser-preis': 4.35}),
      Entry(id: 'e-wasser-p2', date: _d(2026, 1, 1), values: const {'f-wasser-preis': 4.62}),
      ..._readings('e-wasser', 'f-wasser-stand', start: 512.4, yearly: const {2024: 88, 2025: 84, 2026: 81}, season: _flat, until: _d(2026, 7, 1), everyMonths: 3, day: 1),
    ],
  );

  static final _wohnung = Tracker(
    id: 't-wohnung',
    name: 'Wohnung',
    fields: const [
      FieldDefinition(id: 'f-miete-kalt', name: 'Kaltmiete', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat'),
      FieldDefinition(id: 'f-miete-nk', name: 'Nebenkosten-Vorauszahlung', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat'),
      FieldDefinition(id: 'f-miete-abrechnung', name: 'Nachzahlung / Guthaben', kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€'),
    ],
    entries: [
      Entry(id: 'e-miete-1', date: _d(2024, 1, 1), values: const {'f-miete-kalt': 890, 'f-miete-nk': 210}),
      Entry(
        id: 'e-miete-2',
        date: _d(2025, 5, 20),
        values: const {'f-miete-abrechnung': 148},
        note: 'Nebenkostenabrechnung 2024',
        periodStart: _d(2024, 1, 1),
        periodEnd: _d(2024, 12, 31),
      ),
      Entry(id: 'e-miete-3', date: _d(2025, 7, 1), values: const {'f-miete-kalt': 920}, note: 'Mieterhöhung nach Mietspiegel'),
      Entry(id: 'e-miete-4', date: _d(2026, 1, 1), values: const {'f-miete-nk': 235}),
      Entry(
        id: 'e-miete-5',
        date: _d(2026, 5, 18),
        values: const {'f-miete-abrechnung': -62},
        note: 'Nebenkostenabrechnung 2025',
        periodStart: _d(2025, 1, 1),
        periodEnd: _d(2025, 12, 31),
      ),
    ],
  );

  // Auto: Kilometerstand und Tanken in einem Eintrag, alle drei Wochen.
  static final _golf = Tracker(
    id: 't-golf',
    name: 'Golf',
    fields: const [
      FieldDefinition(id: 'f-golf-km', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'km'),
      FieldDefinition(id: 'f-golf-tanken', name: 'Tanken', kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€'),
      FieldDefinition(id: 'f-golf-liter', name: 'Liter', kind: FieldKind.number, role: FieldRole.snapshot, unit: 'l'),
      FieldDefinition(
        id: 'f-golf-verbrauch',
        name: 'Verbrauch',
        kind: FieldKind.formula,
        role: FieldRole.snapshot,
        unit: 'l/100 km',
        formula: 'runden(liter / verbrauch * 100; 1)',
      ),
      FieldDefinition(id: 'f-golf-vers', name: 'Kfz-Versicherung', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Jahr', intervalMonths: 12),
      FieldDefinition(id: 'f-golf-steuer', name: 'Kfz-Steuer', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Jahr', intervalMonths: 12),
      FieldDefinition(id: 'f-golf-tuev', name: 'Hauptuntersuchung', kind: FieldKind.date, role: FieldRole.deadline),
    ],
    entries: [
      Entry(id: 'e-golf-p1', date: _d(2024, 1, 1), values: {'f-golf-vers': 612, 'f-golf-steuer': 128, 'f-golf-tuev': _d(2027, 2, 26)}),
      Entry(id: 'e-golf-p2', date: _d(2026, 1, 1), values: const {'f-golf-vers': 648}),
      for (var i = 0; i * 21 < 1010; i++)
        Entry(
          id: 'e-golf-$i',
          date: _d(2024, 1, 5).add(Duration(days: i * 21)),
          values: {'f-golf-km': 48200 + i * 690, 'f-golf-tanken': 58.0 + (i % 5) * 3.4, 'f-golf-liter': 34.5 + (i % 5) * 1.5},
        ),
    ],
  );

  /// [provider] landet wie über „Details“ gesetzt in einem eigenen Eintrag, [ends] (ältere Art) im
  /// letzten Preis-Eintrag.
  static Tracker _contract(String id, String name, List<(DateTime, double)> prices, {int intervalMonths = 1, DateTime? ends, String? provider}) => Tracker(
    id: 't-$id',
    name: name,
    fields: [
      FieldDefinition(id: 'f-$id-preis', name: 'Beitrag', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: intervalMonths == 12 ? '€/Jahr' : '€/Monat', intervalMonths: intervalMonths),
      if (provider != null) FieldDefinition(id: 'f-$id-anbieter', name: 'Anbieter', kind: FieldKind.text),
      if (ends != null) FieldDefinition(id: 'f-$id-ende', name: 'Vertragsende', kind: FieldKind.date, role: FieldRole.deadline),
    ],
    entries: [
      for (final (i, (date, price)) in prices.indexed)
        Entry(id: 'e-$id-$i', date: date, values: {'f-$id-preis': price, if (i == prices.length - 1 && ends != null) 'f-$id-ende': ends}),
      if (provider != null) Entry(id: 'e-$id-anbieter', date: prices.first.$1, values: {'f-$id-anbieter': provider}),
    ],
  );

  static final _glasfaser = _contract('glasfaser', 'Glasfaser 250', [(_d(2024, 1, 1), 39.99), (_d(2026, 2, 1), 44.99)], ends: _d(2026, 12, 31), provider: 'Telekom');
  static final _handy = _contract('handy', 'Handyvertrag', [(_d(2024, 1, 1), 14.99)], provider: 'congstar');
  static final _haftpflicht = _contract('haftpflicht', 'Privathaftpflicht', [(_d(2024, 1, 1), 68.40)], intervalMonths: 12);
  static final _hausrat = _contract('hausrat', 'Hausrat', [(_d(2024, 1, 1), 117.60), (_d(2026, 3, 1), 124.80)], intervalMonths: 12);
  static final _streaming = _contract('streaming', 'Streaming', [(_d(2024, 1, 1), 13.99), (_d(2025, 9, 1), 15.99)]);
  static final _fitness = _contract('fitness', 'Fitnessstudio', [(_d(2024, 1, 1), 29.90)]);
  static final _ticket = _contract('ticket', 'Deutschlandticket', [(_d(2024, 1, 1), 49), (_d(2025, 1, 1), 58), (_d(2026, 1, 1), 63)]);
}
