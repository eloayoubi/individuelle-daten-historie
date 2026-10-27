import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/features/update/cubit/update_cubit.dart';
import 'package:kostenkurve/features/update/data/app_release.dart';
import 'package:kostenkurve/features/update/data/installed_app.dart';
import 'package:kostenkurve/features/update/view/force_update_gate.dart';
import 'package:kostenkurve/features/update/view/force_update_page.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';
import 'package:lottie/lottie.dart';

void main() {
  const testflight = InstalledApp(version: '1.0.0', build: 11, channel: ReleaseChannel.testflight);

  /// App wie in `app.dart`: Gate im Builder über allem, darunter eine Seite mit Zähl-Button.
  Future<UpdateCubit> pumpApp(WidgetTester tester, {InstalledApp installed = testflight, int latest = 12, bool reduceMotion = false}) async {
    final cubit = UpdateCubit(_Release(latest), () async => installed);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: ForceUpdateGate(child: child!),
          ),
          home: const _Probe(),
        ),
      ),
    );
    await cubit.check();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return cubit;
  }

  setUp(() => _Probe.taps = 0);

  testWidgets('aktueller Build: App bleibt bedienbar', (tester) async {
    await pumpApp(tester, latest: 11);

    expect(find.byType(ForceUpdatePage), findsNothing);
    await tester.tap(find.text('Zählen'));
    expect(_Probe.taps, 1);
  });

  testWidgets('veralteter Build: Pflicht-Update über allem, App darunter unerreichbar', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);

    expect(find.byType(ForceUpdatePage), findsOneWidget);
    expect(find.text('Neue Version verfügbar'), findsOneWidget);
    expect(find.text('In TestFlight aktualisieren'), findsOneWidget);
    expect(find.text('Build 11 → 12'), findsOneWidget);
    expect(find.byType(Lottie), findsOneWidget);

    await tester.tap(find.text('Zählen'), warnIfMissed: false);
    expect(_Probe.taps, 0, reason: 'die Seite fängt alles ab');
    expect(find.semantics.byLabel('Zählen'), findsNothing, reason: 'VoiceOver sieht die App darunter nicht');
    expect(find.semantics.byLabel('Neue Version verfügbar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('App Store: eigener Text und Button', (tester) async {
    await pumpApp(tester, installed: const InstalledApp(version: '1.1.0', build: 40, channel: ReleaseChannel.appStore), latest: 41);

    expect(find.text('Im App Store aktualisieren'), findsOneWidget);
    expect(find.textContaining('App Store'), findsWidgets);
  });

  testWidgets('weniger Bewegung: steht still, kommt zur Ruhe', (tester) async {
    await pumpApp(tester, reduceMotion: true);

    await tester.pumpAndSettle();
    expect(find.byType(ForceUpdatePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Release implements ReleaseRepository {
  const _Release(this.build);

  final int build;

  @override
  Future<AppRelease?> latest(ReleaseChannel channel) async => AppRelease(build: build);
}

class _Probe extends StatelessWidget {
  const _Probe();

  static var taps = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: TextButton(onPressed: () => taps++, child: const Text('Zählen'))),
  );
}
