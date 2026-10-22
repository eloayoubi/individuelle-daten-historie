part of 'attachments_cubit.dart';

enum AttachmentsEventKind { added, deleted, rejected, failed }

/// Einmaliges Ereignis für den Toast. Bewusst nicht `const`.
class AttachmentsEvent {
  AttachmentsEvent(this.kind, {this.problem});

  final AttachmentsEventKind kind;
  final AttachmentProblem? problem;
}

class AttachmentsState extends Equatable {
  const AttachmentsState({this.items = const [], this.loaded = false, this.failed = false, this.uploading = false, this.event});

  final List<Attachment> items;
  final bool loaded;

  /// Laden ging nicht (z. B. offline).
  final bool failed;
  final bool uploading;
  final AttachmentsEvent? event;

  AttachmentsState copyWith({List<Attachment>? items, bool? loaded, bool? failed, bool? uploading, AttachmentsEvent? event}) => AttachmentsState(
    items: items ?? this.items,
    loaded: loaded ?? this.loaded,
    failed: failed ?? this.failed,
    uploading: uploading ?? this.uploading,
    event: event,
  );

  @override
  List<Object?> get props => [items, loaded, failed, uploading, event];
}
