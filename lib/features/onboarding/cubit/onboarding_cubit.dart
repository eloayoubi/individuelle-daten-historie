import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/json_store.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/data/category_templates.dart';

part 'onboarding_state.dart';

/// Erster Start: Willkommen → Kategorien aus Vorlagen wählen → Erinnerungen. Erscheint nur, solange
/// es keine Kategorien gibt und das Onboarding nicht abgeschlossen ist.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository, this._store) : super(const OnboardingState());

  final CategoriesRepository _repository;
  final JsonStore _store;

  /// Vorlagen, die zum Start ausgewählt sind – die meisten Haushalte haben sie.
  static const suggested = {'strom', 'heizung', 'wasser'};

  Future<void> load() async {
    if (await _store.read().catchError((Object _) => null) case {'done': true}) {
      if (!isClosed) emit(state.copyWith(loaded: true));
      return;
    }
    try {
      final categories = await _repository.loadCategories();
      if (categories.isNotEmpty) {
        // Kategorien gibt es schon (anderes Gerät, Partner): nichts einzurichten.
        await _markDone();
        if (!isClosed) emit(state.copyWith(loaded: true));
        return;
      }
    } catch (_) {
      // Offline beim ersten Start: trotzdem begrüßen.
    }
    if (!isClosed) emit(state.copyWith(loaded: true, show: true));
  }

  void next() {
    if (state.step.index < OnboardingStep.values.length - 1) emit(state.copyWith(step: OnboardingStep.values[state.step.index + 1]));
  }

  void toggle(String key) =>
      emit(state.copyWith(selected: state.selected.contains(key) ? ({...state.selected}..remove(key)) : {...state.selected, key}));

  /// Legt die gewählten Vorlagen an (in der Reihenfolge der Liste) und geht weiter.
  Future<void> create(List<CategoryTemplate> templates) async {
    emit(state.copyWith(busy: true));
    try {
      for (final t in templates) {
        if (!state.selected.contains(t.key)) continue;
        await _repository.createCategory(CategoryDraft(name: t.name, icon: t.icon, swatch: t.swatch, templateKey: t.key, trackers: t.trackers));
      }
      if (!isClosed) emit(state.copyWith(busy: false, step: OnboardingStep.reminders));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(busy: false, event: OnboardingEvent()));
    }
  }

  Future<void> finish() async {
    await _markDone();
    if (!isClosed) emit(state.copyWith(show: false));
  }

  Future<void> _markDone() => _store.write({'done': true}).catchError((Object _) {});
}
