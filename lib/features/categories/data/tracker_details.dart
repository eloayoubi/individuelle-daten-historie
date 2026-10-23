import '../../../core/utils/cost_engine.dart';
import '../../../core/utils/ids.dart';
import 'categories_repository.dart';

/// Details eines Trackers (Anbieter, Vertragsnummer, Vertragsende) setzen und entfernen.
///
/// Details haben keinen Verlauf, gespeichert werden sie aber wie Werte: in einem Eintrag, der nur
/// Details trägt ([Tracker.isDetailEntry]). So gehen sie offline durch dieselbe Warteschlange wie
/// Einträge, und es braucht keine eigene Tabelle.
extension TrackerDetails on CategoriesRepository {
  /// [value] `null` entfernt das Detail aus allen Einträgen. Sonst landet es im Detail-Eintrag von
  /// heute (vorhanden oder neu); spätere Einträge verlieren ihren Wert dafür, damit der neue gilt.
  Future<void> saveDetail(Tracker tracker, FieldDefinition field, Object? value, {required DateTime now}) async {
    final today = CostEngine.day(now);
    final todays = value == null ? null : tracker.entries.where((e) => e.date == today && tracker.isDetailEntry(e)).firstOrNull;
    for (final e in tracker.entries) {
      if (e == todays || !e.values.containsKey(field.id) || (value != null && !e.date.isAfter(today))) continue;
      final rest = _stored(tracker, e)..remove(field.id);
      // Ein Eintrag ohne Wert ist keiner (save_entry lehnt ihn ab).
      if (rest.isEmpty) {
        await deleteEntry(tracker.id, e.id);
      } else {
        await saveEntry(tracker.id, e.copyWith(values: rest));
      }
    }
    if (value == null) return;
    final base = todays ?? Entry(id: newId(), date: today);
    await saveEntry(tracker.id, base.copyWith(values: {..._stored(tracker, base), field.id: value}));
  }

  /// Werte ohne Formel-Ergebnisse (die rechnet die App, gespeichert werden sie nie).
  static Map<String, Object> _stored(Tracker tracker, Entry e) => {
    for (final MapEntry(:key, :value) in e.values.entries)
      if (tracker.fields.where((f) => f.id == key).firstOrNull?.kind != FieldKind.formula) key: value,
  };
}
