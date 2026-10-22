part of 'account_cubit.dart';

enum AccountEventKind { secured, signedIn, codeSent, nameSaved, signedOut, deleted, alreadyUsed, invalidCode, canceled, failed }

/// Einmaliges Ereignis für Toasts und Folgeschritte. Bewusst nicht `const`.
class AccountEvent {
  AccountEvent(this.kind);

  factory AccountEvent.failure(AuthFailureKind failure) => AccountEvent(switch (failure) {
    AuthFailureKind.alreadyUsed => AccountEventKind.alreadyUsed,
    AuthFailureKind.invalidCode => AccountEventKind.invalidCode,
    AuthFailureKind.canceled => AccountEventKind.canceled,
    _ => AccountEventKind.failed,
  });

  final AccountEventKind kind;
}

class AccountState extends Equatable {
  const AccountState({required this.account, this.appleAvailable = false, this.busy = false, this.event});

  final AccountInfo account;
  final bool appleAvailable;
  final bool busy;
  final AccountEvent? event;

  AccountState copyWith({AccountInfo? account, bool? appleAvailable, bool? busy, AccountEvent? event}) => AccountState(
    account: account ?? this.account,
    appleAvailable: appleAvailable ?? this.appleAvailable,
    busy: busy ?? this.busy,
    event: event,
  );

  @override
  List<Object?> get props => [account, appleAvailable, busy, event];
}
