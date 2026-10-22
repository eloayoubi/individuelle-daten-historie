import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../categories/data/categories_repository.dart';

part 'sharing_state.dart';

/// Teilen einer Kategorie: Mitglieder sehen, Rollen ändern, entfernen, einladen, verlassen.
class SharingCubit extends Cubit<SharingState> {
  SharingCubit(this._repository, this.categoryId) : super(const SharingState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  final String categoryId;
  late final StreamSubscription<void> _subscription;

  Future<void> load() async {
    try {
      final category = await _repository.loadCategory(categoryId);
      if (!isClosed) emit(state.copyWith(category: category, loaded: true));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loaded: true));
    }
  }

  void setInviteRole(MemberRole role) => emit(state.copyWith(inviteRole: role, clearCode: true));

  Future<void> createInvite() => _run(() async {
    final code = await _repository.createInvite(categoryId, state.inviteRole);
    if (!isClosed) emit(state.copyWith(inviteCode: code));
  });

  Future<void> setRole(CategoryMember member, MemberRole role) => _run(() => _repository.setMemberRole(categoryId, member.userId, role));

  Future<void> remove(CategoryMember member) => _run(() => _repository.removeMember(categoryId, member.userId), success: SharingEventKind.removed);

  Future<void> leave() => _run(() => _repository.leaveCategory(categoryId), success: SharingEventKind.left);

  Future<void> _run(Future<void> Function() action, {SharingEventKind? success}) async {
    emit(state.copyWith(busy: true));
    try {
      await action();
      if (!isClosed) emit(state.copyWith(busy: false, event: success == null ? null : SharingEvent(success)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(busy: false, event: SharingEvent(SharingEventKind.failed)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
