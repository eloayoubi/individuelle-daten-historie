import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Initialisiert Supabase und stellt eine gespeicherte Sitzung wieder her.
abstract final class SupabaseBootstrap {
  static Future<void> init() => Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);

  static SupabaseClient get client => Supabase.instance.client;
}

/// Dünne Hülle um den Supabase-Client, damit Repositories keine Supabase-Typen leaken.
class SupabaseApi {
  const SupabaseApi(this._client);

  final SupabaseClient _client;

  /// Postgres-Funktion aufrufen (`create function … security definer`).
  Future<T> rpc<T>(String fn, {Map<String, dynamic>? params}) async => await _client.rpc(fn, params: params) as T;

  /// Edge Function aufrufen (`supabase/functions/<name>`).
  Future<Map<String, dynamic>> invoke(String function, {Map<String, dynamic>? body}) async {
    final res = await _client.functions.invoke(function, body: body);
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Tabelle lesen oder schreiben – RLS entscheidet, was sichtbar ist.
  SupabaseQueryBuilder table(String name) => _client.from(name);

  /// Realtime-Strom einer Tabelle, gefiltert auf `column = value`.
  Stream<List<Map<String, dynamic>>> stream(String table, {required String column, required Object value, List<String> primaryKey = const ['id']}) =>
      _client.from(table).stream(primaryKey: primaryKey).eq(column, value);

  String? get userId => _client.auth.currentUser?.id;

  /// Änderungen in [tables] (Realtime, RLS filtert); liefert eine Funktion zum Abmelden.
  void Function() onChanges(List<String> tables, void Function() onChange) {
    var channel = _client.channel('kostenkurve-${tables.join('-')}');
    for (final table in tables) {
      channel = channel.onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: table, callback: (_) => onChange());
    }
    channel.subscribe();
    return () => _client.removeChannel(channel);
  }

  /// Datei in einen privaten Bucket laden.
  Future<void> upload(String bucket, String path, Uint8List bytes, {required String contentType}) =>
      _client.storage.from(bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType));

  Future<Uint8List> download(String bucket, String path) => _client.storage.from(bucket).download(path);

  Future<void> remove(String bucket, List<String> paths) => _client.storage.from(bucket).remove(paths);
}
