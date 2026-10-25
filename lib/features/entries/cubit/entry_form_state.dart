part of 'entry_form_cubit.dart';

enum EntryFormEventKind { saved, savedOffline, deleted, failed }

/// Was das Formular erfasst. Versorgungszähler ([Tracker.isUtilityMeter]) kennen Rechnung,
/// Zählerstand und Vertrag; alle anderen Tracker haben das eine Formular mit allen Feldern.
enum EntryFormMode {
  /// Alle Felder mit Verlauf (Auto, Miete, Abos …).
  standard,

  /// Rechnung: Zeitraum und Verbrauch darin.
  bill,

  /// Zählerstand an einem Tag, ohne Preise.
  reading,

  /// Preisänderung: nur Preise und Beträge, gültig ab dem Datum.
  contract,
}

/// Einmaliges Ereignis für Toast und Zurück. Bewusst nicht `const`.
class EntryFormEvent {
  EntryFormEvent(this.kind);

  final EntryFormEventKind kind;
}

class EntryFormState extends Equatable {
  const EntryFormState({
    required this.tracker,
    required this.entryId,
    required this.isNew,
    required this.date,
    required this.decimalSeparator,
    required this.today,
    this.mode = EntryFormMode.standard,
    this.inputs = const {},
    this.originalValues = const {},
    this.note = '',
    this.meterChange = false,
    this.periodStart,
    this.periodEnd,
    this.saving = false,
    this.event,
  });

  factory EntryFormState.initial(EntryFormArgs args, DateTime now) {
    final entry = args.entry;
    final tracker = args.tracker;
    final mode = _modeFor(tracker, entry, contract: args.contract);
    final period = entry == null && mode == EntryFormMode.bill ? billPeriod(tracker, now) : null;
    return EntryFormState(
      tracker: tracker,
      entryId: entry?.id ?? newId(),
      isNew: entry == null,
      date: CostEngine.day(entry?.date ?? (mode == EntryFormMode.contract ? _firstContractDay(tracker, now) : now)),
      decimalSeparator: args.decimalSeparator,
      today: CostEngine.day(now),
      mode: mode,
      note: entry?.note ?? '',
      meterChange: entry?.meterChange ?? false,
      periodStart: period?.start ?? entry?.periodStart,
      periodEnd: period?.end ?? entry?.periodEnd,
      originalValues: entry?.values ?? const {},
      inputs: {
        for (final MapEntry(:key, :value) in (entry?.values ?? const <String, Object>{}).entries)
          key: value is num ? formatNumberInput(value, decimalSeparator: args.decimalSeparator) : value,
      },
    );
  }

  /// Vorhandener Eintrag: nach seiner Art. Neu: wie zuletzt erfasst, ohne Zählereintrag die Rechnung.
  static EntryFormMode _modeFor(Tracker tracker, Entry? entry, {required bool contract}) {
    if (!tracker.isUtilityMeter) return EntryFormMode.standard;
    if (entry == null) {
      if (contract) return EntryFormMode.contract;
      final meter = tracker.meter!;
      final hasMeterEntry = tracker.entries.any((e) => e.values.containsKey(meter.id));
      return !hasMeterEntry || tracker.readsFromBills ? EntryFormMode.bill : EntryFormMode.reading;
    }
    // Aus dem Preisverlauf: immer die Preise bearbeiten, auch wenn der Eintrag noch einen Stand trägt.
    if (contract || tracker.isPriceChange(entry)) return EntryFormMode.contract;
    if (tracker.isBill(entry)) return EntryFormMode.bill;
    return EntryFormMode.reading;
  }

  /// Der erste Vertrag gilt ab dem ersten bekannten Verbrauch, damit Grundpreis und Abschlag auch
  /// für schon eingetragene Rechnungen und Stände zählen. Gibt es schon Preise: ab heute.
  static DateTime _firstContractDay(Tracker tracker, DateTime now) {
    final rates = {for (final f in tracker.rateFields) f.id};
    if (tracker.entries.any((e) => e.values.keys.any(rates.contains))) return now;
    var first = now;
    for (final e in tracker.entries) {
      final start = tracker.isBill(e) ? e.periodStart! : (tracker.isReading(e) ? e.date : null);
      if (start != null && start.isBefore(first)) first = start;
    }
    return first;
  }

