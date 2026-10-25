import 'package:equatable/equatable.dart';

/// Wie ein Konto gesichert ist.
enum AuthProvider { apple, email }

/// Das angemeldete Konto.
class AccountInfo extends Equatable {
  const AccountInfo({required this.userId, this.isAnonymous = true, this.email, this.displayName = '', this.providers = const {}});

  /// `null` = nicht angemeldet (Speicherort „Lokal“ braucht kein Konto).
  final String? userId;

  /// Anonymes Konto aus der Testphase (nur auf diesem Gerät). Neue Konten sind nie anonym.
  final bool isAnonymous;
  final String? email;

  /// Name, den Mitglieder geteilter Kategorien sehen.
  final String displayName;
  final Set<AuthProvider> providers;

  AccountInfo copyWith({bool? isAnonymous, String? email, String? displayName, Set<AuthProvider>? providers}) => AccountInfo(
    userId: userId,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    providers: providers ?? this.providers,
  );

  bool get isSignedIn => userId != null;

  /// Angemeldet mit Apple oder E-Mail – das Konto taugt für die Cloud.
  bool get isRegistered => isSignedIn && !isAnonymous;

  @override
  List<Object?> get props => [userId, isAnonymous, email, displayName, providers];
}

/// Eingaben prüfen, bevor sie zum Server gehen (Formular und Repository).
abstract final class AuthInput {
  /// Längste erlaubte Adresse (RFC 5321).
  static const maxEmailLength = 254;
  static const codeLength = 6;
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _code = RegExp(r'^\d{6}$');

  static bool isEmail(String value) => value.length <= maxEmailLength && _email.hasMatch(value);

  static bool isCode(String value) => _code.hasMatch(value);
}

enum AuthFailureKind { canceled, alreadyUsed, invalidCode, unavailable, network, rateLimited, notSignedIn, unknown }

class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Anmeldung für die Cloud: Registrieren und Anmelden mit Apple oder E-Mail-Code, ohne Passwort.
/// Lokal braucht kein Konto. Ein anonymes Konto aus der Testphase wird beim Registrieren verknüpft
/// – dieselbe Nutzer-Id, alle Daten bleiben.
abstract interface class AuthRepository {
  /// Wirft [AuthFailureKind.notSignedIn] ohne Sitzung. Legt nie ein anonymes Konto an.
  Future<void> ensureSignedIn();

  String? get userId;

  AccountInfo get account;

  /// Lädt Name und Stand vom Server.
  Future<AccountInfo> loadAccount();

  Stream<AccountInfo> get accountChanges;

  /// „Mit Apple anmelden“ gibt es (iOS, macOS).
  Future<bool> appleAvailable();

  /// Anonymes Konto mit Apple sichern. [AuthFailureKind.alreadyUsed], wenn die Apple-ID schon zu
  /// einem anderen Konto gehört – dann [signInWithApple].
  Future<void> linkApple();

  /// Mit Apple registrieren oder anmelden (neue Apple-ID = neues Konto).
  Future<void> signInWithApple();

  /// Code an [email] schicken: [link] sichert das aktuelle anonyme Konto, [create] legt ein neues an
  /// (Registrieren), sonst Anmeldung in ein bestehendes. Beim Anmelden verrät die Antwort nicht, ob
  /// es die Adresse gibt.
  Future<void> requestEmailCode(String email, {required bool link, bool create = false});

  Future<void> verifyEmailCode(String email, String code, {required bool link});

  Future<void> setDisplayName(String name);

  /// Abmelden; Sitzung und Cache dieses Kontos verschwinden vom Gerät.
  Future<void> signOut();

  /// Konto mit allen eigenen Cloud-Daten löschen (Edge Function `delete-account`), danach abgemeldet.
  Future<void> deleteAccount();
}
