import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/update/cubit/update_cubit.dart';
import 'package:kostenkurve/features/update/data/app_release.dart';
import 'package:kostenkurve/features/update/data/installed_app.dart';

void main() {
  const testflight = InstalledApp(version: '1.0.0', build: 11, channel: ReleaseChannel.testflight);

  Future<InstalledApp> Function() installed(InstalledApp app) => () async => app;

  test('neuerer Build auf TestFlight sperrt', () async {
    final repo = _Releases({ReleaseChannel.testflight: const AppRelease(build: 12, url: 'https://testflight.apple.com/join/x')});
    final cubit = UpdateCubit(repo, installed(testflight));
    await cubit.check();
    expect(cubit.state.required, isTrue);
    expect(cubit.state.release, const AppRelease(build: 12, url: 'https://testflight.apple.com/join/x'));
    expect(cubit.state.installed, testflight);
    await cubit.close();
  });

  test('gleicher oder älterer Build sperrt nicht', () async {
    for (final build in [11, 10]) {
      final cubit = UpdateCubit(_Releases({ReleaseChannel.testflight: AppRelease(build: build)}), installed(testflight));
      await cubit.check();
      expect(cubit.state.required, isFalse, reason: 'Server: $build, installiert: 11');
      await cubit.close();
    }
  });

  test('nur der eigene Vertriebsweg zählt', () async {
    final cubit = UpdateCubit(_Releases({ReleaseChannel.appStore: const AppRelease(build: 40)}), installed(testflight));
    await cubit.check();
    expect(cubit.state.required, isFalse);
    await cubit.close();
  });

  test('ohne Vertriebsweg (Debug, Simulator, Android) nie gesperrt, ohne Netzaufruf', () async {
    final repo = _Releases({ReleaseChannel.testflight: const AppRelease(build: 99)});
    final cubit = UpdateCubit(repo, installed(const InstalledApp(version: '1.0.0', build: 1)));
    await cubit.check();
    expect(cubit.state.required, isFalse);
    expect(repo.calls, 0);
    await cubit.close();
  });

  test('ohne Netz bleibt der Stand: frei bleibt frei, gesperrt bleibt gesperrt', () async {
    final repo = _Releases({ReleaseChannel.testflight: const AppRelease(build: 12)});
    final cubit = UpdateCubit(repo, installed(testflight));
    repo.offline = true;
    await cubit.check();
    expect(cubit.state.required, isFalse);

    repo.offline = false;
    await cubit.check();
    expect(cubit.state.required, isTrue);
    repo.offline = true;
    await cubit.check();
    expect(cubit.state.required, isTrue);
    await cubit.close();
  });

  test('liest den laufenden Build nur einmal, fragt den Server bei jeder Prüfung', () async {
    final repo = _Releases({ReleaseChannel.testflight: const AppRelease(build: 11)});
    var reads = 0;
    final cubit = UpdateCubit(repo, () async {
      reads++;
      return testflight;
    });
    await cubit.check();
    repo.releases[ReleaseChannel.testflight] = const AppRelease(build: 12);
    await cubit.check();
    expect(reads, 1);
    expect(repo.calls, 2);
    expect(cubit.state.release?.build, 12, reason: 'neuer Build erst bei der zweiten Prüfung');
    await cubit.close();
  });

  test('Vertriebsweg aus dem Installer', () {
    expect(InstalledApp.channelOf('com.apple.testflight'), ReleaseChannel.testflight);
    expect(InstalledApp.channelOf('com.apple'), ReleaseChannel.appStore);
    expect(InstalledApp.channelOf('com.apple.simulator'), isNull);
    expect(InstalledApp.channelOf('com.android.vending'), isNull);
    expect(InstalledApp.channelOf(null), isNull);
  });
}

class _Releases implements ReleaseRepository {
  _Releases(this.releases);

  final Map<ReleaseChannel, AppRelease> releases;
  var offline = false;
  var calls = 0;

  @override
  Future<AppRelease?> latest(ReleaseChannel channel) async {
    calls++;
    if (offline) throw Exception('offline');
    return releases[channel];
  }
}
