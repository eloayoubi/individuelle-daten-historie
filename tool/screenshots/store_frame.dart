import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kostenkurve/core/theme/text_styles.dart';

import '../branding/brand.dart';

/// Rahmen eines Store-Screenshots: Überschrift und Unterzeile auf dem Indigo der Marke, darunter
/// ein iPhone mit der echten App-Seite.
///
/// Entworfen in Punkten auf [canvas] (iPhone 6,9", 440 × 956 pt) und mit Faktor 3 auf [size]
/// gerendert – so wird alles als Vektor scharf in 1320 × 2868 px gezeichnet.
class StoreFrame extends StatelessWidget {
  const StoreFrame({super.key, required this.headline, required this.subline, required this.theme, required this.screen});

  /// Ausgabe in Pixeln, wie App Store Connect sie für iPhone 6,9" erwartet.
  static const size = Size(1320, 2868);
  static const canvas = Size(440, 956);
  static const captureKey = ValueKey('store-frame');

  /// Höhe des Textbereichs oben; darunter steht das Gerät.
  static const _textHeight = 224.0;
  static const _bottom = 26.0;

  final String headline;
  final String subline;

  /// Theme der App-Seite im Gerät (hell oder dunkel).
  final ThemeData theme;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    const styles = AppTextStyles(color: Brand.white);
    final deviceHeight = canvas.height - _textHeight - _bottom;
    final deviceWidth = deviceHeight * DeviceMockup.outer.width / DeviceMockup.outer.height;
    return RepaintBoundary(
      key: captureKey,
      child: SizedBox.fromSize(
        size: size,
        child: FittedBox(
          child: SizedBox.fromSize(
            size: canvas,
            child: CustomPaint(
              painter: const _BackgroundPainter(),
              child: Stack(
                children: [
                  Positioned(
                    left: 26,
                    right: 26,
                    top: 18,
                    height: _textHeight - 18,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        Text(
                          headline,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: styles.largeTitle.copyWith(fontSize: 38, height: 1.08, letterSpacing: -0.7),
                        ),
                        Text(
                          subline,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: styles.body.copyWith(fontSize: 17, height: 1.35, letterSpacing: -0.2, color: Brand.white.withValues(alpha: 0.84)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: _textHeight,
                    left: (canvas.width - deviceWidth) / 2,
                    width: deviceWidth,
                    height: deviceHeight,
                    child: FittedBox(child: DeviceMockup(theme: theme, child: screen)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indigo-Verlauf wie das App-Icon, mit weichem Licht hinter dem Gerät und der Kurve der Marke
/// ganz dezent im Hintergrund.
class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Brand.gradient,
            stops: [0, 0.45, 1],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 0.75,
            colors: [Brand.white.withValues(alpha: 0.16), Brand.white.withValues(alpha: 0)],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}

/// iPhone mit Dynamic Island, Statusleiste und Home-Indikator; [child] ist die App-Seite in
/// echter Größe ([screen], Safe Area wie beim iPhone 16 Pro Max).
class DeviceMockup extends StatelessWidget {
  const DeviceMockup({super.key, required this.theme, required this.child});

  static const screen = Size(440, 956);
  static const padding = EdgeInsets.only(top: 62, bottom: 34);
  static const _radius = 62.0;
  static const _bezel = 10.5;
  static const _band = 3.5;
  static const outer = Size(440 + 2 * (_bezel + _band), 956 + 2 * (_bezel + _band));

  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? Brand.white : const Color(0xFF000000);
    return Container(
      width: outer.width,
      height: outer.height,
      padding: const EdgeInsets.all(_band),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius + _bezel + _band),
        // Rahmen aus Titan: dunkles Grau mit Lichtkante oben.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E8E96), Color(0xFF3A3A40), Color(0xFF55555C)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x47100E50), blurRadius: 60, offset: Offset(0, 28)),
          BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(_bezel),
        decoration: BoxDecoration(color: const Color(0xFF050506), borderRadius: BorderRadius.circular(_radius + _bezel)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: SizedBox.fromSize(
            size: screen,
            child: Theme(
              data: theme,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: screen,
                    devicePixelRatio: 3,
                    padding: padding,
                    viewPadding: padding,
                    viewInsets: EdgeInsets.zero,
                    platformBrightness: theme.brightness,
                    textScaler: TextScaler.noScaling,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: theme.scaffoldBackgroundColor, child: child)),
                      Positioned(top: 0, left: 0, right: 0, height: 54, child: _StatusBar(ink: ink)),
                      Positioned(
                        top: 11,
                        left: (screen.width - 126) / 2,
                        width: 126,
                        height: 37,
                        child: const DecoratedBox(decoration: ShapeDecoration(color: Color(0xFF000000), shape: StadiumBorder())),
                      ),
                      Positioned(
                        bottom: 8,
                        left: (screen.width - 144) / 2,
                        width: 144,
                        height: 5,
                        child: DecoratedBox(decoration: ShapeDecoration(color: ink.withValues(alpha: 0.9), shape: const StadiumBorder())),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Statusleiste wie in Apples Marketing-Bildern: 9:41, volle Balken, WLAN, voller Akku.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    const styles = AppTextStyles(color: Color(0xFF000000));
    return Stack(
      children: [
        Positioned(
          left: 0,
          width: 157,
          top: 17,
          height: 25,
          child: Center(
            child: Text('9:41', style: styles.headline.copyWith(color: ink, fontSize: 17, letterSpacing: -0.3, height: 1.2)),
          ),
        ),
        Positioned(right: 30, top: 23, width: 76, height: 13, child: CustomPaint(painter: _StatusIconsPainter(ink))),
      ],
    );
  }
}

class _StatusIconsPainter extends CustomPainter {
  const _StatusIconsPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = ink;
    final h = size.height;

    // Mobilfunk: vier Balken.
    const barWidth = 3.2, gap = 1.6;
    for (var i = 0; i < 4; i++) {
      final barHeight = h * (0.36 + 0.213 * i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(i * (barWidth + gap), h - barHeight, barWidth, barHeight), const Radius.circular(1)),
        fill,
      );
    }

    // WLAN: drei Bögen um einen Punkt unten in der Mitte.
    final wifiCenter = Offset(19 + 6 + 8.2, h + 0.6);
    final arc = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    for (final r in [10.6, 6.6]) {
      canvas.drawArc(Rect.fromCircle(center: wifiCenter, radius: r), -math.pi * 0.77, math.pi * 0.54, false, arc);
    }
    canvas.drawPath(
      Path()
        ..moveTo(wifiCenter.dx, wifiCenter.dy - 0.4)
        ..arcTo(Rect.fromCircle(center: wifiCenter, radius: 3.4), -math.pi * 0.77, math.pi * 0.54, false)
        ..close(),
      fill,
    );

    // Akku: Rahmen, Füllung, Pol.
    const batteryLeft = 19 + 6 + 16.4 + 6.5;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(batteryLeft, 0.2, 25, h - 0.4), const Radius.circular(4));
    canvas
      ..drawRRect(
        body,
        Paint()
          ..color = ink.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      )
      ..drawRRect(body.deflate(2), Paint()..color = ink)
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(batteryLeft + 26.2, h / 2 - 2.3, 1.6, 4.6), const Radius.circular(0.8)),
        Paint()..color = ink.withValues(alpha: 0.4),
      );
  }

  @override
  bool shouldRepaint(_StatusIconsPainter oldDelegate) => oldDelegate.ink != ink;
}
