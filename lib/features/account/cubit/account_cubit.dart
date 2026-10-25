import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_repository.dart';

part 'account_state.dart';

/// Registrieren und anmelden (Apple, E-Mail-Code), anonymes Testkonto sichern, Namen setzen,
/// abmelden, löschen.
/// Liegt über dem `MaterialApp`: Einstellungen und Teilen brauchen denselben Stand.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._auth) : super(AccountState(account: _auth.account)) {
    _subscription = _auth.accountChanges.listen((account) {
      if (!isClosed) emit(state.copyWith(account: account.copyWith(displayName: account.displayName.isEmpty ? state.account.displayName : null)));
    });
  }

  final AuthRepository _auth;
  late final StreamSubscription<AccountInfo> _subscription;

  Future<void> load() async {
    final apple = await _auth.appleAvailable().catchError((Object _) => false);
    try {
      final account = await _auth.loadAccount();
      if (!isClosed) emit(state.copyWith(account: account, appleAvailable: apple));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(appleAvailable: apple));
    }
  }

  /// Anonymes Konto mit Apple sichern. Gehört die Apple-ID schon zu einem Konto, meldet das
  /// Ereignis [AccountEventKind.alreadyUsed] – dann kann der Nutzer sich dort anmelden.
  Future<void> linkApple() => _run(_auth.linkApple, success: AccountEventKind.secured);

  Future<void> signInWithApple() => _run(_auth.signInWithApple, success: AccountEventKind.signedIn);

  /// [create] legt ein neues Konto an (Registrieren), [link] sichert das anonyme Testkonto.
  Future<void> requestEmailCode(String email, {required bool link, bool create = false}) =>
      _run(() => _auth.requestEmailCode(email, link: link, create: create), success: AccountEventKind.codeSent);

  Future<void> verifyEmailCode(String email, String code, {required bool link}) =>
      _run(() => _auth.verifyEmailCode(email, code, link: link), success: link ? AccountEventKind.secured : AccountEventKind.signedIn);

  Future<void> setDisplayName(String name) => _run(() => _auth.setDisplayName(name), success: AccountEventKind.nameSaved);

  Future<void> signOut() => _run(_auth.signOut, success: AccountEventKind.signedOut);

  Future<void> deleteAccount() => _run(_auth.deleteAccount, success: AccountEventKind.deleted);

  Future<void> _run(Future<void> Function() action, {required AccountEventKind success}) async {
    emit(state.copyWith(busy: true));
    try {
      await action();
      if (isClosed) return;
      emit(state.copyWith(busy: false, account: _auth.account, event: AccountEvent(success)));
    } on AuthFailure catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false, event: AccountEvent.failure(e.kind)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(busy: false, event: AccountEvent.failure(AuthFailureKind.unknown)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
