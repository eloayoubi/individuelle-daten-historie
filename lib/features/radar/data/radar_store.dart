import '../../../core/utils/json_store.dart';

/// Welche Funde des Radars der Nutzer ausgeblendet hat – als Kennungen ([Finding.id]: nur Ids, ein
/// Datum und ein gerundeter Wert, keine Namen), je Gerät.
class RadarStore {
  RadarStore(this._store);

  /// Mehr merkt sich das Gerät nicht; die ältesten fallen weg.
  static const maxIds = 200;

  /// Längere Kennungen stammen nicht vom Radar (beschädigte Datei) und werden ignoriert.
  static const maxIdLength = 200;

  final JsonStore _store;

  /// Stand im Speicher nach dem ersten Lesen, älteste zuerst: Zwei schnelle „Ausblenden“ nacheinander
  /// überschreiben sich so nicht.
  List<String>? _ids;

  /// Gespeicherte Kennungen – höchstens [maxIds], auch wenn die Datei mehr enthält.
  Future<List<String>> _read() async {
    final ids = switch (await _store.read()) {
      final List<Object?> ids => [for (final id in ids) if (id is String && id.isNotEmpty && id.length <= maxIdLength) id],
      _ => <String>[],
    };
    return ids.length > maxIds ? ids.sublist(ids.length - maxIds) : ids;
  }

  Future<Set<String>> load() async => {...(_ids ??= await _read())};

  /// Merkt sich [id] und gibt alle ausgeblendeten Kennungen zurück.
  Future<Set<String>> dismiss(String id) async {
    final known = _ids ??= await _read();
    final ids = [for (final other in known) if (other != id) other, id];
    final kept = _ids = ids.length > maxIds ? ids.sublist(ids.length - maxIds) : ids;
    await _store.write(kept);
    return {...kept};
  }
}
