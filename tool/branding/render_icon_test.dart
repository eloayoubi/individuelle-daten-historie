import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brand.dart';
import 'png_golden_comparator.dart';

/// Rendert App-Icon, Android-Icons und Splash-Logos nach `assets/branding/`.
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
  // Splash: Bild gilt als @4x (iOS 1x = ¼, Android xxxhdpi), 1152 px = 288 pt/dp – die Fläche,
  // die Android 12 für das Splash-Icon ohne Hintergrund vorsieht (Inhalt im Kreis von 768 px).
  const splash = Size.square(1152);

  final assets = <(String, Size, void Function(Canvas, Size))>[
    // iOS und App Store: randlos und deckend, die Ecken rundet das System.
    ('app_icon', icon, (canvas, size) => Brand.paintIcon(canvas, Offset.zero & size)),
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
    // Android-Adaptive-Icon: nur die Kurve, in der sicheren Zone (Kreis mit 66 % Durchmesser); den
    // Hintergrund (Indigo) setzt flutter_launcher_icons.yaml. Dient auch als Monochrom-Ebene.
    (
      'app_icon_foreground',
      icon,
      (canvas, size) => Brand.paintMark(canvas, Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.66, height: size.height * 0.66), line: Brand.white),
    ),
    // Splash hell (#F2F2F7) und dunkel (#000000): die Kurve in Indigo, etwa 120 pt/dp breit.
    ('splash_logo', splash, (canvas, size) => _splash(canvas, size, Brand.indigo)),
    ('splash_logo_dark', splash, (canvas, size) => _splash(canvas, size, Brand.indigoBright)),
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
}

void _splash(Canvas canvas, Size size, Color color) {
  final box = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.55, height: size.height * 0.55);
  Brand.paintMark(canvas, box, line: color, fillOpacity: 0.24, haloOpacity: 0.22);
}
