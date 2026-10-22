import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Ein JSON-Dokument auf dem Gerät (Cache, Warteschlange, Einstellungen).
abstract interface class JsonStore {
  /// `null`, wenn noch nichts gespeichert ist oder die Datei kaputt ist.
  Future<Object?> read();

  Future<void> write(Object? json);
}

/// Datei im App-Support-Ordner (wird nicht in iCloud gesichert und vom Nutzer nicht gesehen).
class FileJsonStore implements JsonStore {
  FileJsonStore(this.name);

  final String name;

  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/$name.json');

  @override
  Future<Object?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (_) {
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
