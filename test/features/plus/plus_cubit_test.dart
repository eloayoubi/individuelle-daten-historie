import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/plus/cubit/plus_cubit.dart';
import 'package:kostenkurve/features/plus/data/plus_repository.dart';
import 'package:kostenkurve/features/plus/data/plus_store.dart';

void main() {
  late MockPlusRepository repo;
  late MockPlusStore store;
  setUp(() {
    repo = MockPlusRepository();
    store = MockPlusStore(repo);
  });

  test('lädt Stand und Monatspreis, vom Server bestätigt', () async {
    final cubit = PlusCubit(repo, store);
    await cubit.load();
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.checked, isTrue);
    expect(cubit.state.active, isFalse);
    expect(cubit.state.prices.keys, PlusStore.products);
    expect(cubit.state.monthly?.raw, 2);
    await cubit.close();
  });

  test('Server nicht erreichbar: geladen, aber nicht bestätigt', () async {
    final cubit = PlusCubit(_OfflinePlusRepository(), store);
    await cubit.load();
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.checked, isFalse);
    await cubit.close();
  });

  test('Kaufen schaltet frei und meldet unlocked', () async {
    final cubit = PlusCubit(repo, store);
    await cubit.load();
    final events = <PlusStoreUpdateKind>[];
    final sub = cubit.stream.where((s) => s.event != null).listen((s) => events.add(s.event!.kind));
    await cubit.buy(PlusStore.monthly);
    await pumpEventQueue();
    expect(cubit.state.active, isTrue);
    expect(cubit.state.busy, isFalse);
    expect(events, [PlusStoreUpdateKind.unlocked]);
    await sub.cancel();
    await cubit.close();
  });

  test('Wiederherstellen ohne Abo meldet expired, mit Abo unlocked', () async {
    final cubit = PlusCubit(repo, store);
    await cubit.restore();
    expect(cubit.state.event?.kind, PlusStoreUpdateKind.expired);
    expect(cubit.state.busy, isFalse);
    await repo.redeem('jws');
    await cubit.restore();
    expect(cubit.state.event?.kind, PlusStoreUpdateKind.unlocked);
    expect(cubit.state.active, isTrue);
    await cubit.close();
  });

  test('Android ohne Store: nicht unterstützt, keine Preise', () async {
    final cubit = PlusCubit(repo, const UnavailablePlusStore());
    await cubit.load();
    expect(cubit.state.supported, isFalse);
    expect(cubit.state.prices, isEmpty);
    expect(cubit.state.monthly, isNull);
    await cubit.buy(PlusStore.monthly);
    expect(cubit.state.event?.kind, PlusStoreUpdateKind.failed);
    await cubit.close();
  });

  test('PlusRejected erkennt fremdes Konto', () {
    expect(const PlusRejected('wrong_user').otherAccount, isTrue);
    expect(const PlusRejected('wrong_app').otherAccount, isFalse);
  });
}

class _OfflinePlusRepository implements PlusRepository {
  @override
  Future<PlusStatus> status() async => throw StateError('offline');

  @override
  Future<PlusStatus> redeem(String jws) async => throw StateError('offline');
}
