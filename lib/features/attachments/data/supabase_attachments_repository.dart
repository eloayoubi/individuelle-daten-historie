import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException, StorageException;

import '../../../core/network/supabase_api.dart';
import '../../../core/utils/ids.dart';
import '../../auth/data/auth_repository.dart';
import 'attachments_repository.dart';

/// Belege in Supabase: Datei in den privaten Bucket, dann die Zeile in `attachments`. RLS lässt
/// beides nur mit Plus und Bearbeiten-Rechten zu; lesen dürfen alle Mitglieder der Kategorie.
class SupabaseAttachmentsRepository implements AttachmentsRepository {
  SupabaseAttachmentsRepository(this._api, this._auth);

  final SupabaseApi _api;
  final AuthRepository _auth;
  final _cache = <String, Uint8List>{};

  static const _columns = 'id, entry_id, storage_path, mime_type, size_bytes, created_by, created_at';

  @override
  Future<List<Attachment>> list(String entryId) async {
    await _auth.ensureSignedIn();
    final rows = await _api.table('attachments').select(_columns).eq('entry_id', entryId).order('created_at');
    return [for (final row in rows) _attachment(row)];
  }

  @override
  Future<Attachment> add({required String categoryId, required String entryId, required Uint8List bytes, required String mimeType}) async {
    await _auth.ensureSignedIn();
    AttachmentsRepository.check(size: bytes.length, mimeType: mimeType, used: await usage());
    final id = newId();
    final path = '$categoryId/$entryId/$id.${AttachmentsRepository.types[mimeType]}';
    try {
      await _api.upload(AttachmentsRepository.bucket, path, bytes, contentType: mimeType);
    } on StorageException catch (e) {
      throw switch (e.statusCode) {
        '403' || '401' => const AttachmentRejected(AttachmentProblem.needsPlus),
        '413' => const AttachmentRejected(AttachmentProblem.tooLarge),
        _ => e,
      };
    }
    try {
      final row = await _api
          .table('attachments')
          .insert({'id': id, 'entry_id': entryId, 'storage_path': path, 'mime_type': mimeType, 'size_bytes': bytes.length})
          .select(_columns)
          .single();
      _cache[id] = bytes;
      return _attachment(row);
    } catch (e) {
      // Ohne Zeile wäre die Datei verwaist.
      await _api.remove(AttachmentsRepository.bucket, [path]).catchError((Object _) {});
      if (e is PostgrestException) {
        // 23503: Eintrag ist noch nicht beim Server; 42501: RLS (kein Plus, keine Rechte).
        if (e.code == '23503') throw const AttachmentRejected(AttachmentProblem.notSynced);
        if (e.code == '42501') throw const AttachmentRejected(AttachmentProblem.needsPlus);
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> bytes(Attachment attachment) async =>
      _cache[attachment.id] ??= await _api.download(AttachmentsRepository.bucket, attachment.path);

  @override
  Future<void> delete(Attachment attachment) async {
    await _auth.ensureSignedIn();
    await _api.table('attachments').delete().eq('id', attachment.id);
    await _api.remove(AttachmentsRepository.bucket, [attachment.path]);
    _cache.remove(attachment.id);
  }

  @override
  Future<int> usage() async {
    await _auth.ensureSignedIn();
    final rows = await _api.table('attachments').select('size_bytes').eq('created_by', _auth.userId!);
    return rows.fold<int>(0, (sum, row) => sum + (row['size_bytes'] as num).toInt());
  }

  static Attachment _attachment(Map<String, dynamic> row) => Attachment(
    id: row['id'] as String,
    entryId: row['entry_id'] as String,
    path: row['storage_path'] as String,
    mimeType: row['mime_type'] as String,
    sizeBytes: (row['size_bytes'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
    createdBy: row['created_by'] as String?,
  );
}
