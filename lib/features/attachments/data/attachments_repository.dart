import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Beleg an einem Eintrag: Foto oder PDF im privaten Bucket `attachments`
/// (Pfad `<category_id>/<entry_id>/<datei>`, siehe Migration `attachments`).
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.entryId,
    required this.path,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    this.createdBy,
  });

  final String id;
  final String entryId;
  final String path;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
  final String? createdBy;

  bool get isPdf => mimeType == AttachmentsRepository.pdf;

  @override
  List<Object?> get props => [id, entryId, path, mimeType, sizeBytes, createdAt, createdBy];
}

enum AttachmentProblem {
  /// Hochladen braucht Kostenkurve Plus (oder Bearbeiten-Rechte in der Kategorie).
  needsPlus,

  /// Größer als [AttachmentsRepository.maxBytes].
  tooLarge,

  /// Speicher von [AttachmentsRepository.quotaBytes] voll.
  quota,

  /// Kein JPEG, PNG, HEIC oder PDF.
  type,

  /// Eintrag liegt noch in der Offline-Warteschlange.
  notSynced,
}

class AttachmentRejected implements Exception {
  const AttachmentRejected(this.problem);

  final AttachmentProblem problem;

  @override
  String toString() => 'AttachmentRejected: ${problem.name}';
}

abstract interface class AttachmentsRepository {
  static const bucket = 'attachments';
  static const maxBytes = 20 * 1024 * 1024;
  static const quotaBytes = 5 * 1024 * 1024 * 1024;
  static const pdf = 'application/pdf';

  /// Erlaubte Typen (wie `allowed_mime_types` des Buckets) mit Dateiendung.
  static const types = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/heic': 'heic', pdf: 'pdf'};

  /// Typ aus der Dateiendung, `null` wenn er nicht erlaubt ist.
  static String? mimeOf(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'jpeg') return 'image/jpeg';
    for (final MapEntry(:key, :value) in types.entries) {
      if (value == ext) return key;
    }
    return null;
  }

  /// Wirft [AttachmentRejected], wenn die Datei nicht hochgeladen werden darf.
  static void check({required int size, required String mimeType, required int used}) {
    if (!types.containsKey(mimeType)) throw const AttachmentRejected(AttachmentProblem.type);
    if (size > maxBytes) throw const AttachmentRejected(AttachmentProblem.tooLarge);
    if (used + size > quotaBytes) throw const AttachmentRejected(AttachmentProblem.quota);
  }

  /// Belege eines Eintrags, älteste zuerst.
  Future<List<Attachment>> list(String entryId);

  Future<Attachment> add({required String categoryId, required String entryId, required Uint8List bytes, required String mimeType});

  /// Inhalt laden (mit Cache für die laufende Sitzung).
  Future<Uint8List> bytes(Attachment attachment);

  Future<void> delete(Attachment attachment);

  /// Belegter Speicher meiner hochgeladenen Belege in Byte.
  Future<int> usage();
}