  /// Vorbelegung einer neuen Rechnung: ab dem Tag nach der letzten Rechnung, ohne Rechnung die
  /// letzten sechs Monate; bis heute.
  static ({DateTime start, DateTime end}) billPeriod(Tracker tracker, DateTime now) {
    final today = CostEngine.day(now);
    DateTime? lastEnd;
    for (final e in tracker.entries) {
      if (tracker.isBill(e) && (lastEnd == null || e.periodEnd!.isAfter(lastEnd))) lastEnd = CostEngine.day(e.periodEnd!);
    }
    // Sechs Monate zurück, am Monatsende gekürzt (31.8. → 28.2., nicht 3.3.).
    final monthStart = DateTime.utc(today.year, today.month - 6);
    final lastDay = DateTime.utc(monthStart.year, monthStart.month + 1, 0).day;
    final start = lastEnd?.add(const Duration(days: 1)) ?? DateTime.utc(monthStart.year, monthStart.month, today.day > lastDay ? lastDay : today.day);
    return (start: start, end: start.isAfter(today) ? start : today);
  }

  static const maxNote = 1000;
  static const maxText = 500;

  final Tracker tracker;
  final String entryId;
  final bool isNew;

  /// Stichtag des Eintrags (UTC-Mitternacht). Bei einer Rechnung zählt stattdessen [periodEnd].
  final DateTime date;
  final String decimalSeparator;

  /// Heute (UTC-Mitternacht) – Grenze für Daten von Rechnungen und Ständen.
  final DateTime today;
  final EntryFormMode mode;

  /// Eingaben je Feld: `String` bei Zahlen und Text, `String?` bei Auswahl, `bool?` bei Ja/Nein,
  /// `DateTime?` bei Datum.
  final Map<String, Object?> inputs;

  /// Werte des Eintrags beim Öffnen (leer bei einem neuen).
  final Map<String, Object> originalValues;
  final String note;
  final bool meterChange;

  /// Zeitraum einer Rechnung bzw. Abrechnungszeitraum einer Einmalzahlung (z. B. Nachzahlung für
  /// 2025): Verbrauch und Kosten verteilen sich über diese Tage. Beide `null` = kein Zeitraum.
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool saving;
  final EntryFormEvent? event;

  bool get isBill => mode == EntryFormMode.bill;

  /// Felder, die der Modus erfasst. Details (Anbieter, Vertragsende) legt man einmal fest, nicht je
  /// Eintrag; Formeln rechnet die App.
  List<FieldDefinition> get fields => switch (mode) {
    EntryFormMode.standard => tracker.entryFields,
    EntryFormMode.bill => [for (final f in tracker.entryFields) if (f.role == FieldRole.meterReading || f.role == FieldRole.oneOffCost) f],
    EntryFormMode.reading => [for (final f in tracker.entryFields) if (!f.isRate) f],
    EntryFormMode.contract => tracker.contractFields,
  };

  /// Rechnung und Zählerstand lassen sich bei einem neuen Eintrag wechseln.
  bool get canSwitchMode => isNew && (mode == EntryFormMode.bill || mode == EntryFormMode.reading);

  /// Datum heißt „Gilt ab“, wenn der Eintrag nur Preise und Beträge ändert (Preiserhöhung, Miete).
  bool get validFrom => mode == EntryFormMode.contract || (mode == EntryFormMode.standard && fields.isNotEmpty && fields.every((f) => f.isRate));

  /// Details, die ein älterer Eintrag noch selbst trägt: Das Formular zeigt sie nicht, beim
  /// Speichern bleiben sie erhalten.
  Map<String, Object> get keptDetails => {
    for (final f in tracker.detailFields)
      if (originalValues[f.id] case final Object v) f.id: v,
  };

  /// Werte, die ein vorhandener Eintrag für Felder trägt, die dieser Modus nicht zeigt (z. B. Preise in
  /// einem Stand von früher): Sie bleiben beim Speichern erhalten. Formel-Werte rechnet die App.
  Map<String, Object> get keptHidden {
    final shown = {for (final f in fields) f.id};
    return {
      for (final MapEntry(:key, :value) in originalValues.entries)
        if (!shown.contains(key) && tracker.fields.any((f) => f.id == key && f.kind != FieldKind.formula)) key: value,
    };
  }

  /// Spätestes wählbares Datum: Rechnungen und Stände liegen nicht in der Zukunft, Preise dürfen es.
  DateTime? get latestDate => mode == EntryFormMode.bill || mode == EntryFormMode.reading ? today : null;

  /// Schalter „Neuer Zähler“: nur bei einem Zählerstand.
  bool get hasMeter => (mode == EntryFormMode.standard || mode == EntryFormMode.reading) && tracker.meter != null;

  /// Schalter für einen Abrechnungszeitraum: nur im Standardformular mit Einmalkosten-Feld (eine
  /// Rechnung hat ihren Zeitraum immer).
  bool get hasOneOff => mode == EntryFormMode.standard && tracker.firstWithRole(FieldRole.oneOffCost) != null;

  bool get hasPeriod => periodStart != null && periodEnd != null;

  bool get periodInvalid => hasPeriod && periodEnd!.isBefore(periodStart!);

