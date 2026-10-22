part of 'entry_form_cubit.dart';

enum EntryFormEventKind { saved, savedOffline, deleted, failed }

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
    this.inputs = const {},
    this.note = '',
    this.meterChange = false,
    this.saving = false,
    this.event,
  });

  factory EntryFormState.initial(EntryFormArgs args, DateTime now) {
    final entry = args.entry;
    return EntryFormState(
      tracker: args.tracker,
      entryId: entry?.id ?? newId(),
      isNew: entry == null,
      date: CostEngine.day(entry?.date ?? now),
      decimalSeparator: args.decimalSeparator,
      note: entry?.note ?? '',
      meterChange: entry?.meterChange ?? false,
      inputs: {
        for (final MapEntry(:key, :value) in (entry?.values ?? const <String, Object>{}).entries)
          key: value is num ? formatNumberInput(value, decimalSeparator: args.decimalSeparator) : value,
      },
    );
  }

  static const maxNote = 1000;
  static const maxText = 500;

  final Tracker tracker;
  final String entryId;
  final bool isNew;

  /// Stichtag des Eintrags (UTC-Mitternacht).
  final DateTime date;
  final String decimalSeparator;

  /// Eingaben je Feld: `String` bei Zahlen und Text, `String?` bei Auswahl, `bool?` bei Ja/Nein,
  /// `DateTime?` bei Datum.
  final Map<String, Object?> inputs;
  final String note;
  final bool meterChange;
  final bool saving;
  final EntryFormEvent? event;

  /// Formeln rechnet die App, sie werden nicht eingegeben.
  List<FieldDefinition> get fields => [for (final f in tracker.fields) if (f.kind != FieldKind.formula) f];

  bool get hasMeter => tracker.firstWithRole(FieldRole.meterReading) != null;

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

  bool get canSave => !saving && values.isNotEmpty && invalid.isEmpty;

  /// Letzter Wert des Felds vor diesem Datum (ohne diesen Eintrag).
  (DateTime, Object)? previous(FieldDefinition f) {
    (DateTime, Object)? last;
    for (final e in tracker.entries) {
      if (e.id == entryId || !e.date.isBefore(date)) continue;
      final value = e.values[f.id];
      if (value != null && (last == null || e.date.isAfter(last.$1))) last = (e.date, value);
    }
    return last;
  }

  /// Verbrauch seit dem letzten Stand (in der Verbrauchseinheit), `null` ohne beide Werte.
  double? meterDelta(FieldDefinition f) {
    final now = valueOf(f), before = previous(f)?.$2;
    if (now is! num || before is! num || meterChange) return null;
    return (now - before) * f.factor;
  }

  /// Zählerstand kleiner als der letzte – Hinweis auf einen Zählerwechsel.
  bool meterBelow(FieldDefinition f) {
    final now = valueOf(f), before = previous(f)?.$2;
    return f.role == FieldRole.meterReading && now is num && before is num && now < before && !meterChange;
  }

  Entry toEntry() => Entry(
    id: entryId,
    date: date,
    values: values,
    note: note.trim().isEmpty ? null : note.trim(),
    meterChange: hasMeter && meterChange,
  );

  EntryFormState copyWith({DateTime? date, Map<String, Object?>? inputs, String? note, bool? meterChange, bool? saving, EntryFormEvent? event}) =>
      EntryFormState(
        tracker: tracker,
        entryId: entryId,
        isNew: isNew,
        date: date ?? this.date,
        decimalSeparator: decimalSeparator,
        inputs: inputs ?? this.inputs,
        note: note ?? this.note,
        meterChange: meterChange ?? this.meterChange,
        saving: saving ?? this.saving,
        event: event,
      );

  @override
  List<Object?> get props => [tracker, entryId, isNew, date, decimalSeparator, inputs, note, meterChange, saving, event];
}
