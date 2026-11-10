import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/features/radar/data/radar.dart';

void main() {
  final today = DateTime.utc(2026, 10, 22);

  const price = FieldDefinition(id: 'price', name: 'Preis', kind: FieldKind.currency, role: FieldRole.recurringCost, unit: '€/Monat');
  const cancelBy = FieldDefinition(id: 'cancel', name: 'Kündbar bis', kind: FieldKind.date, role: FieldRole.deadline);
  const reading = FieldDefinition(id: 'reading', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'kWh');
  const unitPrice = FieldDefinition(id: 'unit', name: 'Arbeitspreis', kind: FieldKind.currency, role: FieldRole.unitPrice, unit: '€/kWh');
  const instalment = FieldDefinition(id: 'instalment', name: 'Abschlag', kind: FieldKind.currency, role: FieldRole.instalment, unit: '€/Monat');

  var nextId = 0;
  Entry entry(DateTime date, Map<String, Object> values) => Entry(id: 'e${nextId++}', date: date, values: values);

  Category category(List<Tracker> trackers, {String id = 'c1', DateTime? archivedAt}) =>
      Category(id: id, name: 'Kategorie', icon: CategoryIcon.play, swatch: CategorySwatch.pink, trackers: trackers, archivedAt: archivedAt);

  List<Finding> findings(List<Tracker> trackers, {Set<String> dismissed = const {}}) => Radar.build([category(trackers)], today, dismissed: dismissed).findings;

  /// Stromzähler mit 10 kWh je Tag seit Anfang 2025, Stand zuletzt am 1.10.2026.
  Tracker meter({List<FieldDefinition> more = const [], List<Entry> entries = const []}) => Tracker(
    id: 'strom',
    name: 'Hauptzähler',
    fields: [reading, unitPrice, ...more],
    entries: [
      entry(DateTime.utc(2025), {'reading': 0, 'unit': 0.30}),
      entry(DateTime.utc(2026, 10), {'reading': 6380}),
      ...entries,
    ],
  );

  group('Preis', () {
    test('Abo ist in den letzten 90 Tagen teurer geworden: Mehrkosten im Jahr', () {
      final netflix = Tracker(
        id: 'netflix',
        name: 'Netflix',
        fields: const [price],
        entries: [
          entry(DateTime.utc(2026), {'price': 13.99}),
          entry(DateTime.utc(2026, 10), {'price': 17.99}),
        ],
      );
      final f = findings([netflix]).single;
      expect(f.kind, FindingKind.priceIncrease);
      expect(f.field, price);
      expect(f.before, 13.99);
      expect(f.after, 17.99);
      expect(f.date, DateTime.utc(2026, 10));
      expect(f.upcoming, isFalse);
      expect(f.amount, closeTo(48, 1e-6));
      expect(f.ratio, closeTo(4 / 13.99, 1e-9));
    });

    test('im Voraus eingetragene Erhöhung zählt, mit Intervall auf das Jahr gerechnet', () {
      const premium = FieldDefinition(id: 'premium', name: 'Beitrag', kind: FieldKind.currency, role: FieldRole.recurringCost, intervalMonths: 12);
      final police = Tracker(
        id: 'haftpflicht',
        name: 'Haftpflicht',
        fields: const [premium],
        entries: [
          entry(DateTime.utc(2025), {'premium': 80}),
          entry(DateTime.utc(2027), {'premium': 95}),
        ],
      );
      final f = findings([police]).single;
      expect(f.upcoming, isTrue);
      expect(f.date, DateTime.utc(2027));
      expect(f.amount, closeTo(15, 1e-6));
    });

    test('wiederkehrender Betrag mitten im Monat: Datum des Eintrags zählt für Frist und Anzeige', () {
      Tracker abo(DateTime changed) => Tracker(id: 'abo', name: 'Abo', fields: const [price], entries: [entry(DateTime.utc(2026), {'price': 10}), entry(changed, {'price': 20})]);
      // Vor 68 Tagen eingetragen, der Monatserste läge 82 Tage zurück – beides innerhalb von 90.
      final recent = findings([abo(DateTime.utc(2026, 8, 15))]).single;
      expect(recent.date, DateTime.utc(2026, 8, 15));
      expect(recent.upcoming, isFalse);
      // Vor 89 Tagen eingetragen: zählt noch, obwohl der Monatserste 113 Tage zurückliegt.
      expect(findings([abo(DateTime.utc(2026, 7, 25))]), hasLength(1));
      expect(findings([abo(DateTime.utc(2026, 7, 23))]), isEmpty);
      // Gilt erst in drei Tagen, die Kosten-Engine zählt es schon für den ganzen Monat.
      final soon = findings([abo(DateTime.utc(2026, 10, 25))]).single;
      expect(soon.date, DateTime.utc(2026, 10, 25));
      expect(soon.upcoming, isTrue);
      expect(soon.amount, closeTo(120, 1e-6));
    });

    test('korrigierter neuer Preis ist ein neuer Fund', () {
      Tracker abo(double after) => Tracker(id: 'abo', name: 'Abo', fields: const [price], entries: [entry(DateTime.utc(2026), {'price': 10}), entry(DateTime.utc(2026, 10), {'price': after})]);
      final first = findings([abo(12)]).single;
      expect(findings([abo(12)], dismissed: {first.id}), isEmpty);
      expect(findings([abo(15)], dismissed: {first.id}), hasLength(1));
    });

    test('alte Erhöhung, Senkung und Kleinstbeträge melden nichts', () {
      Tracker abo(String id, List<Entry> entries) => Tracker(id: id, name: id, fields: const [price], entries: entries);
      expect(
        findings([
          abo('alt', [entry(DateTime.utc(2025), {'price': 10}), entry(DateTime.utc(2026, 6), {'price': 15})]),
          abo('billiger', [entry(DateTime.utc(2026), {'price': 15}), entry(DateTime.utc(2026, 10), {'price': 10})]),
          abo('cent', [entry(DateTime.utc(2026), {'price': 10}), entry(DateTime.utc(2026, 10), {'price': 10.2})]),
          abo('neu', [entry(DateTime.utc(2026, 10), {'price': 10})]),
        ]),
        isEmpty,
      );
    });

    test('Teilbeträge und Abschläge sind keine Preiserhöhung', () {
      const part = FieldDefinition(id: 'kalt', name: 'Kaltmiete', kind: FieldKind.currency, role: FieldRole.recurringCost, partOf: 'price');
      final wohnung = Tracker(
        id: 'wohnung',
        name: 'Wohnung',
        fields: const [price, part],
        entries: [
          entry(DateTime.utc(2026), {'price': 900, 'kalt': 600}),
          entry(DateTime.utc(2026, 10), {'price': 900, 'kalt': 650}),
        ],
      );
      expect(findings([wohnung]), isEmpty);
      // Ein erhöhter Abschlag ist eine Vorauszahlung, kein Preis.
      final strom = meter(more: const [instalment], entries: [entry(DateTime.utc(2026), {'instalment': 92}), entry(DateTime.utc(2026, 10), {'instalment': 93})]);
      expect(findings([strom]), isEmpty);
    });

    test('Arbeitspreis: Differenz mal erwarteter Verbrauch der nächsten 365 Tage', () {
      final f = findings([meter(entries: [entry(DateTime.utc(2026, 10, 15), {'unit': 0.35})])]).single;
      expect(f.kind, FindingKind.priceIncrease);
      expect(f.field, unitPrice);
      expect(f.amount, closeTo(0.05 * 3650, 1e-6));
    });

    test('Arbeitspreis ohne bekannten Verbrauch meldet nichts', () {
      final ohne = Tracker(
        id: 'gas',
        name: 'Gas',
        fields: const [reading, unitPrice],
        entries: [entry(DateTime.utc(2026), {'unit': 0.1}), entry(DateTime.utc(2026, 10), {'unit': 0.2})],
      );
      expect(findings([ohne]), isEmpty);
    });

    test('Kosten, die in einer anderen Kategorie stecken, melden keinen Preis', () {
      final abo = Tracker(
        id: 'abo',
        name: 'Abo',
        fields: const [price],
        includedIn: 'c2',
        entries: [entry(DateTime.utc(2026), {'price': 10}), entry(DateTime.utc(2026, 10), {'price': 20})],
      );
      final radar = Radar.build([category([abo]), category(const [], id: 'c2')], today);
      expect(radar.findings, isEmpty);
      // Fehlt die andere Kategorie, zählen die Kosten hier – dann auch der Fund.
      expect(Radar.build([category([abo])], today).findings, hasLength(1));
    });
  });

  group('Frist', () {
    Tracker abo({required DateTime due, String id = 'netflix'}) => Tracker(
      id: id,
      name: 'Netflix',
      fields: const [price, cancelBy],
      entries: [
        entry(DateTime.utc(2025), {'price': 17.99}),
        entry(DateTime.utc(2025), {'cancel': due}),
      ],
    );

    test('Stichtag eines Vertrags in 19 Tagen: es geht um die Kosten der nächsten 12 Monate', () {
      final f = findings([abo(due: DateTime.utc(2026, 11, 10))]).single;
      expect(f.kind, FindingKind.deadline);
      expect(f.field, cancelBy);
      expect(f.days, 19);
      expect(f.date, DateTime.utc(2026, 11, 10));
      expect(f.amount, closeTo(12 * 17.99, 1e-6));
    });

    test('heute zählt noch, gestern und in 46 Tagen nicht', () {
      expect(findings([abo(due: today)]).single.days, 0);
      expect(findings([abo(due: today.subtract(const Duration(days: 1)))]), isEmpty);
      expect(findings([abo(due: today.add(const Duration(days: 46)))]), isEmpty);
      expect(findings([abo(due: today.add(const Duration(days: 45)))]), hasLength(1));
    });

    test('Auto mit Kilometerstand und Hauptuntersuchung ist kein Vertrag', () {
      const km = FieldDefinition(id: 'km', name: 'Kilometerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'km');
      const hu = FieldDefinition(id: 'hu', name: 'Hauptuntersuchung', kind: FieldKind.date, role: FieldRole.deadline);
      final auto = Tracker(
        id: 'auto',
        name: 'Golf',
        fields: const [km, price, hu],
        entries: [entry(DateTime.utc(2025), {'km': 1000, 'price': 50}), entry(DateTime.utc(2025), {'hu': DateTime.utc(2026, 11)})],
      );
      expect(findings([auto]), isEmpty);
    });

    test('ohne Kosten steht nichts auf dem Spiel', () {
      final leer = Tracker(id: 'x', name: 'X', fields: const [price, cancelBy], entries: [entry(DateTime.utc(2025), {'cancel': DateTime.utc(2026, 11)})]);
      expect(findings([leer]), isEmpty);
    });
  });

  group('Abschlag', () {
    test('zu niedriger Abschlag: Nachzahlung und passender Abschlag', () {
      final f = findings([meter(more: const [instalment], entries: [entry(DateTime.utc(2026), {'instalment': 70})])]).single;
      expect(f.kind, FindingKind.backPayment);
      expect(f.paid, closeTo(840, 1e-6));
      expect(f.cost, closeTo(1095, 1e-6));
      expect(f.amount, closeTo(255, 1e-6));
      expect(f.monthly, 70);
      expect(f.suggested, 92);
    });

    test('zu hoher Abschlag: Guthaben', () {
      final f = findings([meter(more: const [instalment], entries: [entry(DateTime.utc(2026), {'instalment': 120})])]).single;
      expect(f.kind, FindingKind.refund);
      expect(f.amount, closeTo(345, 1e-6));
      expect(f.suggested, 92);
    });

    test('passt der Abschlag ungefähr, meldet das Radar nichts', () {
      expect(findings([meter(more: const [instalment], entries: [entry(DateTime.utc(2026), {'instalment': 92})])]), isEmpty);
    });

    test('erster Abschlag mitten im Monat: Abschläge und Kosten ab demselben Monatsersten', () {
      // 92 Tage Oktober bis Dezember zu 3 € sind 276 € – genau drei Abschläge zu 92 €.
      expect(findings([meter(more: const [instalment], entries: [entry(DateTime.utc(2026, 10, 15), {'instalment': 92})])]), isEmpty);
    });

    test('Versorgungszähler ohne bekannten Verbrauch: kein falsches Guthaben', () {
      final neu = Tracker(
        id: 'neu',
        name: 'Neu',
        fields: const [reading, unitPrice, instalment],
        entries: [entry(DateTime.utc(2026), {'reading': 0, 'unit': 0.3, 'instalment': 90})],
      );
      expect(findings([neu]), isEmpty);
    });
  });

  group('Verbrauch', () {
    /// 10 kWh je Tag bis 22.7.2026, danach [recent] je Tag bis zum letzten Stand am 20.10.2026.
    Tracker usage(double recent, {DateTime? first}) {
      final start = first ?? DateTime.utc(2025, 7);
      final turn = DateTime.utc(2026, 7, 22), last = DateTime.utc(2026, 10, 20);
      final atTurn = 10.0 * turn.difference(start).inDays;
      return Tracker(
        id: 'strom',
        name: 'Hauptzähler',
        fields: const [reading, unitPrice],
        entries: [
          entry(start, {'reading': 0, 'unit': 0.30}),
          entry(DateTime.utc(2025, 10, 20), {'reading': 10.0 * DateTime.utc(2025, 10, 20).difference(start).inDays}),
          entry(turn, {'reading': atTurn}),
          entry(last, {'reading': atTurn + recent * last.difference(turn).inDays}),
        ],
      );
    }

    test('letzte 90 Tage gegen dieselben im Vorjahr, Mehrkosten zum aktuellen Preis', () {
      final f = findings([usage(13)]).single;
      expect(f.kind, FindingKind.usageUp);
      expect(f.field, reading);
      expect(f.date, DateTime.utc(2026, 10, 20));
      expect(f.before, closeTo(900, 1e-6));
      expect(f.after, closeTo(1170, 1e-6));
      expect(f.ratio, closeTo(0.3, 1e-9));
      expect(f.amount, closeTo(81, 1e-6));
    });

    test('unter 10 % mehr oder weniger Verbrauch: nichts', () {
      expect(findings([usage(10.5)]), isEmpty);
      expect(findings([usage(8)]), isEmpty);
    });

    test('zu kurzer Verlauf fürs Vorjahr: nichts', () {
      expect(findings([usage(13, first: DateTime.utc(2025, 9))]), isEmpty);
    });

    test('nur einmal im Jahr abgelesen: nichts – 90 Tage daraus wären nur der Jahresschnitt', () {
      final yearly = Tracker(
        id: 'strom',
        name: 'Hauptzähler',
        fields: const [reading, unitPrice],
        entries: [
          entry(DateTime.utc(2024, 10, 20), {'reading': 0, 'unit': 0.30}),
          entry(DateTime.utc(2025, 10, 20), {'reading': 3650}),
          entry(DateTime.utc(2026, 10, 20), {'reading': 3650 + 4745}),
        ],
      );
      expect(findings([yearly]), isEmpty);
    });

    test('Verbrauch aus Rechnungen: nichts', () {
      final billed = usage(13);
      final bill = Entry(id: 'bill', date: DateTime.utc(2026, 10, 20), periodStart: DateTime.utc(2026, 7, 22), periodEnd: DateTime.utc(2026, 10, 19), values: const {'reading': 1170});
      expect(findings([billed.copyWith(entries: [...billed.entries, bill])]), isEmpty);
    });

    test('Zähler mit verschiedenen Einheiten werden nicht zusammengezählt', () {
      const gas = FieldDefinition(id: 'gas', name: 'Gas', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'm³');
      final mixed = usage(13);
      expect(findings([mixed.copyWith(fields: [...mixed.fields, gas])]), isEmpty);
    });

    test('ausgeblendet bleibt der Fund auch nach dem nächsten Stand im selben Quartal', () {
      final first = findings([usage(13)]).single;
      final later = usage(13);
      final more = later.copyWith(entries: [...later.entries, entry(DateTime.utc(2026, 10, 21), {'reading': (later.entries.last.values['reading']! as num) + 13})]);
      expect(findings([more]).single.id, first.id);
    });

    test('letzter Stand älter als 45 Tage: nichts – der Rest wäre Hochrechnung', () {
      final alt = Radar.build([category([usage(13)])], DateTime.utc(2026, 12, 10)).findings;
      expect(alt.where((f) => f.kind == FindingKind.usageUp), isEmpty);
    });
  });

  group('Liste', () {
    final netflix = Tracker(
      id: 'netflix',
      name: 'Netflix',
      fields: const [price, cancelBy],
      entries: [
        entry(DateTime.utc(2026), {'price': 13.99}),
        entry(DateTime.utc(2026, 10), {'price': 17.99}),
        entry(DateTime.utc(2026), {'cancel': DateTime.utc(2026, 11, 20)}),
      ],
    );
    final spotify = Tracker(
      id: 'spotify',
      name: 'Spotify',
      fields: const [price, cancelBy],
      entries: [
        entry(DateTime.utc(2026), {'price': 10}),
        entry(DateTime.utc(2026, 10), {'price': 20}),
        entry(DateTime.utc(2026), {'cancel': DateTime.utc(2026, 11)}),
      ],
    );

    test('Fristen zuerst nach Nähe, danach nach Betrag', () {
      final all = findings([netflix, spotify]);
      expect([for (final f in all) (f.kind, f.tracker.id)], [
        (FindingKind.deadline, 'spotify'),
        (FindingKind.deadline, 'netflix'),
        (FindingKind.priceIncrease, 'spotify'),
        (FindingKind.priceIncrease, 'netflix'),
      ]);
      expect({for (final f in all) f.id}, hasLength(4));
    });

    test('ausgeblendete Funde fehlen, bis sich die Lage ändert', () {
      final all = findings([netflix]);
      final hidden = findings([netflix], dismissed: {all.first.id});
      expect(hidden, [all.last]);
      // Neuer Stichtag: neuer Fund trotz ausgeblendetem alten.
      final moved = netflix.copyWith(entries: [...netflix.entries, entry(DateTime.utc(2026, 2), {'cancel': DateTime.utc(2026, 11, 25)})]);
      expect(findings([moved], dismissed: {all.first.id}).first.kind, FindingKind.deadline);
    });

    test('kaputte Werte (unendlich, riesig, negativ) ergeben keinen Fund und keinen Absturz', () {
      Tracker abo(String id, num before, num after) =>
          Tracker(id: id, name: id, fields: const [price, cancelBy], entries: [entry(DateTime.utc(2026), {'price': before, 'cancel': DateTime.utc(2026, 11)}), entry(DateTime.utc(2026, 10), {'price': after})]);
      expect(
        findings([
          abo('unendlich', 10, double.infinity),
          abo('nan', 10, double.nan),
          abo('riesig', 10, 1e300),
          abo('gutschrift', -5, 10),
          meter(more: const [instalment], entries: [entry(DateTime.utc(2026), {'instalment': double.infinity})]),
          meter(more: const [instalment], entries: [entry(DateTime.utc(2026), {'instalment': 1e300})]),
        ]).where((f) => f.kind != FindingKind.deadline),
        isEmpty,
      );
    });

    test('archivierte Kategorien melden nichts', () {
      expect(Radar.build([category([netflix], archivedAt: today)], today).findings, isEmpty);
    });
  });
}
