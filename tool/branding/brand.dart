import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:kostenkurve/core/theme/color_config.dart';

/// Markenbild von Kostenkurve: ein Haus aus Glas, gefüllt mit Strom, Heizung und Wasser – drei
/// Schichten in den Farben der Kategorien, ihr Füllstand wie ein Zählerstand. Auf der obersten
/// Schicht liegt die Kostenkurve: durchgezogen bis zum Punkt „heute“, danach gestrichelt als
/// Prognose. Grundlage für App-Icon, Startanimation und Store-Screenshots.
///
/// Alle Formen liegen im Einheitsquadrat (0…1, y nach unten) als [BezierShape] vor und werden auf
/// das Ziel-Rechteck skaliert – so zeichnen Icon und Lottie-Startanimation dieselbe Geometrie.
abstract final class Brand {
  /// Systemindigo der App – auch Hintergrund des Android-Adaptive-Icons (flutter_launcher_icons.yaml).
  static const indigo = Palette.indigo;
  static const white = Palette.white;
  static const black = Palette.black;

  /// Verlauf des Icon-Hintergrunds: oben links heller, unten rechts tiefer, in der Mitte [indigo].
  static const gradient = [Color(0xFF7E7CF9), Palette.indigo, Color(0xFF3B39B1)];

  /// Schatten unter dem Haus (tiefes Indigo statt Schwarz, damit nichts grau wirkt).
  static const shadow = Color(0xFF17156B);

  /// Glas im Haus: oben heller, unten tiefer.
  static const glass = [Color(0xFF8C89FF), Color(0xFF4A47C9)];

  /// Zeichen im dunklen iOS-Icon: Rahmen und Kurve in hellem Lavendel.
  static const lavender = Color(0xFFC9C7FF);

  // Haus: Wände, Dach mit Schornstein rechts. Mittellinie des Rahmens.
  static const _left = 0.25, _right = 0.75, _base = 0.83, _eave = 0.47, _peak = 0.18;
  static const _chimney = (0.6, 0.685, 0.225);
  static const frame = 0.04;
  static const _corner = 0.05;

  /// Schichten von unten: Wasser, Heizung, Strom – Oberkante (Stützpunkte) und Verlauf oben → unten.
  static const layers = [
    (top: [0.735, 0.715, 0.735, 0.705, 0.69, 0.68], colors: [Color(0xFF6EDBFF), Color(0xFF1E8CFF)]),
    (top: [0.645, 0.61, 0.645, 0.61, 0.585, 0.57], colors: [Color(0xFFFF8A75), Color(0xFFFF3B5C)]),
    (top: [0.545, 0.49, 0.525, 0.5, 0.475, 0.46], colors: [Color(0xFFFFD75E), Color(0xFFFF9F0A)]),
  ];

  /// x der Stützpunkte, über die Wände hinaus (das Glas schneidet ab).
  static const layerXs = [0.18, 0.32, 0.46, 0.60, 0.74, 0.86];

  /// Kostenkurve auf der obersten Schicht: Stärke, Punkt „heute“ (x) mit Hof, Striche der Prognose.
  static const line = 0.026;
  static const todayX = 0.5;
  static const dot = 0.036;
  static const halo = 0.064;
  static const dash = (0.034, 0.03);

  /// Schatten des Hauses relativ zur Kantenlänge.
  static const shadowBlur = 0.035;
  static const shadowOffset = 0.03;
  static const shadowOpacity = 0.5;

  static Offset at(Rect box, Offset unit) => box.topLeft + Offset(unit.dx * box.width, unit.dy * box.height);

  static double _roofY(double x) => _peak + (_eave - _peak) * ((x - 0.5).abs() / (_right - 0.5));

  /// Mittellinie des Hausrahmens mit gerundeten Ecken (geschlossen).
  static BezierShape house() {
    final (cx0, cx1, ctop) = _chimney;
    return BezierShape.roundedPolygon([
      const Offset(_left, _base),
      const Offset(_left, _eave),
      const Offset(0.5, _peak),
      Offset(cx0, _roofY(cx0)),
      Offset(cx0, ctop),
      Offset(cx1, ctop),
      Offset(cx1, _roofY(cx1)),
      const Offset(_right, _eave),
      const Offset(_right, _base),
    ], _corner);
  }

