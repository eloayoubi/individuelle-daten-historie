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

  /// Antrieb des Fahrzeugs: wechselt die Felder fürs Tanken und Laden. Abgewählte Felder bleiben
  /// abgewählt, soweit es sie beim neuen Antrieb gibt.
  void setDrive(VehicleDrive drive) {
    final before = state.trackers;
    final after = state.template?.trackersFor(drive) ?? const <TrackerDraft>[];
    final excluded = {
      for (final (t, f) in state.excluded)
        if (t < after.length)
          if (after[t].fields.indexWhere((field) => field.name == before[t].fields[f].name) case final i when i >= 0) (t, i),
    };
    emit(state.copyWith(drive: drive, excluded: excluded));
  }

  /// Feld der Vorlage an- oder abwählen.
  void toggleField(int tracker, int field) {
    final key = (tracker, field);
    final excluded = {...state.excluded};
    if (!excluded.remove(key)) excluded.add(key);
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
