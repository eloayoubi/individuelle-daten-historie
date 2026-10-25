import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/json_store.dart';

/// Supabase-Sitzung (Access- und Refresh-Token) im iOS-Schlüsselbund bzw. im Android Keystore statt
/// in NSUserDefaults/SharedPreferences (OWASP MASVS-STORAGE-1): nur auf diesem Gerät, lesbar nach
/// dem ersten Entsperren (das Token erneuert sich auch im Hintergrund), nie per iCloud synchronisiert.
///
/// Eine Sitzung aus älteren Versionen (SharedPreferences) wird einmal übernommen und dort gelöscht.
/// Der Schlüsselbund übersteht eine Neuinstallation: Fehlt die Markierung [installMarker], gilt die
/// App als neu installiert und eine alte Sitzung im Schlüsselbund wird verworfen.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.key, required this.installMarker, FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  /// Schlüssel wie bei Supabase: `sb-<projekt-ref>-auth-token`.
  final String key;
  final JsonStore installMarker;
  final FlutterSecureStorage _storage;

  static const _ios = IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device);
  static const _android = AndroidOptions();

  /// Schlüssel für eine Supabase-URL, z. B. `https://abc.supabase.co` → `sb-abc-auth-token`.
  static String keyFor(String url) => 'sb-${Uri.parse(url).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    if (await installMarker.read() == null) {
      await _delete();
      await installMarker.write({'installed': true}).catchError((Object _) {});
    }
    final legacy = SharedPreferencesLocalStorage(persistSessionKey: key);
    await legacy.initialize();
    if (await legacy.accessToken() case final session?) {
      await persistSession(session);
      await legacy.removePersistedSession();
    }
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: key, iOptions: _ios, aOptions: _android);
    } catch (_) {
      // Unlesbar (z. B. Keystore nach einem Geräte-Wechsel): wie abgemeldet.
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() => _delete();

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(key: key, value: persistSessionString, iOptions: _ios, aOptions: _android);

  Future<void> _delete() async {
    try {
      await _storage.delete(key: key, iOptions: _ios, aOptions: _android);
    } catch (_) {
      // Nichts gespeichert oder nicht lesbar – beides heißt abgemeldet.
    }
  }
}
