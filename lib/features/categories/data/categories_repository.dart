import '../../../core/models/tracking.dart';

export '../../../core/models/tracking.dart';

/// Kategorien mit ihren Trackern, Feldern und Einträgen – eigene und mit mir geteilte.
///
/// Die Modelle liegen in `core/models/tracking.dart`, weil Übersicht, Kategorien und Auswertung
/// sie gemeinsam nutzen.
abstract interface class CategoriesRepository {
  /// Alle nicht archivierten Kategorien, sortiert wie vom Nutzer festgelegt.
  Future<List<Category>> loadCategories();
}
