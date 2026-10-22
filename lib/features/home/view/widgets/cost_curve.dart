import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Die „Kostenkurve“: Monatskosten von diesem und dem nächsten Jahr als weiche Linie.
/// Bis zum aktuellen Monat durchgezogen mit Fläche, danach gestrichelt (Hochrechnung).
class CostCurve extends StatelessWidget {
  const CostCurve({
    super.key,
    required this.months,
    required this.currentIndex,
    required this.lineColor,
    required this.forecastColor,
    required this.gridColor,
  });

  /// Monatswerte, Januar dieses Jahres bis Dezember des nächsten.
  final List<double> months;

  /// Index des aktuellen Monats in [months].
  final int currentIndex;
  final Color lineColor;
  final Color forecastColor;
  final Color gridColor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.infinite,
      painter: _CurvePainter(months: months, currentIndex: currentIndex, line: lineColor, forecast: forecastColor, grid: gridColor),
    ),
  );
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.months, required this.currentIndex, required this.line, required this.forecast, required this.grid});

  final List<double> months;
  final int currentIndex;
  final Color line;
  final Color forecast;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.length < 2) return;
    const dot = 4.0;
    final top = dot * 2, bottom = size.height - dot * 2;
    final lo = months.reduce(math.min), hi = months.reduce(math.max);
    final span = (hi - lo).abs() < 1 ? 1.0 : hi - lo;
    final step = size.width / (months.length - 1);
    final points = [
      for (final (i, v) in months.indexed) Offset(i * step, bottom - (v - lo) / span * (bottom - top)),
    ];

    // Jahreswechsel als feine Linie.
    final yearX = step * (months.length ~/ 2 - 0.5);
    canvas.drawLine(Offset(yearX, 0), Offset(yearX, size.height), Paint()..color = grid..strokeWidth = 1);

    final now = currentIndex.clamp(0, points.length - 1);
    final past = _smooth(points.sublist(0, now + 1));
    final future = _smooth(points.sublist(now));

    // Fläche unter dem Ist-Verlauf.
    if (now > 0) {
      final area = Path.from(past)
        ..lineTo(points[now].dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.35), line.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(past, stroke..color = line);
    canvas.drawPath(_dashed(future), stroke..color = forecast);

    // Heute: Punkt mit Hof.
    canvas
      ..drawCircle(points[now], dot * 2, Paint()..color = line.withValues(alpha: 0.25))
      ..drawCircle(points[now], dot, Paint()..color = line);
  }

  /// Weiche Kurve durch alle Punkte (Catmull-Rom als kubische Bézier).
  static Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i == 0 ? p[i] : p[i - 1];
      final p1 = p[i], p2 = p[i + 1];
      final p3 = i + 2 < p.length ? p[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  static Path _dashed(Path source, {double dash = 5, double gap = 5}) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        out.addPath(metric.extractPath(d, math.min(d + dash, metric.length)), Offset.zero);
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.months != months || old.currentIndex != currentIndex || old.line != line || old.forecast != forecast || old.grid != grid;
}
