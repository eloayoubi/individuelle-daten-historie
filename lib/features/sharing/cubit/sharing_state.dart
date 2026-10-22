part of 'sharing_cubit.dart';

enum SharingEventKind { removed, left, failed }

/// Einmaliges Ereignis. Bewusst nicht `const`.
class SharingEvent {
  SharingEvent(this.kind);

  final SharingEventKind kind;
}

class SharingState extends Equatable {
  const SharingState({this.loaded = false, this.category, this.inviteRole = MemberRole.editor, this.inviteCode, this.busy = false, this.event});

  final bool loaded;
  final Category? category;

  /// Rolle für die nächste Einladung.
  final MemberRole inviteRole;

  /// Zuletzt erzeugter Code (gilt 7 Tage, einmal).
  final String? inviteCode;
  final bool busy;
  final SharingEvent? event;

  SharingState copyWith({bool? loaded, Category? category, MemberRole? inviteRole, String? inviteCode, bool clearCode = false, bool? busy, SharingEvent? event}) =>
      SharingState(
        loaded: loaded ?? this.loaded,
        category: category ?? this.category,
        inviteRole: inviteRole ?? this.inviteRole,
        inviteCode: clearCode ? null : inviteCode ?? this.inviteCode,
        busy: busy ?? this.busy,
        event: event,
      );

  @override
  List<Object?> get props => [loaded, category, inviteRole, inviteCode, busy, event];
}
