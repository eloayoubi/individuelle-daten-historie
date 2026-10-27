part of 'category_setup_cubit.dart';

/// Einmaliges Ereignis: angelegt (mit Id und Name) oder fehlgeschlagen.
class CategorySetupEvent {
  CategorySetupEvent.created(String this.categoryId, String this.name);

  CategorySetupEvent.failed() : categoryId = null, name = null;

  final String? categoryId;
  final String? name;
}

class CategorySetupState extends Equatable {
  const CategorySetupState({
    required this.name,
    required this.icon,
    required this.swatch,
    this.template,
    this.excluded = const {},
    this.saving = false,
    this.event,
  });

  /// Wie in der Datenbank (`categories.name`).
  static const maxName = 60;

  final String name;
  final CategoryIcon icon;
  final CategorySwatch swatch;

  /// `null` = eigene Kategorie ohne Tracker.
  final CategoryTemplate? template;

  /// Abgewählte Felder der Vorlage als (Tracker, Feld).
  final Set<(int, int)> excluded;
  final bool saving;
  final CategorySetupEvent? event;

  bool get canCreate => name.trim().isNotEmpty && !saving;

  bool isIncluded(int tracker, int field) => !excluded.contains((tracker, field));

  CategoryDraft get draft => CategoryDraft(
    name: name.trim(),
    icon: icon,
    swatch: swatch,
    templateKey: template?.key,
    trackers: [
      for (final (t, tracker) in (template?.trackers ?? const <TrackerDraft>[]).indexed) tracker.where((f) => isIncluded(t, f)),
    ],
  );

  CategorySetupState copyWith({String? name, CategoryIcon? icon, CategorySwatch? swatch, Set<(int, int)>? excluded, bool? saving, CategorySetupEvent? event}) =>
      CategorySetupState(
        name: name ?? this.name,
        icon: icon ?? this.icon,
        swatch: swatch ?? this.swatch,
        template: template,
        excluded: excluded ?? this.excluded,
        saving: saving ?? this.saving,
        event: event,
      );

  @override
  List<Object?> get props => [name, icon, swatch, template, excluded, saving, event];
}
