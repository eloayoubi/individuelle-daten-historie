import '../../../core/network/supabase_api.dart';
import 'app_release.dart';

/// Neuester Build aus `app_releases` – lesbar auch ohne Konto (Speicherort „Lokal“). Die Zeile setzt
/// `fastlane beta`, sobald ein Build bei den Testern ist.
class SupabaseReleaseRepository implements ReleaseRepository {
  const SupabaseReleaseRepository(this._api);

  final SupabaseApi _api;

  @override
  Future<AppRelease?> latest(ReleaseChannel channel) async {
    final row = await _api.table('app_releases').select('build, url').eq('channel', channel.key).maybeSingle();
    if (row == null) return null;
    return AppRelease(build: row['build'] as int, url: row['url'] as String?);
  }
}
