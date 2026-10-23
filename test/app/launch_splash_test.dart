import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/app/launch_splash.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

void main() {
  final composition = LottieComposition.parseJsonBytes(File(LaunchSplash.asset).readAsBytesSync());

  setUp(() => _Probe.starts = 0);

  Widget app(LottieComposition? launch, {bool reduceMotion = false}) => MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: LaunchSplash(composition: launch, child: child!),
    ),
    home: const _Probe(),
  );

  testWidgets('ohne Animation gleich die App', (tester) async {
    await tester.pumpWidget(app(null));

    expect(find.byType(Lottie), findsNothing);
    expect(find.byType(_Probe), findsOneWidget);
  });

  testWidgets('spielt die Animation, blendet aus und lässt die App stehen', (tester) async {
    await tester.pumpWidget(app(composition));
    expect(find.byType(Lottie), findsOneWidget);
    expect(tester.getSize(find.byType(Lottie)), const Size.square(LaunchSplash.size));

    await tester.pump(composition.duration);
    expect(find.byType(Lottie), findsOneWidget, reason: 'noch beim Ausblenden');

    await tester.pumpAndSettle();
    expect(find.byType(Lottie), findsNothing);
    expect(find.byType(_Probe), findsOneWidget);
    expect(_Probe.starts, 1, reason: 'die App darunter startet nicht neu');
  });

  testWidgets('weniger Bewegung: nur ausblenden, ohne Animation', (tester) async {
    await tester.pumpWidget(app(composition, reduceMotion: true));
    expect(find.byType(Lottie), findsOneWidget);

    final start = tester.binding.clock.now();
    await tester.pumpAndSettle();
    expect(find.byType(Lottie), findsNothing);
    expect(tester.binding.clock.now().difference(start), lessThan(composition.duration), reason: 'nur Ausblenden, nicht die Animation');
  });
}

class _Probe extends StatefulWidget {
  const _Probe();

  static var starts = 0;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.starts++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
