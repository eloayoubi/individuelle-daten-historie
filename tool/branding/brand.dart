import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:kostenkurve/core/theme/color_config.dart';

/// Markenbild von Kostenkurve: die Kurve aus der Prognose-Karte – steigt, fällt, steigt wieder –
/// mit dem Punkt „heute“ am Ende. Grundlage für App-Icon, Splash und Store-Screenshots.
///
/// Gezeichnet wird alles im Einheitsquadrat (0…1, y nach unten) und auf das Ziel-Rechteck skaliert,
/// damit Icon, Adaptive-Icon-Vordergrund und Splash dieselbe Form haben.
abstract final class Brand {
  /// Systemindigo der App – auch Hintergrund des Android-Adaptive-Icons (flutter_launcher_icons.yaml).
  static const indigo = Palette.indigo;
  static const indigoBright = Palette.indigoBright;
  static const white = Palette.white;

  /// Verlauf des Icon-Hintergrunds: oben links heller, unten rechts tiefer, in der Mitte [indigo].
  static const gradient = [Color(0xFF7E7CF9), Palette.indigo, Color(0xFF3B39B1)];

  /// Schatten unter Linie und Punkt (tiefes Indigo statt Schwarz, damit nichts grau wirkt).
  static const shadow = Color(0xFF17156B);

  /// Anfang der Kurve im Einheitsquadrat.
  static const start = Offset(0.17, 0.63);

  /// Kubische Abschnitte (Kontrollpunkt 1, Kontrollpunkt 2, Ende): steigen, fallen, steigen.
  /// Hoch- und Tiefpunkt haben waagrechte Tangenten, damit die Kurve weich und ruhig wirkt.
  /// Das letzte Ende ist der Punkt „heute“.
  static const segments = [
    (Offset(0.27, 0.63), Offset(0.31, 0.43), Offset(0.41, 0.43)),
    (Offset(0.49, 0.43), Offset(0.53, 0.565), Offset(0.61, 0.565)),
    (Offset(0.70, 0.565), Offset(0.75, 0.38), Offset(0.83, 0.33)),
  ];

  static Offset get dotCenter => segments.last.$3;

  /// Linienstärke, Punkt und Hof relativ zur Kantenlänge des Einheitsquadrats.
  static const stroke = 0.06;
  static const dot = 0.052;
  static const halo = 0.094;

  static Offset _at(Rect box, Offset unit) => box.topLeft + Offset(unit.dx * box.width, unit.dy * box.height);

  /// Die Kurve in [box] (Einheitsquadrat auf [box] skaliert).
  static Path curve(Rect box) {
    final a = _at(box, start);
    final path = Path()..moveTo(a.dx, a.dy);
    for (final (c1, c2, end) in segments) {
      final p1 = _at(box, c1), p2 = _at(box, c2), p3 = _at(box, end);
      path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    }
    return path;
  }

  /// Zeichnet Fläche, Linie und Punkt mit Hof in [box].
  ///
  /// [fillBottom] ist die Unterkante der Fläche im Einheitsquadrat (dort ist sie ganz ausgeblendet).
  /// [shadow] zeichnet einen weichen Schatten unter Linie und Punkt (nur auf farbigem Grund).
  static void paintMark(
    Canvas canvas,
    Rect box, {
    required Color line,
    double fillOpacity = 0.3,
    double haloOpacity = 0.26,
    double fillBottom = 0.94,
    bool shadow = false,
  }) {
    final s = box.width;
    final path = curve(box);
    final first = _at(box, start);
    final last = _at(box, dotCenter);
    final top = box.top + [start, for (final seg in segments) seg.$3].map((p) => p.dy).reduce(math.min) * box.height;
    final bottom = box.top + fillBottom * box.height;

    // Fläche unter der Kurve: nach unten ausgeblendet, links weich eingeblendet (keine harte Kante).
    // Ohne den Hof um den Punkt, sonst addieren sich die beiden halbtransparenten Flächen.
    final area = Path.combine(
      PathOperation.difference,
      Path.from(path)
        ..lineTo(last.dx, bottom)
        ..lineTo(first.dx, bottom)
        ..close(),
      Path()..addOval(Rect.fromCircle(center: last, radius: halo * s)),
    );
    final bounds = Rect.fromLTRB(first.dx, top, last.dx, bottom);
    canvas
      ..saveLayer(bounds.inflate(1), Paint())
      ..drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top),
            Offset(0, bottom),
            [line.withValues(alpha: fillOpacity), line.withValues(alpha: fillOpacity * 0.4), line.withValues(alpha: 0)],
            [0, 0.5, 1],
          ),
      )
      ..drawRect(
        bounds.inflate(1),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(first.dx, 0),
            Offset(first.dx + 0.22 * s, 0),
            [line.withValues(alpha: 0), line],
          ),
      )
      ..restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Brand.stroke * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (shadow) {
      final blur = MaskFilter.blur(BlurStyle.normal, 0.02 * s);
      final offset = Offset(0, 0.018 * s);
      final shade = Brand.shadow.withValues(alpha: 0.42);
      canvas
        ..drawPath(
          path.shift(offset),
          Paint.from(stroke)
            ..color = shade
            ..maskFilter = blur,
        )
        ..drawCircle(
          last + offset,
          dot * s,
          Paint()
            ..color = shade
            ..maskFilter = blur,
        );
    }

    canvas
      ..drawPath(path, stroke..color = line)
      ..drawCircle(last, halo * s, Paint()..color = line.withValues(alpha: haloOpacity))
      ..drawCircle(last, dot * s, Paint()..color = line);
  }

  /// Hintergrund des Icons: Indigo-Verlauf mit weichem Licht von oben links, randlos in [rect].
  static void paintBackground(Canvas canvas, Rect rect) {
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft + Offset(rect.width * 0.1, 0),
            rect.bottomRight - Offset(rect.width * 0.1, 0),
            gradient,
            [0, 0.5, 1],
          ),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            rect.topLeft + Offset(rect.width * 0.22, rect.height * 0.08),
            rect.width * 0.95,
            [white.withValues(alpha: 0.1), white.withValues(alpha: 0)],
          ),
      );
  }

  /// Komplettes Icon (Hintergrund und Zeichen mit Schatten) in [rect].
  static void paintIcon(Canvas canvas, Rect rect) {
    paintBackground(canvas, rect);
    paintMark(canvas, rect, line: white, shadow: true);
  }

  /// Apples Icon-Form (Superellipse mit fließenden Ecken), angenähert mit Exponent 5.
  static Path squircle(Rect rect) {
    const n = 5.0;
    const steps = 720;
    final path = Path();
    final c = rect.center;
    final a = rect.width / 2, b = rect.height / 2;
    double curve(double v) => v.sign * math.pow(v.abs(), 2 / n).toDouble();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final x = c.dx + a * curve(math.cos(t));
      final y = c.dy + b * curve(math.sin(t));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }
}

/// Zeichnet mit einer Funktion – für die Render-Tests von Icon und Splash.
class BrandPainter extends CustomPainter {
  const BrandPainter(this.draw);

  final void Function(Canvas canvas, Size size) draw;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);

  @override
  bool shouldRepaint(BrandPainter oldDelegate) => oldDelegate.draw != draw;
}
