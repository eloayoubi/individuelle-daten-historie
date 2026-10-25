import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

/// Supabase Auth: Registrieren und Anmelden mit Apple (ID-Token + Nonce) oder E-Mail-Code, ohne
/// Passwort. Ein anonymes Konto aus der Testphase wird verknüpft (`linkIdentityWithIdToken`,
/// `updateUser(email)`): Die Nutzer-Id bleibt, alle Daten bleiben.
///
/// Im Dashboard nötig: Apple-Provider (Bundle-ID als Client-ID) und in den Mail-Vorlagen „Confirm
/// signup“, „Magic Link“ und „Change Email Address“ der Code `{{ .Token }}`. Codes, Tokens und
/// Adressen werden nie geloggt.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  String _displayName = '';

  GoTrueClient get _auth => _client.auth;

  @override
  Future<void> ensureSignedIn() async {
    if (_auth.currentSession == null) throw const AuthFailure(AuthFailureKind.notSignedIn);
  }

  @override
  String? get userId => _auth.currentUser?.id;

  @override
  AccountInfo get account {
    final user = _auth.currentUser;
    final providers = {
      for (final identity in user?.identities ?? const <UserIdentity>[])
        if (identity.provider == 'apple') AuthProvider.apple else if (identity.provider == 'email') AuthProvider.email,
    };
    return AccountInfo(
      userId: user?.id,
      isAnonymous: user == null || user.isAnonymous,
      email: user?.email?.isEmpty ?? true ? null : user!.email,
      displayName: _displayName,
      providers: providers,
    );
  }

  @override
  Future<AccountInfo> loadAccount() async {
    if (userId == null) return account;
    final row = await _client.from('profiles').select('display_name').eq('id', userId!).maybeSingle();
    _displayName = (row?['display_name'] as String?) ?? '';
    return account;
  }

  @override
  Stream<AccountInfo> get accountChanges => _auth.onAuthStateChange.map((_) => account);

  @override
  Future<bool> appleAvailable() async => (Platform.isIOS || Platform.isMacOS) && await SignInWithApple.isAvailable();

  @override
  Future<void> linkApple() => _guard(() async {
    final apple = await _appleToken();
    await _auth.linkIdentityWithIdToken(provider: OAuthProvider.apple, idToken: apple.token, nonce: apple.nonce);
    _storeAppleCode(apple.code);
    if (_displayName.isEmpty && apple.givenName != null) await setDisplayName(apple.givenName!);
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    final apple = await _appleToken();
    await _auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: apple.token, nonce: apple.nonce);
    _storeAppleCode(apple.code);
    await loadAccount();
  });

  /// Der Server tauscht den einmaligen Code gegen Apples Refresh-Token, um ihn beim Löschen des
  /// Kontos zu widerrufen (App-Store-Regel 5.1.1(v)). Nebenbei – Anmelden klappt auch ohne.
  void _storeAppleCode(String code) {
    if (code.isEmpty) return;
    _client.functions.invoke('apple-token', body: {'code': code}).then((_) {}, onError: (Object _) {});
  }

  @override
  Future<void> requestEmailCode(String email, {required bool link, bool create = false}) => _guard(() async {
    final address = email.trim();
    if (!AuthInput.isEmail(address)) throw const AuthFailure(AuthFailureKind.unknown);
    if (link) {
      await _auth.updateUser(UserAttributes(email: address));
    } else if (create) {
      await _auth.signInWithOtp(email: address, shouldCreateUser: true);
    } else {
      try {
        await _auth.signInWithOtp(email: address, shouldCreateUser: false);
      } on AuthException catch (e) {
        // Unbekannte Adresse: genauso antworten wie bei einer bekannten (keine Konto-Aufzählung).
        // Der Code-Schritt erscheint, ein Code kommt nie an.
        if (e.code != 'otp_disabled' && e.code != 'user_not_found') rethrow;
      }
    }
  });

  @override
  Future<void> verifyEmailCode(String email, String code, {required bool link}) => _guard(() async {
    final token = code.trim();
    if (!AuthInput.isCode(token)) throw const AuthFailure(AuthFailureKind.invalidCode);
    await _auth.verifyOTP(email: email.trim(), token: token, type: link ? OtpType.emailChange : OtpType.email);
    await loadAccount();
  });

  @override
  Future<void> setDisplayName(String name) => _guard(() async {
    await ensureSignedIn();
    await _client.from('profiles').update({'display_name': name.trim()}).eq('id', userId!);
    _displayName = name.trim();
  });

  @override
  Future<void> signOut() => _guard(() async {
    try {
      await _auth.signOut();
    } on AuthException {
      // Ohne Netz: wenigstens auf dem Gerät abmelden.
      await _auth.signOut(scope: SignOutScope.local);
    }
    _displayName = '';
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    await ensureSignedIn();
    await _client.functions.invoke('delete-account');
    await _auth.signOut(scope: SignOutScope.local);
    _displayName = '';
  });

  /// Apple-ID-Token mit Nonce (SHA-256 an Apple, Klartext an Supabase), Autorisierungscode und
  /// Vorname, falls geteilt.
  Future<({String token, String nonce, String code, String? givenName})> _appleToken() async {
    final raw = _nonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: sha256.convert(utf8.encode(raw)).toString(),
    );
    final token = credential.identityToken;
    if (token == null) throw const AuthFailure(AuthFailureKind.unknown);
    return (token: token, nonce: raw, code: credential.authorizationCode, givenName: credential.givenName);
  }

  static String _nonce() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  /// Fehler der Anbieter auf [AuthFailure] abbilden.
  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AuthFailure(e.code == AuthorizationErrorCode.canceled ? AuthFailureKind.canceled : AuthFailureKind.unknown);
    } on AuthException catch (e) {
      final code = e.code ?? '';
      throw AuthFailure(switch (code) {
        'identity_already_exists' || 'email_exists' || 'user_already_exists' => AuthFailureKind.alreadyUsed,
        'otp_expired' || 'invalid_credentials' => AuthFailureKind.invalidCode,
        'otp_disabled' || 'provider_disabled' || 'email_provider_disabled' => AuthFailureKind.unavailable,
        'over_email_send_rate_limit' || 'over_request_rate_limit' => AuthFailureKind.rateLimited,
        _ when e.statusCode == '429' => AuthFailureKind.rateLimited,
        _ when e.statusCode == '403' => AuthFailureKind.invalidCode,
        _ => AuthFailureKind.unknown,
      });
    } on SocketException {
      throw const AuthFailure(AuthFailureKind.network);
    } on FunctionException {
      throw const AuthFailure(AuthFailureKind.unknown);
    }
  }
}
