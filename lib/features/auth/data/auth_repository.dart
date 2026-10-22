import 'package:equatable/equatable.dart';

/// Wie ein Konto gesichert ist.
enum AuthProvider { apple, email }

/// Das angemeldete Konto.
class AccountInfo extends Equatable {
  const AccountInfo({required this.userId, this.isAnonymous = true, this.email, this.displayName = '', this.providers = const {}});

  final String? userId;

  /// Anonym = nur auf diesem Gerät; fürs Teilen und für ein neues Gerät muss es gesichert werden.
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

  @override
  List<Object?> get props => [userId, isAnonymous, email, displayName, providers];
}

enum AuthFailureKind { canceled, alreadyUsed, invalidCode, unavailable, network, unknown }

class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Anmeldung. Zum Start anonym: Jedes Gerät bekommt still ein eigenes Konto, ohne Formular.
/// Gesichert wird es mit Apple oder per E-Mail-Code – dieselbe Nutzer-Id, alle Daten bleiben.
abstract interface class AuthRepository {
  /// Meldet anonym an, falls noch keine Sitzung besteht. Ohne Netz wirft der erste Aufruf.
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

  /// Mit einem bestehenden Konto anmelden; das anonyme Konto dieses Geräts wird verlassen.
  Future<void> signInWithApple();

  /// Code an [email] schicken: [link] sichert das aktuelle Konto, sonst Anmeldung in ein bestehendes.
  Future<void> requestEmailCode(String email, {required bool link});

  Future<void> verifyEmailCode(String email, String code, {required bool link});

  Future<void> setDisplayName(String name);

  /// Abmelden; danach beginnt sofort ein neues anonymes Konto.
  Future<void> signOut();

  /// Konto mit allen eigenen Daten löschen (Edge Function `delete-account`), danach neu anonym.
  Future<void> deleteAccount();
}
