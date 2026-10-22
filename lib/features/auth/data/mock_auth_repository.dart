import 'dart:async';

import 'auth_repository.dart';

/// Für Mock-Modus und Tests: Beispielnutzer, zuerst anonym. Der E-Mail-Code ist immer [demoCode].
class MockAuthRepository implements AuthRepository {
  static const demoUserId = '00000000-0000-4000-8000-000000000001';
  static const demoCode = '123456';

  var _account = const AccountInfo(userId: demoUserId);
  final _changes = StreamController<AccountInfo>.broadcast();

  @override
  Future<void> ensureSignedIn() async {}

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

  @override
  Future<bool> appleAvailable() async => true;

  @override
  Future<void> linkApple() async => _set(_account.copyWith(isAnonymous: false, providers: {..._account.providers, AuthProvider.apple}));

  @override
  Future<void> signInWithApple() => linkApple();

  @override
  Future<void> requestEmailCode(String email, {required bool link}) async {
    if (!email.contains('@')) throw const AuthFailure(AuthFailureKind.unknown);
  }

  @override
  Future<void> verifyEmailCode(String email, String code, {required bool link}) async {
    if (code.trim() != demoCode) throw const AuthFailure(AuthFailureKind.invalidCode);
    _set(_account.copyWith(isAnonymous: false, email: email.trim(), providers: {..._account.providers, AuthProvider.email}));
  }

  @override
  Future<void> setDisplayName(String name) async => _set(_account.copyWith(displayName: name.trim()));

  @override
  Future<void> signOut() async => _set(const AccountInfo(userId: demoUserId));

  @override
  Future<void> deleteAccount() => signOut();
}
