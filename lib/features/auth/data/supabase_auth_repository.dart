import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

/// Anonyme Anmeldung über Supabase Auth („Anonymous Sign-Ins“ im Dashboard aktivieren).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  Future<void>? _pending;

  @override
  Future<void> ensureSignedIn() {
    if (_client.auth.currentSession != null) return Future.value();
    // Mehrere Repositories fragen gleichzeitig: nur eine Anmeldung starten.
    return _pending ??= _client.auth.signInAnonymously().then((_) {}).whenComplete(() => _pending = null);
  }

  @override
  String? get userId => _client.auth.currentUser?.id;
}
