import 'dart:async';

import 'auth_repository.dart';

/// Für Mock-Modus und Tests: startet abgemeldet (wie eine neue Installation). Registrieren und
/// Anmelden führen ins Beispielkonto [demoUserId]; der E-Mail-Code ist immer [demoCode].
/// [initial] stellt z. B. ein anonymes Konto aus der Testphase nach.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({AccountInfo initial = signedOut}) : _account = initial;

  static const demoUserId = '00000000-0000-4000-8000-000000000001';
  static const demoCode = '123456';
  static const signedOut = AccountInfo(userId: null);

  /// Anonymes Konto aus der Testphase.
  static const anonymous = AccountInfo(userId: demoUserId);

  AccountInfo _account;
  final _changes = StreamController<AccountInfo>.broadcast();

  @override
  Future<void> ensureSignedIn() async {
    if (_account.userId == null) throw const AuthFailure(AuthFailureKind.notSignedIn);
  }

  @override
  String? get userId => _account.userId;

  @override
  AccountInfo get account => _account;

  @override
  Future<AccountInfo> loadAccount() async => _account;

  @override
  Stream<AccountInfo> get accountChanges => _changes.stream;

  void _set(AccountInfo account) {
    _account = account;
    _changes.add(account);
  }

  AccountInfo _registered({String? email, required AuthProvider provider}) => AccountInfo(
    userId: demoUserId,
    isAnonymous: false,
    email: email ?? _account.email,
    displayName: _account.displayName,
    providers: {..._account.providers, provider},
  );

  @override
  Future<bool> appleAvailable() async => true;

  @override
  Future<void> linkApple() async => _set(_registered(provider: AuthProvider.apple));

  @override
  Future<void> signInWithApple() async => _set(_registered(provider: AuthProvider.apple));

  @override
  Future<void> requestEmailCode(String email, {required bool link, bool create = false}) async {
    if (!email.contains('@')) throw const AuthFailure(AuthFailureKind.unknown);
  }

  @override
  Future<void> verifyEmailCode(String email, String code, {required bool link}) async {
    if (code.trim() != demoCode) throw const AuthFailure(AuthFailureKind.invalidCode);
    _set(_registered(email: email.trim(), provider: AuthProvider.email));
  }

  @override
  Future<void> setDisplayName(String name) async => _set(_account.copyWith(displayName: name.trim()));

  @override
  Future<void> signOut() async => _set(signedOut);

  @override
  Future<void> deleteAccount() => signOut();
}
