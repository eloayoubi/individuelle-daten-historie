/// Anmeldung. Zum Start anonym: Jedes Gerät bekommt still ein eigenes Konto, ohne Formular.
/// Später lässt es sich mit E-Mail oder Apple/Google sichern (nötig fürs Teilen).
abstract interface class AuthRepository {
  /// Meldet anonym an, falls noch keine Sitzung besteht. Ohne Netz wirft der erste Aufruf.
  Future<void> ensureSignedIn();

  String? get userId;
}
