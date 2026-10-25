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

/// Der Server hat eine Änderung endgültig abgelehnt (fehlende Rechte, ungültiger Wert) –
/// erneutes Senden hilft nicht. Alle anderen Fehler gelten als vorübergehend (kein Netz).
class WriteRejected implements Exception {
  const WriteRejected(this.message);

  /// Geht nur mit Cloud: lokal (Teilen, Einladungen) oder weil der Eigentümer einer geteilten
  /// Kategorie gerade kein Cloud-Abo hat (Beitreten, Server-Fehler P0064).
  static const cloudRequired = 'cloud_required';

  final String message;

  @override
  String toString() => 'WriteRejected: $message';
}

/// Der Server lässt eine Änderung gerade nicht zu, das kann sich aber ändern (Abo abgelaufen oder
/// noch nicht verbucht, Rolle geändert). Die Offline-Schicht behält sie – sie ist oft die einzige
/// Kopie – und sendet die übrigen weiter.
class WriteHeld implements Exception {
  const WriteHeld(this.message);

  final String message;

  @override
  String toString() => 'WriteHeld: $message';
}

/// Stand der Offline-Warteschlange für Einträge.
class SyncState extends Equatable {
  const SyncState({this.pending = 0, this.rejected = 0});

  /// Noch nicht beim Server (offline erfasst oder gerade unterwegs).
  final int pending;

  /// Vom Server abgelehnt und verworfen, seit der Nutzer zuletzt bestätigt hat.
  final int rejected;

  @override
  List<Object?> get props => [pending, rejected];
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

  /// Kosten des Trackers stecken in einer anderen Kategorie (`null` = eigene Kosten).
  Future<void> setTrackerIncludedIn(String id, String? categoryId);

  Future<String> createField(String trackerId, FieldDraft draft, {required int sort});

  Future<void> updateField(String id, FieldDraft draft);

  /// Blendet das Feld aus; gespeicherte Werte bleiben erhalten.
  Future<void> archiveField(String id);

  /// Speichert einen Eintrag unter seiner Id – neu oder geändert. Die Id vergibt das Gerät
  /// (`newId()`), damit ein offline erfasster Eintrag beim Nachsenden nicht doppelt landet.
  Future<void> saveEntry(String trackerId, Entry entry);

  Future<void> deleteEntry(String trackerId, String entryId);

  /// Wartende und abgelehnte Einträge (nur mit Offline-Schicht ungleich 0).
  SyncState get syncState;

  /// Wartende Einträge jetzt senden (z. B. wenn die App wieder in den Vordergrund kommt).
  Future<void> sync();

  /// Abgelehnte Einträge zur Kenntnis genommen.
  void acknowledgeRejected();

  // Teilen (nur online)

  /// Einladungscode für [categoryId] (nur owner), 7 Tage gültig, einmal einlösbar.
  Future<String> createInvite(String categoryId, MemberRole role);

  /// Code einlösen; liefert die Kategorie-Id. [WriteRejected], wenn er ungültig oder abgelaufen ist.
  Future<String> acceptInvite(String code);

  Future<void> setMemberRole(String categoryId, String userId, MemberRole role);

  Future<void> removeMember(String categoryId, String userId);

  /// Eine mit mir geteilte Kategorie verlassen.
  Future<void> leaveCategory(String categoryId);
}