  /// Innenraum: der Rahmen um die halbe Stärke nach innen versetzt – darin Glas und Schichten.
  static BezierShape inside() => house().scaled(_insideScale, _insideCenter);

  static const _insideCenter = Offset(0.5, 0.53);
  static double get _insideScale => 1 - frame / (_right - _left);

  /// Oberkante der Schicht [i] (offen, von links nach rechts).
  static BezierShape layerTop(int i) => BezierShape.smooth([
    for (var k = 0; k < layerXs.length; k++) Offset(layerXs[k], layers[i].top[k]),
  ]);

  /// Schicht [i] als Fläche: Oberkante, dann unter dem Haus zurück.
  static BezierShape layerArea(int i) => layerTop(i).closedDownTo(0.95);

  /// Kurve bis „heute“ und Prognose danach (Teil der Oberkante der obersten Schicht).
  static (BezierShape past, BezierShape forecast) curve() {
    final top = layerTop(layers.length - 1);
    return (top.until(todayX), top.from(todayX));
  }

  static Offset get today => curve().$1.vertices.last;

  /// Zeichnet das Haus mit Glas, Schichten, Kurve und Punkt in [box].
  ///
  /// [frameColor] färbt Rahmen, Kurve und Punkt; [colorful] = false zeichnet die Schichten in
  /// Weißtönen (getöntes iOS-Icon). [shadow] wirft einen weichen Schatten (nur auf farbigem Grund).
  static void paintHouse(Canvas canvas, Rect box, {Color frameColor = white, bool colorful = true, bool glassFill = true, bool shadow = false}) {
    final s = box.width;
    final outline = house().path(box);
    final inner = inside().path(box);

    if (shadow) {
      canvas.drawPath(
        outline.shift(Offset(0, shadowOffset * s)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame * s
          ..color = Brand.shadow.withValues(alpha: shadowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur * s),
      );
      canvas.drawPath(
        inner.shift(Offset(0, shadowOffset * s)),
        Paint()
          ..color = Brand.shadow.withValues(alpha: shadowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur * s),
      );
    }

    canvas
      ..save()
      ..clipPath(inner);
    if (glassFill) {
      canvas.drawPath(inner, Paint()..shader = ui.Gradient.linear(at(box, const Offset(0.5, _peak)), at(box, const Offset(0.5, _base)), glass));
    }
    // Von der obersten Schicht nach unten: Jede Fläche reicht bis unter das Haus, die tiefere liegt darüber.
    for (var i = layers.length - 1; i >= 0; i--) {
      final colors = colorful ? layers[i].colors : _tintedLayer(i);
      final top = layers[i].top.reduce(math.min);
      canvas
        ..drawPath(layerArea(i).path(box), Paint()..shader = ui.Gradient.linear(at(box, Offset(0, top)), at(box, const Offset(0, _base)), colors))
        ..drawPath(layerTop(i).path(box), seamPaint(s));
    }
    canvas.drawPath(reflection().path(box), Paint()..color = white.withValues(alpha: 0.16));

    final (past, forecast) = curve();
    canvas
      ..drawPath(past.path(box), curvePaint(s, frameColor))
      ..drawPath(dashed(forecast.path(box), s), curvePaint(s, frameColor))
      ..restore();

    final today = at(box, Brand.today);
    canvas
      ..drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame * s
          ..strokeJoin = StrokeJoin.round
          ..color = frameColor,
      )
      ..drawCircle(today, halo * s, Paint()..color = frameColor.withValues(alpha: 0.35))
      ..drawCircle(today, dot * s, Paint()..color = frameColor);
  }

  static List<Color> _tintedLayer(int i) => [white.withValues(alpha: 0.35 + i * 0.25), white.withValues(alpha: 0.15 + i * 0.15)];

