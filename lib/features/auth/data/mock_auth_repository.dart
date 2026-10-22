import 'auth_repository.dart';

/// Für Mock-Modus und Tests: immer angemeldet als Beispielnutzer.
class MockAuthRepository implements AuthRepository {
  static const demoUserId = '00000000-0000-4000-8000-000000000001';

  @override
  Future<void> ensureSignedIn() async {}

  @override
  String? get userId => demoUserId;
}
