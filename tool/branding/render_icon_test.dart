import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'brand.dart';
import 'launch_animation.dart';
import 'png_golden_comparator.dart';

/// Rendert App-Icons, Startanimation und Splash-Logo nach `assets/branding/`.
///
/// ```sh
/// flutter test tool/branding/render_icon_test.dart --update-goldens
/// dart run flutter_launcher_icons            # Icons für iOS und Android
/// dart run flutter_native_splash:create      # Splash für iOS und Android
/// ```
///
/// Liegt bewusst nicht unter `test/`: Es ist ein Werkzeug, kein Test der App. Ohne
/// `--update-goldens` prüft der Lauf nur, ob die Dateien noch zum Code passen.
void main() {
  useOpaquePngGoldens();

  const icon = Size.square(1024);

  final assets = <(String, Size, void Function(Canvas, Size))>[
    // iOS und App Store: randlos und deckend, die Ecken rundet das System.
    ('app_icon', icon, (canvas, size) => Brand.paintIcon(canvas, Offset.zero & size)),
    // iOS 18+ dunkel: durchsichtig, den dunklen Grund legt iOS selbst; Rahmen und Kurve in Lavendel.
    ('app_icon_dark', icon, (canvas, size) => Brand.paintHouse(canvas, Offset.zero & size, frameColor: Brand.lavender)),
    // iOS 18+ getönt: Graustufen auf Schwarz, iOS färbt nach Helligkeit.
    (
      'app_icon_tinted',
      icon,
      (canvas, size) {
        const luminance = [0.2126, 0.7152, 0.0722, 0.0, 0.0];
        canvas
          ..drawRect(Offset.zero & size, Paint()..color = Brand.black)
          ..saveLayer(Offset.zero & size, Paint()..colorFilter = const ColorFilter.matrix([...luminance, ...luminance, ...luminance, 0, 0, 0, 1, 0]));
        Brand.paintHouse(canvas, Offset.zero & size, colorful: false, glassFill: false);
        canvas.restore();
      },
    ),
    // Android 7 (ohne Adaptive Icons): abgerundetes Quadrat mit etwas Rand.
    (
      'app_icon_android',
      icon,
      (canvas, size) {
        final rect = (Offset.zero & size).deflate(size.width * 0.04);
        canvas
          ..save()
          ..clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.22)));
        Brand.paintIcon(canvas, rect);
        canvas.restore();
      },
    ),
    // Android-Adaptive-Icon: nur das Haus, in der sicheren Zone (Kreis mit 66 % Durchmesser); den
    // Hintergrund (Indigo) setzt flutter_launcher_icons.yaml.
    ('app_icon_foreground', icon, (canvas, size) => Brand.paintHouse(canvas, _adaptive(size))),
    // Themed Icon (Android 13+): zählt nur die Deckkraft – Schichten daher in abgestuftem Weiß.
    ('app_icon_monochrome', icon, (canvas, size) => Brand.paintHouse(canvas, _adaptive(size), colorful: false, glassFill: false)),
  ];

  for (final (name, size, draw) in assets) {
    testWidgets(name, (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const key = ValueKey('asset');
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            child: CustomPaint(size: size, painter: BrandPainter(draw)),
          ),
        ),
      );
      await expectLater(find.byKey(key), matchesGoldenFile('../../assets/branding/$name.png'));
    });
  }

  final launch = '${jsonEncode(LaunchAnimation.build())}\n';

  test('launch_animation', () {
    final file = File('assets/branding/launch_animation.json');
    if (autoUpdateGoldenFiles) {
      file.writeAsStringSync(launch);
    } else {
      expect(file.readAsStringSync(), launch, reason: 'Startanimation passt nicht mehr zum Code – mit --update-goldens neu erzeugen.');
    }
  });

  // Splash hell (#F2F2F7) und dunkel (#000000): Bild 0 der Startanimation, die leere Kachel. Das Bild
  // gilt als @4x (iOS 1x = ¼, Android xxxhdpi), 1152 px = 288 pt/dp – die Fläche, die Android 12
  // für das Splash-Icon ohne Hintergrund vorsieht (Inhalt im Kreis von 768 px). Die App zeigt die
  // Animation genauso groß, daher geht der Splash nahtlos in sie über.
  testWidgets('splash_logo', (tester) async {
    const size = Size.square(LaunchAnimation.size);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('asset');
    final composition = LottieComposition.parseJsonBytes(utf8.encode(launch));
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: Lottie(composition: composition, controller: const AlwaysStoppedAnimation(0.0), width: size.width, height: size.height),
        ),
      ),
    );
    await expectLater(find.byKey(key), matchesGoldenFile('../../assets/branding/splash_logo.png'));
  });
}

/// Sichere Zone des Adaptive Icons: Das Haus passt mit Rahmen in den Kreis mit 66 % Durchmesser.
Rect _adaptive(Size size) => Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.74, height: size.height * 0.74);