  static Paint seamPaint(double s) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.01 * s
    ..color = white.withValues(alpha: 0.5);

  static Paint curvePaint(double s, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = line * s
    ..strokeCap = StrokeCap.round
    ..color = color;

  static Path dashed(Path path, double s) {
    final out = Path();
    final (on, off) = dash;
    for (final metric in path.computeMetrics()) {
      // Erster Strich mit Abstand zum Punkt, damit er nicht am Hof klebt.
      for (var d = off * s + halo * s * 0.5; d < metric.length; d += (on + off) * s) {
        out.addPath(metric.extractPath(d, math.min(d + on * s, metric.length)), Offset.zero);
      }
    }
    return out;
  }

  /// Spiegelung auf dem Glas: schräger Streifen links unter dem Dach.
  static BezierShape reflection() => BezierShape.polygon(const [Offset(0.29, 0.46), Offset(0.41, 0.34), Offset(0.41, 0.41), Offset(0.29, 0.53)]);

  /// Hintergrund des Icons: Indigo-Verlauf mit weichem Licht von oben links, randlos in [rect].
  static void paintBackground(Canvas canvas, Rect rect) {
    canvas
      ..drawRect(rect, Paint()..shader = backgroundGradient(rect))
      ..drawRect(rect, Paint()..shader = backgroundLight(rect));
  }

  static Shader backgroundGradient(Rect rect) => ui.Gradient.linear(
    rect.topLeft + Offset(rect.width * 0.1, 0),
    rect.bottomRight - Offset(rect.width * 0.1, 0),
    gradient,
    [0, 0.5, 1],
  );

  static Shader backgroundLight(Rect rect) => ui.Gradient.radial(
    rect.topLeft + Offset(rect.width * 0.22, rect.height * 0.08),
    rect.width * 0.95,
    [white.withValues(alpha: 0.12), white.withValues(alpha: 0)],
  );

  /// Komplettes Icon (Hintergrund und Haus mit Schatten) in [rect].
  static void paintIcon(Canvas canvas, Rect rect) {
    paintBackground(canvas, rect);
    paintHouse(canvas, rect, shadow: true);
  }

  /// Apples Icon-Form (Superellipse mit fließenden Ecken), angenähert mit Exponent 5, als Punkte.
  static List<Offset> squirclePoints(Rect rect, {int steps = 720}) {
    const n = 5.0;
    final c = rect.center;
    final a = rect.width / 2, b = rect.height / 2;
    double curve(double v) => v.sign * math.pow(v.abs(), 2 / n).toDouble();
    return [
      for (var i = 0; i < steps; i++)
        Offset(c.dx + a * curve(math.cos(i / steps * 2 * math.pi)), c.dy + b * curve(math.sin(i / steps * 2 * math.pi))),
    ];
  }

  static Path squircle(Rect rect) => Path()..addPolygon(squirclePoints(rect), true);
}

/// Pfad aus kubischen Bézier-Stücken wie in Lottie: Punkte mit Tangenten (relativ zum Punkt).
/// Koordinaten im Einheitsquadrat; [path] skaliert auf ein Rechteck.
class BezierShape {
  const BezierShape(this.vertices, this.ins, this.outs, {required this.closed});

  /// Ecken mit Radius [radius] abgerundet (kubische Näherung des Kreisbogens).
  factory BezierShape.roundedPolygon(List<Offset> corners, double radius) {
    final v = <Offset>[], ins = <Offset>[], outs = <Offset>[];
    const k = 0.5523; // Kreisbogen 90° als Kubik
    for (var i = 0; i < corners.length; i++) {
      final prev = corners[(i - 1 + corners.length) % corners.length], cur = corners[i], next = corners[(i + 1) % corners.length];
      final r = math.min(radius, math.min((prev - cur).distance, (next - cur).distance) / 2.2);
      final a = cur + (prev - cur) / (prev - cur).distance * r;
      final b = cur + (next - cur) / (next - cur).distance * r;
      v.addAll([a, b]);
      ins.addAll([Offset.zero, (cur - b) * k]);
      outs.addAll([(cur - a) * k, Offset.zero]);
    }
    return BezierShape(v, ins, outs, closed: true);
  }

