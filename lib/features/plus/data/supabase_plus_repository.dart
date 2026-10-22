import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../../../core/network/supabase_api.dart';
import '../../auth/data/auth_repository.dart';
import 'plus_repository.dart';

/// Abo-Stand aus `entitlements` (RLS: nur der eigene), Kaufprüfung über `verify-purchase`.
class SupabasePlusRepository implements PlusRepository {
  SupabasePlusRepository(this._api, this._auth);

  final SupabaseApi _api;
  final AuthRepository _auth;

  @override
  Future<PlusStatus> status() async {
    await _auth.ensureSignedIn();
    final row = await _api.table('entitlements').select('tier, valid_until').eq('user_id', _auth.userId!).maybeSingle();
    if (row == null) return const PlusStatus();
    final until = switch (row['valid_until']) {
      final String iso => DateTime.parse(iso),
      _ => null,
    };
    return PlusStatus(active: row['tier'] == 'plus' && (until == null || until.isAfter(DateTime.now())), validUntil: until);
  }

  @override
  Future<PlusStatus> redeem(String jws) async {
    await _auth.ensureSignedIn();
    final Map<String, dynamic> res;
    try {
      res = await _api.invoke('verify-purchase', body: {'jws': jws});
    } on FunctionException catch (e) {
      if (e.status >= 400 && e.status < 500) {
        throw PlusRejected(switch (e.details) {
          {'error': final String code} => code,
          _ => '${e.status}',
        });
      }
      rethrow;
    }
    return PlusStatus(
      active: res['plus'] == true,
      validUntil: switch (res['valid_until']) {
        final String iso => DateTime.parse(iso),
        _ => null,
      },
    );
  }
}
