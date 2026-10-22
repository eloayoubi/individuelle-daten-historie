import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/categories_repository.dart';
import '../data/category_templates.dart';

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
        ),
      );

  final CategoriesRepository _repository;

  void setName(String name) => emit(state.copyWith(name: name));

  void setIcon(CategoryIcon icon) => emit(state.copyWith(icon: icon));

  void setSwatch(CategorySwatch swatch) => emit(state.copyWith(swatch: swatch));

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
