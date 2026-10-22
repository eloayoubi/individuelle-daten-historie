import 'package:equatable/equatable.dart';

import '../../../core/models/tracking.dart';

export '../../../core/models/tracking.dart';

/// Ein Feld, wie es angelegt oder geändert wird (ohne Id).
class FieldDraft extends Equatable {
  const FieldDraft({
    required this.name,
    required this.kind,
    this.role = FieldRole.info,
    this.unit,
    this.consumptionUnit,
    this.factor = 1,
    this.intervalMonths = 1,
    this.choices = const [],
    this.formula,
  });

  factory FieldDraft.of(FieldDefinition f) => FieldDraft(
    name: f.name,
    kind: f.kind,
    role: f.role,
    unit: f.unit,
    consumptionUnit: f.consumptionUnit,
    factor: f.factor,
    intervalMonths: f.intervalMonths,
    choices: f.choices,
    formula: f.formula,
  );

  final String name;
  final FieldKind kind;
  final FieldRole role;
  final String? unit;
  final String? consumptionUnit;
  final double factor;
  final int intervalMonths;
  final List<String> choices;
  final String? formula;

  FieldDefinition withId(String id) => FieldDefinition(
    id: id,
    name: name,
    kind: kind,
    role: role,
    unit: unit,
    consumptionUnit: consumptionUnit,
    factor: factor,
    intervalMonths: intervalMonths,
    choices: choices,
    formula: formula,
  );

  @override
  List<Object?> get props => [name, kind, role, unit, consumptionUnit, factor, intervalMonths, choices, formula];
}

/// Ein Tracker mit seinen Feldern, wie er angelegt wird.
class TrackerDraft extends Equatable {
  const TrackerDraft({required this.name, this.fields = const []});

  final String name;
  final List<FieldDraft> fields;

  @override
  List<Object?> get props => [name, fields];
}

/// Eine neue Kategorie – aus einer Vorlage oder leer.
class CategoryDraft extends Equatable {
  const CategoryDraft({required this.name, required this.icon, required this.swatch, this.templateKey, this.trackers = const []});

  final String name;
  final CategoryIcon icon;
  final CategorySwatch swatch;
  final String? templateKey;
  final List<TrackerDraft> trackers;

  @override
  List<Object?> get props => [name, icon, swatch, templateKey, trackers];
}

/// Kategorien mit ihren Trackern, Feldern und Einträgen – eigene und mit mir geteilte.
///
/// Die Modelle liegen in `core/models/tracking.dart`, weil Übersicht, Kategorien und Auswertung
/// sie gemeinsam nutzen. Nach jeder Änderung meldet [changes] ein Ereignis, damit alle Ansichten
/// neu laden.
abstract interface class CategoriesRepository {
  Stream<void> get changes;

  /// Alle Kategorien in meiner Reihenfolge, archivierte eingeschlossen ([Category.isArchived]).
  Future<List<Category>> loadCategories();

  /// Eine Kategorie, `null` wenn es sie nicht (mehr) gibt oder sie nicht sichtbar ist.
  Future<Category?> loadCategory(String id);

  /// Legt Kategorie, Tracker und Felder in einem Schritt an und liefert die neue Id.
  Future<String> createCategory(CategoryDraft draft);

  Future<void> updateCategory(String id, {required String name, required CategoryIcon icon, required CategorySwatch swatch});

  /// Archivieren und Wiederherstellen (nur owner).
  Future<void> setCategoryArchived(String id, {required bool archived});

  /// Meine Reihenfolge der (nicht archivierten) Kategorien.
  Future<void> reorderCategories(List<String> ids);

  Future<String> createTracker(String categoryId, String name, {required int sort});

  Future<void> renameTracker(String id, String name);

  Future<void> archiveTracker(String id);

  Future<String> createField(String trackerId, FieldDraft draft, {required int sort});

  Future<void> updateField(String id, FieldDraft draft);

  /// Blendet das Feld aus; gespeicherte Werte bleiben erhalten.
  Future<void> archiveField(String id);
}
