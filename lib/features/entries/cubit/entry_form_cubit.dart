import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/cost_engine.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/numbers.dart';
import '../../categories/data/categories_repository.dart';

part 'entry_form_state.dart';

/// Wofür das Formular geöffnet wird: neuer Eintrag in [tracker] oder vorhandener [entry].
class EntryFormArgs {
  const EntryFormArgs({required this.category, required this.tracker, this.entry, this.decimalSeparator = ','});

  final Category category;
  final Tracker tracker;
  final Entry? entry;

  /// Aus der App-Sprache (`context.decimalSeparator`), für Eingabe und Vorbelegung.
  final String decimalSeparator;
}

/// Eintrag erfassen oder ändern: Datum, ein Wert je Feld (alle optional, mindestens einer),
/// Notiz und – bei Zählern – „neuer Zähler“. Gespeichert wird über das Repository, das offline
/// erst in die Warteschlange schreibt.
class EntryFormCubit extends Cubit<EntryFormState> {
  EntryFormCubit(this._repository, this.args, {DateTime Function()? now}) : super(EntryFormState.initial(args, (now ?? DateTime.now)()));

  final CategoriesRepository _repository;
  final EntryFormArgs args;

  void setDate(DateTime date) => emit(state.copyWith(date: CostEngine.day(date)));

  void setText(String fieldId, String text) => _set(fieldId, text);

  void setChoice(String fieldId, String? choice) => _set(fieldId, choice);

  void setToggle(String fieldId, bool? value) => _set(fieldId, value);

  void setFieldDate(String fieldId, DateTime? date) => _set(fieldId, date == null ? null : CostEngine.day(date));

  void setNote(String note) => emit(state.copyWith(note: note));

  void setMeterChange(bool value) => emit(state.copyWith(meterChange: value));

  /// Zeitraum an: vorbelegt mit dem Kalenderjahr vor dem Stichtag (typisch für Abrechnungen).
  void setPeriodEnabled(bool on) {
    final year = state.date.year - 1;
    emit(state.copyWith(period: on ? (start: DateTime.utc(year), end: DateTime.utc(year, 12, 31)) : (start: null, end: null)));
  }

  void setPeriodStart(DateTime day) => emit(state.copyWith(period: (start: CostEngine.day(day), end: state.periodEnd)));

  void setPeriodEnd(DateTime day) => emit(state.copyWith(period: (start: state.periodStart, end: CostEngine.day(day))));

  void _set(String fieldId, Object? value) => emit(state.copyWith(inputs: {...state.inputs, fieldId: value}));

  Future<void> save() async {
    if (!state.canSave) return;
    emit(state.copyWith(saving: true));
    try {
      await _repository.saveEntry(args.tracker.id, state.toEntry());
      // Offline landet der Eintrag erst in der Warteschlange – das sagen wir dazu.
      final kind = _repository.syncState.pending > 0 ? EntryFormEventKind.savedOffline : EntryFormEventKind.saved;
      if (!isClosed) emit(state.copyWith(saving: false, event: EntryFormEvent(kind)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(saving: false, event: EntryFormEvent(EntryFormEventKind.failed)));
    }
  }

  Future<void> delete() async {
    if (state.isNew) return;
    emit(state.copyWith(saving: true));
    try {
      await _repository.deleteEntry(args.tracker.id, state.entryId);
      if (!isClosed) emit(state.copyWith(saving: false, event: EntryFormEvent(EntryFormEventKind.deleted)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(saving: false, event: EntryFormEvent(EntryFormEventKind.failed)));
    }
  }
}
