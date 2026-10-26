part of 'field_editor_cubit.dart';

enum FieldEditorEventKind { saved, archived, failed }

/// Einmaliges Ereignis für Toast und Zurück. Bewusst nicht `const`.
class FieldEditorEvent {
  FieldEditorEvent(this.kind);

  final FieldEditorEventKind kind;
}

class FieldEditorState extends Equatable {
  const FieldEditorState({
    required this.isNew,
    required this.originalKind,
    required this.hasValues,
    this.keepsBills = false,
    this.keepsMeter = false,
    this.tracker,
    required this.name,
    required this.kind,
    required this.role,
    this.unit = '',
    this.consumptionUnit = '',
    this.meterGroup = '',
    this.factorText = '1',
    this.intervalMonths = 1,
    this.choices = const [],
    this.formula = '',
    this.summary,
    this.saving = false,
    this.event,
  });

  factory FieldEditorState.of(FieldDefinition? field, {required bool hasValues, Tracker? tracker}) => FieldEditorState(
    isNew: field == null,
    originalKind: field?.kind,
    hasValues: hasValues,
    keepsBills: field != null && tracker != null && _carriesBills(tracker, field),
    keepsMeter: hasValues && field?.role == FieldRole.meterReading,
    tracker: tracker,
    formula: field?.formula ?? '',
    name: field?.name ?? '',
    kind: field?.kind ?? FieldKind.number,
    role: field?.role ?? FieldRole.snapshot,
    unit: field?.unit ?? '',
    consumptionUnit: field?.consumptionUnit ?? '',
    meterGroup: field?.meterGroup ?? '',
    factorText: _formatFactor(field?.factor ?? 1),
    intervalMonths: field?.intervalMonths ?? 1,
    choices: field?.choices ?? const [],
    summary: field?.summary,
  );

  /// Letzter Arbeitspreis eines Versorgungszählers mit Rechnungen: Ohne ihn wären die Rechnungen
  /// keine mehr (siehe [Tracker.isBill]).
  static bool _carriesBills(Tracker tracker, FieldDefinition field) =>
      field.role == FieldRole.unitPrice && tracker.withRole(FieldRole.unitPrice).length == 1 && tracker.entries.any(tracker.isBill);

  /// Grenzen wie in der Datenbank.
  static const maxName = 60;
  static const maxUnit = 20;
  static const maxMeterGroup = 40;
  static const maxChoice = 40;

  final bool isNew;
  final FieldKind? originalKind;
  final bool hasValues;

  /// Das Feld trägt die Rechnungen des Zählers: Es bleibt ein Arbeitspreis und lässt sich nicht
  /// archivieren.
  final bool keepsBills;

  /// Zählerstand mit Werten: bleibt Zählerstand (als Zahl) – sonst würden alle Stände umgedeutet.
  final bool keepsMeter;

  /// Zeitverhalten liegt fest (Zählerstand mit Werten, Arbeitspreis mit Rechnungen).
  FieldRole? get lockedRole => keepsMeter ? FieldRole.meterReading : (keepsBills ? FieldRole.unitPrice : null);

  /// Für Formeln: welche Namen es gibt und wie die Vorschau rechnet.
  final Tracker? tracker;

  final String name;
  final FieldKind kind;
  final FieldRole role;
  final String unit;
  final String consumptionUnit;

  /// Gruppe eines Zählerstands (Kaltwasser, Warmwasser); leer = ohne.
  final String meterGroup;

  /// Umrechnungsfaktor, wie eingetippt (Komma oder Punkt).
  final String factorText;
  final int intervalMonths;
  final List<String> choices;

  /// Ausdruck bei [FieldKind.formula].
  final String formula;

  /// Gewählte Zusammenfassung für Kennzahlen; `null` = Standard des Zeitverhaltens.
  final FieldSummary? summary;
  final bool saving;
  final FieldEditorEvent? event;

