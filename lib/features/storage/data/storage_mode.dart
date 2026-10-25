import 'dart:async';

import '../../../core/utils/json_store.dart';

/// Wo die Daten liegen: nur auf diesem Gerät (kostenlos) oder in der Cloud (mit Konto und Abo).
enum StorageMode { local, cloud }

/// Gewählter Speicherort dieses Geräts; `null`, bis der Nutzer auf dem Start-Bildschirm wählt.
///
/// Öffnet keine Rechte: Ob die Cloud beschrieben werden darf, entscheidet der Server (RLS).
class StorageModeStore {
  StorageModeStore(this._store);

  final JsonStore _store;
  final _changes = StreamController<StorageMode?>.broadcast();
  StorageMode? _mode;

  StorageMode? get mode => _mode;

  Stream<StorageMode?> get changes => _changes.stream;

  /// Einmal beim Start, vor dem ersten Zugriff auf die Daten.
  Future<void> load() async {
    if (await _store.read().catchError((Object _) => null) case {'mode': final String name}) {
      _mode = StorageMode.values.asNameMap()[name];
    }
  }

  Future<void> set(StorageMode? mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _changes.add(mode);
    await _store.write({'mode': mode?.name}).catchError((Object _) {});
  }
}
