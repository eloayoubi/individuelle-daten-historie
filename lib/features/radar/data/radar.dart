import 'package:equatable/equatable.dart';

import '../../../core/models/tracking.dart';
import '../../../core/utils/cost_engine.dart';
import '../../insights/data/insights.dart';

enum FindingKind {
  /// Stichtag eines Vertrags rückt näher (Vertragsende, Kündbar bis).
  deadline,

  /// Preis oder wiederkehrender Betrag ist gestiegen oder steigt.
  priceIncrease,

  /// Verbrauch liegt merklich über dem Vorjahr.
  usageUp,

  /// Abschläge decken die Kosten des Jahres nicht.
  backPayment,

  /// Abschläge liegen über den Kosten des Jahres.
  refund,
}

/// Ein Fund des Radars: etwas, das Geld kostet oder spart und das man sonst erst später merkt.
class Finding extends Equatable {
  const Finding({
    required this.id,
    required this.kind,
    required this.category,
    required this.tracker,
    required this.amount,
    this.field,
    this.date,
    this.days,
    this.ratio,
    this.before,
    this.after,
    this.upcoming = false,
    this.monthly,
    this.suggested,
    this.paid,
    this.cost,
  });

  /// Kennung für „Ausblenden“. Ändert sich die Lage (neuer Stichtag, neuer Preis, anderer Abschlag),
  /// ändert sie sich mit – der Fund erscheint dann wieder. Enthält nur Ids und ein Datum.
  final String id;
  final FindingKind kind;
  final Category category;
  final Tracker tracker;

  /// Betrag in Euro, um den es geht: Kosten der nächsten 12 Monate ([FindingKind.deadline]),
  /// Mehrkosten im Jahr ([FindingKind.priceIncrease]), Mehrkosten im Vergleichszeitraum
  /// ([FindingKind.usageUp]), Nachzahlung bzw. Guthaben bis Jahresende.
  final double amount;

  /// Stichtag, Preis oder Zähler, um den es geht; `null` beim Abschlag.
  final FieldDefinition? field;

  /// Stichtag, „gilt ab“ des neuen Preises, Ende des Vergleichszeitraums beim Verbrauch bzw. der
  /// 31. Dezember des Jahres, für das der Abschlag gerechnet ist.
  final DateTime? date;

  /// Tage bis zum Stichtag.
  final int? days;

  /// Veränderung als Anteil (0,3 = +30 %); `null`, wenn der alte Wert 0 war.
  final double? ratio;

  /// Alter und neuer Preis (in der Einheit des Felds) bzw. Verbrauch im Vorjahr und jetzt.
  final double? before;
  final double? after;

  /// Der neue Preis gilt erst ab [date].
  final bool upcoming;

  /// Abschlag: aktuell je Monat, passend je Monat, gezahlt und gerechnete Kosten im Jahr.
  final double? monthly;
  final double? suggested;
  final double? paid;
  final double? cost;

  @override
  List<Object?> get props => [id, kind, category, tracker, amount, field, date, days, ratio, before, after, upcoming, monthly, suggested, paid, cost];
}

/// Preis oder Betrag: zählt ab [from] (bei wiederkehrenden Beträgen der Monatserste), eingetragen
/// für den Tag [date].
typedef _Step = ({DateTime from, DateTime date, double value});

/// Sucht in den Kategorien nach dem, was Geld kostet, bevor es jemand merkt – gerechnet auf dem
/// Gerät mit der [CostEngine]. Regeln: docs/superpowers/specs/2026-11-10-kosten-radar-design.md.
class Radar extends Equatable {
  const Radar({required this.today, this.findings = const []});

  /// So weit im Voraus meldet das Radar Stichtage von Verträgen.
  static const deadlineWithinDays = 45;

  /// So lange bleibt eine schon geltende Preiserhöhung ein Fund.
  static const priceSinceDays = 90;

  /// Verbrauch: Vergleichszeitraum, höchstes Alter des letzten bekannten Tags, kleinste Steigerung.
  static const usageWindowDays = 90;
  static const usageFreshDays = 45;

  /// So nah an Anfang und Ende der Vergleichszeiträume muss ein Zählerstand liegen.
  static const usageReadingDays = 45;
  static const usageMinRatio = 0.1;

