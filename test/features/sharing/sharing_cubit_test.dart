import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';
import 'package:kostenkurve/features/sharing/cubit/sharing_cubit.dart';
import 'package:kostenkurve/features/sharing/data/invite_links.dart';

void main() {
  late MockCategoriesRepository repo;
  setUp(() => repo = MockCategoriesRepository());

  test('lädt Mitglieder, Einladung mit Rolle erstellen', () async {
    final cubit = SharingCubit(repo, 'c-miete');
    await cubit.load();
    expect(cubit.state.category!.sharedWith.single.name, 'Anna');
    cubit.setInviteRole(MemberRole.viewer);
    await cubit.createInvite();
    expect(cubit.state.inviteCode, MockCategoriesRepository.demoInvite);
    expect(cubit.state.inviteRole, MemberRole.viewer);
    // Andere Rolle: alter Code gilt nicht mehr für die Anzeige.
    cubit.setInviteRole(MemberRole.editor);
    expect(cubit.state.inviteCode, isNull);
    await cubit.close();
  });

  test('Rolle ändern und entfernen', () async {
    final cubit = SharingCubit(repo, 'c-miete');
    await cubit.load();
    final anna = cubit.state.category!.sharedWith.single;
    final events = <SharingEventKind>[];
    final sub = cubit.stream.where((s) => s.event != null).listen((s) => events.add(s.event!.kind));
    await cubit.setRole(anna, MemberRole.viewer);
    await pumpEventQueue();
    expect(cubit.state.category!.sharedWith.single.role, MemberRole.viewer);
    await cubit.remove(anna);
    await pumpEventQueue();
    // Das Ereignis kommt vor dem Neuladen nach der Änderung.
    expect(events, [SharingEventKind.removed]);
    expect(cubit.state.category!.sharedWith, isEmpty);
    await sub.cancel();
    await cubit.close();
  });

  test('Einladung annehmen und wieder verlassen', () async {
    final id = await repo.acceptInvite(MockCategoriesRepository.demoInvite);
    final cubit = SharingCubit(repo, id);
    await cubit.load();
    expect(cubit.state.category!.isOwner, isFalse);
    await cubit.leave();
    expect(cubit.state.event?.kind, SharingEventKind.left);
    expect(await repo.loadCategory(id), isNull);
    await cubit.close();
  });

  test('Einladungslinks: Code aus dem Link, nur unser Schema', () {
    final link = InviteLinks.linkFor('K7Q2M9X4TA');
    expect(InviteLinks.codeOf(Uri.parse(link)), 'K7Q2M9X4TA');
    expect(InviteLinks.codeOf(Uri.parse('de.eloayoubi.kostenkurve://invite?code=k7q2')), 'K7Q2');
    expect(InviteLinks.codeOf(Uri.parse('https://example.com/invite?code=K7Q2M9X4TA')), isNull);
    expect(InviteLinks.codeOf(Uri.parse('de.eloayoubi.kostenkurve://login-callback')), isNull);
  });
}
