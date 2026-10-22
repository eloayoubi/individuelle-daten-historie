/// Build-Konfiguration über `--dart-define` (Werte stehen in `.env.local`, nie im Repo).
///
/// ```sh
/// flutter run --dart-define-from-file=.env.local
/// ```
/// Ohne diese Werte läuft die App komplett mit Mock-Repositories (Beispieldaten aus dem Design).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Eigenes URL-Schema für Rücksprünge (Einladungslinks, Mail-Bestätigung).
  static const appScheme = 'de.eloayoubi.kostenkurve';
  static const authRedirect = '$appScheme://login-callback';

  /// Apples Standard-Nutzungsvertrag (EULA) für Abos – Link auf der Abo-Seite.
  static const appleEulaUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Abos verwalten und kündigen (App Store).
  static const manageSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';
}
