import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/attachments_repository.dart';

part 'attachments_state.dart';

/// Wofür die Belege geladen werden.
class AttachmentsArgs extends Equatable {
  const AttachmentsArgs({required this.categoryId, required this.entryId});

  final String categoryId;
  final String entryId;

  @override
  List<Object?> get props => [categoryId, entryId];
}

/// Belege eines Eintrags: anzeigen, hinzufügen (Foto, PDF), löschen.
class AttachmentsCubit extends Cubit<AttachmentsState> {
  AttachmentsCubit(this._repository, this.args) : super(const AttachmentsState());

  final AttachmentsRepository _repository;
  final AttachmentsArgs args;

  Future<void> load() async {
    try {
      final items = await _repository.list(args.entryId);
      if (!isClosed) emit(state.copyWith(items: items, loaded: true));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loaded: true, failed: true));
    }
  }

  Future<void> add(Uint8List bytes, String mimeType) async {
    emit(state.copyWith(uploading: true));
    try {
      final added = await _repository.add(categoryId: args.categoryId, entryId: args.entryId, bytes: bytes, mimeType: mimeType);
      if (!isClosed) emit(state.copyWith(items: [...state.items, added], uploading: false, event: AttachmentsEvent(AttachmentsEventKind.added)));
    } on AttachmentRejected catch (e) {
      if (!isClosed) emit(state.copyWith(uploading: false, event: AttachmentsEvent(AttachmentsEventKind.rejected, problem: e.problem)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(uploading: false, event: AttachmentsEvent(AttachmentsEventKind.failed)));
    }
  }

  Future<void> delete(Attachment attachment) async {
    try {
      await _repository.delete(attachment);
      if (!isClosed) {
        emit(state.copyWith(items: [for (final a in state.items) if (a.id != attachment.id) a], event: AttachmentsEvent(AttachmentsEventKind.deleted)));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(event: AttachmentsEvent(AttachmentsEventKind.failed)));
    }
  }
}