  factory BezierShape.polygon(List<Offset> points) => BezierShape(points, [for (final _ in points) Offset.zero], [for (final _ in points) Offset.zero], closed: true);

  /// Weiche Kurve durch [points] (Catmull-Rom), offen.
  factory BezierShape.smooth(List<Offset> points) {
    final ins = <Offset>[], outs = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final prev = points[math.max(i - 1, 0)], next = points[math.min(i + 1, points.length - 1)];
      final tangent = (next - prev) / 6;
      ins.add(i == 0 ? Offset.zero : -tangent);
      outs.add(i == points.length - 1 ? Offset.zero : tangent);
    }
    return BezierShape(points, ins, outs, closed: false);
  }

  final List<Offset> vertices, ins, outs;
  final bool closed;

  int get _segments => closed ? vertices.length : vertices.length - 1;

  (Offset, Offset, Offset, Offset) _segment(int i) {
    final j = (i + 1) % vertices.length;
    return (vertices[i], vertices[i] + outs[i], vertices[j] + ins[j], vertices[j]);
  }

  Path path(Rect box) {
    Offset p(Offset u) => Brand.at(box, u);
    final start = p(vertices.first);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < _segments; i++) {
      final (_, c1, c2, end) = _segment(i);
      final a = p(c1), b = p(c2), e = p(end);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
    }
    if (closed) path.close();
    return path;
  }

  BezierShape scaled(double factor, Offset center) => BezierShape(
    [for (final v in vertices) center + (v - center) * factor],
    [for (final t in ins) t * factor],
    [for (final t in outs) t * factor],
    closed: closed,
  );

  BezierShape map(Offset Function(Offset) f) => BezierShape([for (final v in vertices) f(v)], ins, outs, closed: closed);

  /// Offene Kurve nach unten bis [bottom] geschlossen (Fläche darunter).
  BezierShape closedDownTo(double bottom) => BezierShape(
    [...vertices, Offset(vertices.last.dx, bottom), Offset(vertices.first.dx, bottom)],
    [...ins, Offset.zero, Offset.zero],
    [...outs, Offset.zero, Offset.zero],
    closed: true,
  );

  /// Teil der offenen Kurve links bzw. rechts von [x] (Schnitt per De Casteljau).
  BezierShape until(double x) => _split(x).$1;
  BezierShape from(double x) => _split(x).$2;

  (BezierShape, BezierShape) _split(double x) {
    for (var i = 0; i < _segments; i++) {
      final (p0, p1, p2, p3) = _segment(i);
      if (x < p0.dx || x > p3.dx) continue;
      var lo = 0.0, hi = 1.0;
      for (var n = 0; n < 40; n++) {
        final mid = (lo + hi) / 2;
        _cubic(p0, p1, p2, p3, mid).dx < x ? lo = mid : hi = mid;
      }
      final t = (lo + hi) / 2;
      final a = Offset.lerp(p0, p1, t)!, b = Offset.lerp(p1, p2, t)!, c = Offset.lerp(p2, p3, t)!;
      final d = Offset.lerp(a, b, t)!, e = Offset.lerp(b, c, t)!, m = Offset.lerp(d, e, t)!;
      final left = BezierShape(
        [...vertices.take(i + 1), m],
        [...ins.take(i + 1), d - m],
        [...outs.take(i), a - p0, Offset.zero],
        closed: false,
      );
      final right = BezierShape(
        [m, ...vertices.skip(i + 1)],
        [Offset.zero, c - p3, ...ins.skip(i + 2)],
        [e - m, ...outs.skip(i + 1)],
        closed: false,
      );
      return (left, right);
    }
    throw ArgumentError.value(x, 'x', 'liegt nicht auf der Kurve');
  }

  static Offset _cubic(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t);
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
