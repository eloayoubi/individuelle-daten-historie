import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/categories_repository.dart';
import '../data/category_templates.dart';
import '../data/vehicle_drive.dart';

part 'category_setup_state.dart';

/// Neue Kategorie anlegen – aus einer Vorlage (Felder lassen sich abwählen) oder leer.
class CategorySetupCubit extends Cubit<CategorySetupState> {
  CategorySetupCubit(this._repository, CategoryTemplate? template)
    : super(
        CategorySetupState(
          name: template?.name ?? '',
          icon: template?.icon ?? CategoryIcon.star,
          swatch: template?.swatch ?? CategorySwatch.indigo,
          template: template,
          drive: template == null || template.drives.isEmpty ? null : VehicleDrive.fuel,
        ),
      );

  final CategoriesRepository _repository;

  void setName(String name) => emit(state.copyWith(name: name));

  void setIcon(CategoryIcon icon) => emit(state.copyWith(icon: icon));

  void setSwatch(CategorySwatch swatch) => emit(state.copyWith(swatch: swatch));

  /// Abgewählte Felder über alle Antriebe hinweg: Ein Feld, das es beim aktuellen Antrieb nicht
  /// gibt (Liter bei „Elektro“), bleibt abgewählt, wenn es beim nächsten Wechsel zurückkommt.
  final _hidden = <(int, int, FieldDraft)>{};

  /// Dasselbe Feld bei einem anderen Antrieb: gleicher Name, oder an gleicher Stelle mit gleicher
  /// Art, Rolle und Einheit (der Betrag heißt je Antrieb anders: Tanken, Laden …).
  static bool _same((int, int, FieldDraft) a, (int, int, FieldDraft) b) {
    final (ta, ia, fa) = a;
    final (tb, ib, fb) = b;
    if (ta != tb) return false;
    if (fa.name == fb.name) return true;
    return ia == ib && fa.kind == fb.kind && fa.role == fb.role && fa.unit == fb.unit;
  }

  /// Antrieb des Fahrzeugs: wechselt die Felder fürs Tanken und Laden. Abgewählte Felder bleiben
  /// abgewählt, auch über einen Antrieb hinweg, bei dem es sie nicht gibt.
  void setDrive(VehicleDrive drive) {
    final after = state.template?.trackersFor(drive) ?? const <TrackerDraft>[];
    final excluded = {
      for (final (t, tracker) in after.indexed)
        for (final (i, field) in tracker.fields.indexed)
          if (_hidden.any((h) => _same(h, (t, i, field)))) (t, i),
    };
    emit(state.copyWith(drive: drive, excluded: excluded));
  }

  /// Feld der Vorlage an- oder abwählen.
  void toggleField(int tracker, int field) {
    final key = (tracker, field);
    final excluded = {...state.excluded};
    final entry = (tracker, field, state.trackers[tracker].fields[field]);
    if (excluded.remove(key)) {
      _hidden.removeWhere((h) => _same(h, entry));
    } else {
      excluded.add(key);
      _hidden.add(entry);
    }
    emit(state.copyWith(excluded: excluded));
  }

  Future<void> create() async {
    if (!state.canCreate) return;
    emit(state.copyWith(saving: true));
    try {
      final id = await _repository.createCategory(state.draft);
      if (!isClosed) emit(state.copyWith(saving: false, event: CategorySetupEvent.created(id, state.name.trim())));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(saving: false, event: CategorySetupEvent.failed()));
    }
  }
}
