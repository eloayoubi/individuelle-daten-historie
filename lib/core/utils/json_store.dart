import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Ein JSON-Dokument auf dem Gerät (Cache, Warteschlange, Einstellungen).
abstract interface class JsonStore {
  /// `null`, wenn noch nichts gespeichert ist oder die Datei kaputt ist (strikt: nur wenn nichts
  /// gespeichert ist, sonst ein Fehler).
  Future<Object?> read();

  Future<void> write(Object? json);
}

/// Datei im App-Support-Ordner (vom Nutzer nicht gesehen).
///
/// [strict] für Daten, die es nur hier gibt (Speicherort „Lokal“): Ein Lese- oder Formatfehler
/// wirft, statt „leer“ zu melden – sonst überschriebe die nächste Änderung die Datei.
class FileJsonStore implements JsonStore {
  FileJsonStore(this.name, {this.strict = false});

  final String name;
  final bool strict;

  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/$name.json');

  @override
  Future<Object?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (_) {
      if (strict) rethrow;
      return null;
    }
  }

  @override
  Future<void> write(Object? json) async {
    final f = await _file();
    // Erst in eine Nachbardatei, dann umbenennen: Ein Absturz beim Schreiben lässt den alten Stand stehen.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename(f.path);
  }
}

/// Für Mock-Modus und Tests.
class MemoryJsonStore implements JsonStore {
  MemoryJsonStore([this._json]);

  Object? _json;

  @override
  Future<Object?> read() async => _json == null ? null : jsonDecode(jsonEncode(_json));

  @override
  Future<void> write(Object? json) async => _json = json == null ? null : jsonDecode(jsonEncode(json));
}
