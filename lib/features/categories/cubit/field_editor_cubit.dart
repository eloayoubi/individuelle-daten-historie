import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/formulas.dart';
import '../data/categories_repository.dart';

part 'field_editor_state.dart';

/// Wofür der Editor geöffnet wird: neues Feld in [trackerId] oder vorhandenes [field].
class FieldEditorArgs {
  const FieldEditorArgs({required this.trackerId, this.tracker, this.field, this.hasValues = false, this.sort = 0});

  final String trackerId;

  /// Der Tracker selbst – für Formeln (Namen der anderen Felder, Vorschau).
  final Tracker? tracker;
  final FieldDefinition? field;

  /// Vorhandene Werte schränken den Typwechsel ein (siehe [FieldKindRules.canBecome]).
  final bool hasValues;

  /// Position eines neuen Felds (hinter den vorhandenen).
  final int sort;
}

/// Feld anlegen oder ändern: Name, Feldtyp, Zeitverhalten und je nach Typ Einheit, Umrechnung,
/// Intervall oder Auswahlwerte. Passt das Zeitverhalten nach einem Typwechsel nicht mehr, springt
/// es auf das erste passende.
class FieldEditorCubit extends Cubit<FieldEditorState> {
  FieldEditorCubit(this._repository, this.args) : super(FieldEditorState.of(args.field, hasValues: args.hasValues, tracker: args.tracker));

  final CategoriesRepository _repository;
  final FieldEditorArgs args;

  void setName(String name) => emit(state.copyWith(name: name));

  void setKind(FieldKind kind) {
    if (!state.canPick(kind)) return;
    final role = kind.roles.contains(state.role) ? state.role : kind.roles.first;
    emit(state.copyWith(kind: kind, role: role));
  }

  void setRole(FieldRole role) {
    if (state.lockedRole != null && role != state.lockedRole) return;
    if (state.kind.roles.contains(role)) emit(state.copyWith(role: role));
  }

  void setUnit(String unit) => emit(state.copyWith(unit: unit));

  void setConsumptionUnit(String unit) => emit(state.copyWith(consumptionUnit: unit));

  void setFactor(String text) => emit(state.copyWith(factorText: text));

  void setInterval(int months) => emit(state.copyWith(intervalMonths: months));

  void setFormula(String formula) => emit(state.copyWith(formula: formula));

  void setSummary(FieldSummary summary) {
    if (state.summaries.contains(summary)) emit(state.copyWith(summary: () => summary));
  }

  void addChoice(String choice) {
    final value = choice.trim();
    if (value.isEmpty || state.choices.contains(value)) return;
    emit(state.copyWith(choices: [...state.choices, value]));
  }

  void removeChoice(String choice) => emit(state.copyWith(choices: [...state.choices.where((c) => c != choice)]));

  Future<void> save() async {
    if (!state.canSave) return;
    emit(state.copyWith(saving: true));
    try {
      final field = args.field;
      if (field == null) {
        await _repository.createField(args.trackerId, state.draft, sort: args.sort);
      } else {
        await _repository.updateField(field.id, state.draft);
      }
      if (!isClosed) emit(state.copyWith(saving: false, event: FieldEditorEvent(FieldEditorEventKind.saved)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(saving: false, event: FieldEditorEvent(FieldEditorEventKind.failed)));
    }
  }

  Future<void> archive() async {
    final field = args.field;
    if (field == null || !state.canArchive) return;
    emit(state.copyWith(saving: true));
    try {
      await _repository.archiveField(field.id);
      if (!isClosed) emit(state.copyWith(saving: false, event: FieldEditorEvent(FieldEditorEventKind.archived)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(saving: false, event: FieldEditorEvent(FieldEditorEventKind.failed)));
    }
  }
}
