import 'dart:typed_data';

import '../../../core/utils/ids.dart';
import 'attachments_repository.dart';

/// Ohne Backend: Belege nur im Speicher der laufenden App.
class MockAttachmentsRepository implements AttachmentsRepository {
  final _attachments = <Attachment>[];
  final _bytes = <String, Uint8List>{};

  @override
  Future<List<Attachment>> list(String entryId) async => [for (final a in _attachments) if (a.entryId == entryId) a];

  @override
  Future<Attachment> add({required String categoryId, required String entryId, required Uint8List bytes, required String mimeType}) async {
    AttachmentsRepository.check(size: bytes.length, mimeType: mimeType, used: await usage());
    final id = newId();
    final attachment = Attachment(
      id: id,
      entryId: entryId,
      path: '$categoryId/$entryId/$id.${AttachmentsRepository.types[mimeType]}',
      mimeType: mimeType,
      sizeBytes: bytes.length,
      createdAt: DateTime.now(),
    );
    _attachments.add(attachment);
    _bytes[id] = bytes;
    return attachment;
  }

  @override
  Future<Uint8List> bytes(Attachment attachment) async => _bytes[attachment.id] ?? Uint8List(0);

  @override
  Future<void> delete(Attachment attachment) async {
    _attachments.removeWhere((a) => a.id == attachment.id);
    _bytes.remove(attachment.id);
  }

  @override
  Future<int> usage() async => _attachments.fold<int>(0, (sum, a) => sum + a.sizeBytes);
}