  /// Kleinere Mehrkosten sind kein Fund; bei Stichtagen muss überhaupt etwas auf dem Spiel stehen.
  static const minAmount = 5.0;
  static const minStake = 1.0;
  static const priceMinRatio = 0.01;

  /// Abschlag: erst ab diesem Betrag und diesem Anteil an den Kosten.
  static const instalmentMinAmount = 25.0;
  static const instalmentMinShare = 0.05;

  final DateTime today;

  /// Stichtage nach Nähe, danach alles andere nach Betrag absteigend.
  final List<Finding> findings;

  bool get isEmpty => findings.isEmpty;

  factory Radar.build(List<Category> categories, DateTime now, {Set<String> dismissed = const {}}) {
    final today = CostEngine.day(now);
    final active = [for (final c in categories) if (!c.isArchived) c];
    final ids = {for (final c in active) c.id};
    final findings = <Finding>[];
    for (final category in active) {
      for (final tracker in category.trackers) {
        final engine = CostEngine(tracker, today: today);
        findings.addAll(_deadlines(category, tracker, engine, today));
        // Kosten, die schon in einer anderen Kategorie stecken, sind nur rechnerisch – dort gäbe es
        // nichts zu sparen. Fehlt diese Kategorie, zählen sie hier (wie in der Übersicht).
        if (tracker.includedIn != null && tracker.includedIn != category.id && ids.contains(tracker.includedIn)) continue;
        findings.addAll(_prices(category, tracker, engine, today));
        findings.addAll([?_usage(category, tracker, engine, today), ?_instalment(category, tracker, engine, today)]);
      }
    }
    findings
      ..removeWhere((f) => dismissed.contains(f.id))
      ..sort(_order);
    return Radar(today: today, findings: findings);
  }

  static int _order(Finding a, Finding b) {
    final aDue = a.kind == FindingKind.deadline, bDue = b.kind == FindingKind.deadline;
    if (aDue != bDue) return aDue ? -1 : 1;
    final byValue = aDue ? a.days!.compareTo(b.days!) : b.amount.compareTo(a.amount);
    return byValue != 0 ? byValue : a.id.compareTo(b.id);
  }