  /// Gespeicherter Wert des Felds, `null` bei leerer oder ungültiger Eingabe.
  Object? valueOf(FieldDefinition f) => switch ((f.kind, inputs[f.id])) {
    (FieldKind.number || FieldKind.currency || FieldKind.percent, final String text) => parseNumber(text, decimalSeparator: decimalSeparator),
    (FieldKind.text || FieldKind.choice, final String text) when text.trim().isNotEmpty => text.trim(),
    (FieldKind.date, final DateTime d) => d,
    (FieldKind.toggle, final bool b) => b,
    _ => null,
  };

  /// Zahlenfelder mit Eingabe, die sich nicht lesen lässt.
  Set<String> get invalid => {
    for (final f in fields)
      if (inputs[f.id] case final String text when text.trim().isNotEmpty && f.kind.storage == FieldStorage.number && valueOf(f) == null) f.id,
  };

  Map<String, Object> get values => {
    for (final f in fields)
      if (valueOf(f) case final Object v) f.id: v,
  };

  /// Eine Rechnung braucht Zeitraum und Verbrauch, sonst reicht ein beliebiger Wert.
  bool get canSave =>
      !saving && values.isNotEmpty && invalid.isEmpty && !periodInvalid && (!isBill || (hasPeriod && values.containsKey(tracker.meter!.id)));

  /// Letzter Wert des Felds vor diesem Datum (ohne diesen Eintrag). Beim Zählerstand zählen nur
  /// Stände, keine Rechnungen.
  (DateTime, Object)? previous(FieldDefinition f) {
    (DateTime, Object)? last;
    for (final e in tracker.entries) {
      if (e.id == entryId || !e.date.isBefore(date)) continue;
      if (f.role == FieldRole.meterReading && tracker.isBill(e)) continue;
      final value = e.values[f.id];
      if (value != null && (last == null || e.date.isAfter(last.$1))) last = (e.date, value);
    }
    return last;
  }

  /// Verbrauch seit dem letzten Stand (in der Verbrauchseinheit), `null` ohne beide Werte.
  double? meterDelta(FieldDefinition f) {
    final now = valueOf(f), before = previous(f)?.$2;
    if (isBill || now is! num || before is! num || meterChange) return null;
    return (now - before) * f.factor;
  }

  /// Zählerstand kleiner als der letzte – Hinweis auf einen Zählerwechsel.
  bool meterBelow(FieldDefinition f) {
    final now = valueOf(f), before = previous(f)?.$2;
    return !isBill && f.role == FieldRole.meterReading && now is num && before is num && now < before && !meterChange;
  }

  /// Verbrauch der Rechnung umgerechnet auf einen Monat, `null` ohne Verbrauch oder Zeitraum.
  double? get billPerMonth {
    final value = isBill ? values[tracker.meter!.id] : null;
    if (value is! num || !hasPeriod || periodInvalid) return null;
    return value / (periodEnd!.difference(periodStart!).inDays + 1) * 365 / 12;
  }

  /// Überschneidet sich der Zeitraum mit einer anderen Rechnung?
  bool get billOverlaps =>
      isBill &&
      hasPeriod &&
      tracker.entries.any((e) => e.id != entryId && tracker.isBill(e) && !e.periodStart!.isAfter(periodEnd!) && !e.periodEnd!.isBefore(periodStart!));

  Entry toEntry() => Entry(
    id: entryId,
    date: isBill ? periodEnd! : date,
    values: {...keptDetails, ...keptHidden, ...values},
    note: note.trim().isEmpty ? null : note.trim(),
    meterChange: hasMeter && meterChange,
    periodStart: isBill || (hasOneOff && hasPeriod) ? periodStart : null,
    periodEnd: isBill || (hasOneOff && hasPeriod) ? periodEnd : null,
  );

  /// [period] ersetzt beide Grenzen (auch durch `null`), ohne bleibt der Zeitraum.
  EntryFormState copyWith({
    DateTime? date,
    EntryFormMode? mode,
    Map<String, Object?>? inputs,
    String? note,
    bool? meterChange,
    ({DateTime? start, DateTime? end})? period,
    bool? saving,
    EntryFormEvent? event,
  }) => EntryFormState(
    tracker: tracker,
    entryId: entryId,
    isNew: isNew,
    date: date ?? this.date,
    decimalSeparator: decimalSeparator,
    today: today,
    mode: mode ?? this.mode,
    inputs: inputs ?? this.inputs,
    originalValues: originalValues,
    note: note ?? this.note,
    meterChange: meterChange ?? this.meterChange,
    periodStart: period == null ? periodStart : period.start,
    periodEnd: period == null ? periodEnd : period.end,
    saving: saving ?? this.saving,
    event: event,
  );

  @override
  List<Object?> get props => [tracker, entryId, isNew, date, decimalSeparator, today, mode, inputs, originalValues, note, meterChange, periodStart, periodEnd, saving, event];
}
