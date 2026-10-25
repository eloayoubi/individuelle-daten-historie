import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/account/cubit/account_cubit.dart';
import 'package:kostenkurve/features/auth/data/auth_repository.dart';
import 'package:kostenkurve/features/auth/data/mock_auth_repository.dart';

void main() {
  late MockAuthRepository auth;
  // Anonymes Konto aus der Testphase; neue Installationen starten abgemeldet (siehe unten).
  setUp(() => auth = MockAuthRepository(initial: MockAuthRepository.anonymous));

  test('neue Installation: abgemeldet, ohne Konto', () async {
    final cubit = AccountCubit(MockAuthRepository());
    await cubit.load();
    expect(cubit.state.account.isSignedIn, isFalse);
    expect(cubit.state.account.isRegistered, isFalse);
    expect(cubit.state.appleAvailable, isTrue);
    await cubit.close();
  });

  test('registrieren per E-Mail-Code: neues Konto, kein anonymes', () async {
    final cubit = AccountCubit(MockAuthRepository());
    await cubit.requestEmailCode('elias@example.com', link: false, create: true);
    expect(cubit.state.event?.kind, AccountEventKind.codeSent);
    await cubit.verifyEmailCode('elias@example.com', MockAuthRepository.demoCode, link: false);
    expect(cubit.state.event?.kind, AccountEventKind.signedIn);
    expect(cubit.state.account.isRegistered, isTrue);
    expect(cubit.state.account.email, 'elias@example.com');
    await cubit.close();
  });

  test('anonymes Testkonto startet anonym', () async {
    final cubit = AccountCubit(auth);
    await cubit.load();
    expect(cubit.state.account.isAnonymous, isTrue);
    expect(cubit.state.account.isSignedIn, isTrue);
    await cubit.close();
  });

  test('mit Apple sichern: gesichert, gleiche Nutzer-Id', () async {
    final cubit = AccountCubit(auth);
    await cubit.linkApple();
    expect(cubit.state.event?.kind, AccountEventKind.secured);
    expect(cubit.state.account.isAnonymous, isFalse);
    expect(cubit.state.account.providers, contains(AuthProvider.apple));
    expect(cubit.state.account.userId, MockAuthRepository.demoUserId);
    await cubit.close();
  });

  test('E-Mail: Code senden, falscher Code, richtiger Code', () async {
    final cubit = AccountCubit(auth);
    await cubit.requestEmailCode('elias@example.com', link: true);
    expect(cubit.state.event?.kind, AccountEventKind.codeSent);
    await cubit.verifyEmailCode('elias@example.com', '000000', link: true);
    expect(cubit.state.event?.kind, AccountEventKind.invalidCode);
    expect(cubit.state.account.isAnonymous, isTrue);
    await cubit.verifyEmailCode('elias@example.com', MockAuthRepository.demoCode, link: true);
    expect(cubit.state.event?.kind, AccountEventKind.secured);
    expect(cubit.state.account.email, 'elias@example.com');
    await cubit.close();
  });

  test('Name speichern, abmelden, löschen', () async {
    final cubit = AccountCubit(auth);
    await cubit.setDisplayName('  Elias ');
    expect(cubit.state.event?.kind, AccountEventKind.nameSaved);
    expect(cubit.state.account.displayName, 'Elias');
    await cubit.linkApple();
    await cubit.signOut();
    expect(cubit.state.event?.kind, AccountEventKind.signedOut);
    expect(cubit.state.account.isSignedIn, isFalse);
    await cubit.deleteAccount();
    expect(cubit.state.event?.kind, AccountEventKind.deleted);
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });
}