  static String _iso(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Beträge jenseits davon (oder nicht endlich) stammen aus kaputten Einträgen, nicht aus einem
  /// Haushalt – daraus wird kein Fund.
  static const maxAmount = 1e7;

  static bool _plausible(double value) => value.isFinite && value.abs() <= maxAmount;

  /// Vertrag: etwas mit laufenden Kosten, das man kündigen kann – wiederkehrender Betrag oder
  /// Arbeitspreis. Ein reiner Zähler ohne Arbeitspreis (Auto mit Kilometerstand) ist keiner; sein
  /// Stichtag (Hauptuntersuchung) bleibt eine Erinnerung.
  static bool _isContract(Tracker tracker) =>
      (tracker.meter == null || tracker.isUtilityMeter) &&
      tracker.fields.any((f) => (f.role == FieldRole.recurringCost || f.role == FieldRole.unitPrice) && !tracker.isPart(f));

  static Iterable<Finding> _deadlines(Category category, Tracker tracker, CostEngine engine, DateTime today) sync* {
    if (!_isContract(tracker)) return;
    final tomorrow = today.add(const Duration(days: 1));
    double? stake;
    for (final field in tracker.withRole(FieldRole.deadline)) {
      final value = tracker.detailValue(field.id);
      if (value is! DateTime) continue;
      final due = CostEngine.day(value);
      final days = due.difference(today).inDays;
      if (days < 0 || days > deadlineWithinDays) continue;
      stake ??= engine.cost(tomorrow, tomorrow.add(const Duration(days: 365)));
      if (stake < minStake || !_plausible(stake)) return;
      yield Finding(
        id: 'deadline:${tracker.id}:${field.id}:${_iso(due)}',
        kind: FindingKind.deadline,
        category: category,
        tracker: tracker,
        field: field,
        amount: stake,
        date: due,
        days: days,
      );
    }
  }

  static Iterable<Finding> _prices(Category category, Tracker tracker, CostEngine engine, DateTime today) sync* {
    final since = today.subtract(const Duration(days: priceSinceDays));
    final tomorrow = today.add(const Duration(days: 1));
    double? usage;
    for (final field in tracker.fields) {
      final recurring = field.role == FieldRole.recurringCost;
      if (!recurring && field.role != FieldRole.unitPrice) continue;
      // Teilbeträge stecken im Gesamtbetrag, Formeln rechnet die App aus anderen Feldern.
      if (field.kind == FieldKind.formula || tracker.isPart(field)) continue;
      final steps = _steps(tracker, field, byMonth: recurring);
      final current = steps.lastIndexWhere((s) => !s.from.isAfter(today));
      if (current < 0) continue;
      final _Step old, next;
      if (current + 1 < steps.length && steps[current + 1].value > steps[current].value) {
        // Im Voraus eingetragen: die nächste Änderung.
        (old, next) = (steps[current], steps[current + 1]);
      } else if (current > 0 && steps[current].value > steps[current - 1].value && !steps[current].date.isBefore(since)) {
        (old, next) = (steps[current - 1], steps[current]);
      } else {
        continue;
      }
      // Negative Beträge sind Gutschriften, kein Preis.
      if (old.value < 0) continue;
      final difference = next.value - old.value;
      final ratio = old.value > 0 ? difference / old.value : null;
      if (ratio != null && (ratio < priceMinRatio || !ratio.isFinite)) continue;
      final double amount;
      if (recurring) {
        amount = difference / (field.intervalMonths < 1 ? 1 : field.intervalMonths) * 12;
      } else {
        // Ohne bekannten Verbrauch lässt sich ein Arbeitspreis nicht in Euro umrechnen.
        if (!engine.hasMeter) continue;
        usage ??= engine.consumption(tomorrow, tomorrow.add(const Duration(days: 365)));
        amount = difference * usage;
      }
      if (!_plausible(amount) || amount < minAmount) continue;
      yield Finding(
        // Mit dem neuen Wert (in Cent bzw. Zehntel-Cent): Wird er korrigiert, ist es ein neuer Fund.
        id: 'price:${tracker.id}:${field.id}:${_iso(next.date)}:${(next.value * 1000).round()}',
        kind: FindingKind.priceIncrease,
        category: category,
        tracker: tracker,
        field: field,
        amount: amount,
        date: next.date,
        ratio: ratio,
        before: old.value,
        after: next.value,
        // Ein wiederkehrender Betrag zählt schon ab dem Monatsersten, gilt aber erst ab seinem Tag.
        upcoming: next.date.isAfter(today),
      );
    }
  }

  /// Werte von [field] in zeitlicher Folge, je Tag einer – mit [byMonth] je Monat, ab dessen Erstem:
  /// So zählt die [CostEngine] wiederkehrende Beträge. Mehrere Werte am selben Tag bzw. im selben
  /// Monat: der späteste gilt.
  static List<_Step> _steps(Tracker tracker, FieldDefinition field, {required bool byMonth}) {
    final latest = <DateTime, (DateTime, double)>{};
    for (final e in tracker.entries) {
      final value = e.number(field.id)?.toDouble();
      if (value == null || !value.isFinite) continue;
      final date = CostEngine.day(e.date);
      final from = byMonth ? DateTime.utc(date.year, date.month) : date;
      if (latest[from] case (final DateTime known, _) when known.isAfter(date)) continue;
      latest[from] = (date, value);
    }
    return [for (final MapEntry(:key, :value) in latest.entries) (from: key, date: value.$1, value: value.$2)]..sort((a, b) => a.from.compareTo(b.from));
  }

  /// Hat jeder Zähler mit bekanntem Verbrauch einen Stand höchstens [usageReadingDays] Tage um [date]?
  /// Sonst wäre der Verbrauch dort nur zwischen weit entfernten Ständen gemittelt.
  static bool _readNear(Tracker tracker, CostEngine engine, DateTime date) {
    for (final meter in tracker.meters) {
      if (!engine.measuresField(meter.id)) continue;
      final near = tracker.entries.any(
        (e) => tracker.isReading(e) && e.values.containsKey(meter.id) && CostEngine.day(e.date).difference(date).inDays.abs() <= usageReadingDays,
      );
      if (!near) return false;
    }
    return true;
  }

  static Finding? _usage(Category category, Tracker tracker, CostEngine engine, DateTime today) {
    final meter = tracker.meter, from = engine.measuredFrom;
    var until = engine.measuredUntil;
    if (meter == null || from == null || until == null) return null;
    // Rechnungen verteilen ihren Verbrauch gleichmäßig auf den Zeitraum – 90 Tage daraus sagen nichts
    // über die letzten 90 Tage. Zähler mit verschiedenen Einheiten lassen sich nicht zusammenzählen.
    if (tracker.entries.any(tracker.isBill) || tracker.meters.any((m) => m.usageUnit != meter.usageUnit)) return null;
    // Ein vorausdatierter Stand zählt nur bis heute.
    final tomorrow = today.add(const Duration(days: 1));
    if (until.isAfter(tomorrow)) until = tomorrow;
    // Liegt der letzte bekannte Tag zu weit zurück, wäre der Vergleich eine Hochrechnung gegen sich selbst.
    if (today.difference(until).inDays > usageFreshDays) return null;
    final start = until.subtract(const Duration(days: usageWindowDays));
    final lastYearStart = start.subtract(const Duration(days: 365)), lastYearEnd = until.subtract(const Duration(days: 365));
    if (from.isAfter(lastYearStart)) return null;
    // Beide Zeiträume müssen an ihren Rändern abgelesen sein, nicht nur übers Jahr gemittelt.
    if (![start, lastYearStart, lastYearEnd].every((edge) => _readNear(tracker, engine, edge))) return null;
    final before = engine.consumption(lastYearStart, lastYearEnd), after = engine.consumption(start, until);
    if (before <= 0) return null;
    final ratio = after / before - 1;
    if (!ratio.isFinite || ratio < usageMinRatio) return null;
    final amount = (after - before) * engine.unitPriceOn(today);
    if (!_plausible(amount) || amount < minAmount) return null;
    return Finding(
      // Je Quartal: Ein ausgeblendeter Fund kommt nicht mit jedem neuen Stand zurück.
      id: 'usage:${tracker.id}:${until.year}-Q${(until.month + 2) ~/ 3}',
      kind: FindingKind.usageUp,
      category: category,
      tracker: tracker,
      field: meter,
      amount: amount,
      date: until,
      ratio: ratio,
      before: before,
      after: after,
    );
  }

  /// Wie der Abschlags-Check der Auswertung fürs laufende Jahr ([InstalmentCheck]): gezahlte Abschläge
  /// ab dem ersten Abschlag gegen die gerechneten Kosten bis Dezember.
  static Finding? _instalment(Category category, Tracker tracker, CostEngine engine, DateTime today) {
    final since = engine.instalmentSince;
    final yearStart = DateTime.utc(today.year), yearEnd = DateTime.utc(today.year + 1);
    if (since == null || !since.isBefore(yearEnd)) return null;
    // Zähler mit Arbeitspreis, aber noch ohne Verbrauch: Die Kosten wären nur der Grundpreis – das
    // sähe nach einem großen Guthaben aus.
    if (tracker.isUtilityMeter && !engine.hasMeter) return null;
    final from = since.isAfter(yearStart) ? since : yearStart;
    final months = Insights.monthStarts(from, yearEnd);
    final paid = engine.paid(from, yearEnd), cost = engine.cost(from, yearEnd);
    final monthly = engine.instalmentOn(today);
    if (months < 1 || paid <= 0 || cost <= 0 || !_plausible(paid) || !_plausible(cost) || !_plausible(monthly)) return null;
    final balance = paid - cost;
    if (balance.abs() < instalmentMinAmount || balance.abs() < cost * instalmentMinShare) return null;
    final kind = balance < 0 ? FindingKind.backPayment : FindingKind.refund;
    return Finding(
      id: 'instalment:${kind.name}:${tracker.id}:${today.year}:${monthly.round()}',
      kind: kind,
      category: category,
      tracker: tracker,
      amount: balance.abs(),
      date: DateTime.utc(today.year, 12, 31),
      monthly: monthly,
      suggested: (cost / months).ceilToDouble(),
      paid: paid,
      cost: cost,
    );
  }

  @override
  List<Object?> get props => [today, findings];
}