  /// Vorhandene Werte begrenzen den Wechsel (eine Formel speichert keine Werte).
  bool canPick(FieldKind k) => (originalKind?.canBecome(k, hasValues: hasValues) ?? true) && (lockedRole == null || k.roles.contains(lockedRole));

  /// Prüfung des Ausdrucks gegen die Felder des Trackers.
  FormulaCheck get formulaCheck => Formulas.check(formula, tracker ?? const Tracker(id: '', name: ''));

  double? get factor {
    final value = parseDecimal(factorText);
    return value != null && value > 0 ? value : null;
  }

  bool get factorValid => role != FieldRole.meterReading || factor != null;

  bool get canSave =>
      !saving &&
      name.trim().isNotEmpty &&
      factorValid &&
      (kind != FieldKind.choice || choices.isNotEmpty) &&
      (kind != FieldKind.formula || formulaCheck.isValid) &&
      (!keepsBills || role == FieldRole.unitPrice);

  bool get canArchive => !isNew && !keepsBills;

  /// Zusammenfassungen, die zu Typ und Zeitverhalten passen (leer: Feld ohne Kennzahl).
  List<FieldSummary> get summaries => kind.storage == FieldStorage.number || kind == FieldKind.formula ? role.summaries : const [];

  /// Gilt gerade: die gewählte, wenn sie passt, sonst die erste passende.
  FieldSummary? get effectiveSummary => summaries.contains(summary) ? summary : summaries.firstOrNull;

  FieldDraft get draft {
    final meter = role == FieldRole.meterReading;
    return FieldDraft(
      name: name.trim(),
      kind: kind,
      role: role,
      unit: kind.hasUnit && unit.trim().isNotEmpty ? unit.trim() : null,
      consumptionUnit: meter && consumptionUnit.trim().isNotEmpty ? consumptionUnit.trim() : null,
      factor: meter ? factor ?? 1 : 1,
      meterGroup: meter && meterGroup.trim().isNotEmpty ? meterGroup.trim() : null,
      intervalMonths: role == FieldRole.recurringCost ? intervalMonths : 1,
      choices: kind == FieldKind.choice ? choices : const [],
      formula: kind == FieldKind.formula ? formula.trim() : null,
      summary: summaries.contains(summary) ? summary : null,
    );
  }

  /// Kommazahl aus der Eingabe, mit Komma oder Punkt (`10,35` → 10.35).
  static double? parseDecimal(String text) => double.tryParse(text.trim().replaceAll(' ', '').replaceAll(',', '.'));

  static String _formatFactor(double f) => f == f.roundToDouble() ? f.toInt().toString() : f.toString().replaceAll('.', ',');

  FieldEditorState copyWith({
    String? name,
    FieldKind? kind,
    FieldRole? role,
    String? unit,
    String? consumptionUnit,
    String? meterGroup,
    String? factorText,
    int? intervalMonths,
    List<String>? choices,
    String? formula,
    FieldSummary? Function()? summary,
    bool? saving,
    FieldEditorEvent? event,
  }) => FieldEditorState(
    isNew: isNew,
    originalKind: originalKind,
    hasValues: hasValues,
    keepsBills: keepsBills,
    keepsMeter: keepsMeter,
    tracker: tracker,
    formula: formula ?? this.formula,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    role: role ?? this.role,
    unit: unit ?? this.unit,
    consumptionUnit: consumptionUnit ?? this.consumptionUnit,
    meterGroup: meterGroup ?? this.meterGroup,
    factorText: factorText ?? this.factorText,
    intervalMonths: intervalMonths ?? this.intervalMonths,
    choices: choices ?? this.choices,
    summary: summary == null ? this.summary : summary(),
    saving: saving ?? this.saving,
    event: event,
  );

  @override
  List<Object?> get props => [isNew, originalKind, hasValues, keepsBills, keepsMeter, tracker, name, kind, role, unit, consumptionUnit, meterGroup, factorText, intervalMonths, choices, formula, summary, saving, event];
}
