import 'dart:math' as math;
import 'dart:ui';

import 'package:kostenkurve/core/theme/color_config.dart';

import 'brand.dart';

part 'update_animation.dart';

/// Startanimation als Lottie: In das leere Glashaus vom nativen Splash fließen Wasser, Heizung und
/// Strom, schwappen und kommen zur Ruhe. Dann zeichnet sich die Kostenkurve bis „heute“, der Punkt
/// setzt mit einer Welle auf, die Prognose läuft gestrichelt weiter, ein Glanz zieht übers Glas –
/// am Ende steht das App-Icon.
///
/// Gebaut aus derselben Geometrie wie das Icon ([Brand]). Bild 0 ist genau der native Splash, daher
/// springt beim Übergang nichts. Bewegung „Premium“ mit dem Material Flüssigkeit: ruhige Kurven,
/// die Schichten schwappen leicht über ihr Ziel und beruhigen sich.
abstract final class LaunchAnimation {
  /// Fläche in px wie das Splash-Logo (1152 px als @4x = 288 pt).
  static const size = 1152.0;

  /// Kantenlänge der Kachel: 144 pt.
  static const tile = 576.0;

  static const fps = 60;
  static const duration = 1550;

  static final tileRect = Rect.fromCenter(center: const Offset(size / 2, size / 2), width: tile, height: tile);

  // Ablauf in Millisekunden.
  static const _fillStart = 40;
  static const _fillStagger = 100;
  static const _fillDuration = 560;
  static const _curveStart = 820;
  static const _curveEnd = 1060;
  static const _dotStart = 1020;
  static const _dotPeak = 1180;
  static const _dotSettle = 1320;
  static const _forecastStart = 1150;
  static const _forecastEnd = 1400;
  static const _rippleEnd = 1500;
  static const _breathPeak = 1160;
  static const _breathEnd = 1420;
  static const _sheenStart = 980;
  static const _sheenEnd = 1500;

  /// Schritt der Keyframes (in Bildern) für die schwappenden Oberflächen.
  static const _slosh = 2;

  /// Höhe der leeren Schichten (unter dem Haus, im Einheitsquadrat).
  static const _empty = 0.86;

  /// Einheitliche Kurven (kubische Bézier): [_enter] bremst sanft ab (Signatur für Auftritte),
  /// [_glide] beschleunigt und bremst (Bewegung auf der Fläche, die Kurve zeichnet sich).
  static const _enter = (0.2, 0.0, 0.0, 1.0);
  static const _glide = (0.4, 0.0, 0.2, 1.0);
  static const _linear = (0.0, 0.0, 1.0, 1.0);

  static const _null = 1;

  static Map<String, Object?> build() {
    final box = tileRect;
    final s = box.width;
    final today = Brand.at(box, Brand.today);
    final (past, forecast) = Brand.curve();
    final inside = [_mask(Brand.inside(), box)];

    final dotScale = _anim([
      (_dotStart, [0, 0], _enter),
      (_dotPeak, [112, 112], _glide),
      (_dotSettle, [100, 100], null),
    ]);

    final layers = <Map<String, Object?>>[
      _layer(
        2,
        'Glanz',
        [
          _group(
            'Band',
            [
              _rect(_static([0.26 * s, 1.4 * s]), _static([0, 0]), 0),
              _gradientFill(
                start: Offset(-0.13 * s, 0),
                end: Offset(0.13 * s, 0),
                colors: [(0, Brand.white), (1, Brand.white)],
                alphas: [(0, 0), (0.5, 0.22), (1, 0)],
              ),
            ],
            position: _anim([
              (_sheenStart, [box.left + 0.05 * s, box.center.dy], _glide),
              (_sheenEnd, [box.right - 0.05 * s, box.center.dy], null),
            ]),
            rotation: 24,
          ),
        ],
        masks: inside,
      ),
      _layer(3, 'Punkt', [
        _group('Punkt', [_ellipse(today, Brand.dot * 2 * s), _fill(Brand.white)], anchor: today, position: _static([today.dx, today.dy]), scale: dotScale),
      ]),
      _layer(4, 'Hof', [
        _group(
          'Hof',
          [_ellipse(today, Brand.halo * 2 * s), _fill(Brand.white, opacity: 35)],
          anchor: today,
          position: _static([today.dx, today.dy]),
          scale: _anim([(_dotStart + 40, [40, 40], _enter), (_dotSettle - 40, [100, 100], null)]),
          opacity: _anim([(_dotStart + 40, [0], _enter), (_dotSettle - 40, [100], null)]),
        ),
      ]),
      _layer(5, 'Welle', [
        _group(
          'Welle',
          [_ellipse(today, Brand.halo * 2 * s), _stroke(Brand.white, 0.012 * s)],
          anchor: today,
          position: _static([today.dx, today.dy]),
          scale: _anim([(_dotStart + 60, [100, 100], _enter), (_rippleEnd, [220, 220], null)]),
          // Vor dem Aufsetzen unsichtbar: Lottie hält vor dem ersten Keyframe dessen Wert.
          opacity: _anim([(_dotStart + 60, [0], _enter), (_dotStart + 110, [70], _enter), (_rippleEnd, [0], null)]),
        ),
      ]),
      _layer(
        6,
        'Kurve',
        [
          _group('Prognose', [
            _shape(forecast, box),
            _trim(_anim([(_forecastStart, [0], _glide), (_forecastEnd, [100], null)])),
            _stroke(Brand.white, Brand.line * s, dashes: _dashes(s)),
          ]),
          _group('Verlauf', [
            _shape(past, box),
            _trim(_anim([(_curveStart, [0], _glide), (_curveEnd, [100], null)])),
            _stroke(Brand.white, Brand.line * s),
          ]),
        ],
        masks: inside,
      ),
      _frameLayer(7, box),
      _layer(
        8,
        'Schichten',
        [
          // Erste Gruppe liegt oben: Wasser über Heizung über Strom, jede reicht bis unter das Haus.
          for (var i = 0; i < Brand.layers.length; i++) _liquid(box, i),
        ],
        masks: inside,
      ),
      ..._houseLayers(9, box),
    ];

    return {
      'v': '5.7.4',
      'fr': fps,
      'ip': 0,
      'op': _frame(duration),
      'w': size,
      'h': size,
      'nm': 'Kostenkurve Start',
      'ddd': 0,
      'assets': <Object>[],
      'layers': [
        // Unsichtbarer Träger: Die Kachel atmet einmal, wenn der Punkt aufsetzt – alles atmet mit.
        {
          'ddd': 0,
          'ind': _null,
          'ty': 3,
          'nm': 'Takt',
          'sr': 1,
          'ks': _transform(
            anchor: _static([size / 2, size / 2, 0]),
            position: _static([size / 2, size / 2, 0]),
            scale: _anim([
              (_dotStart + 20, [100, 100, 100], _enter),
              (_breathPeak, [101.5, 101.5, 100], _glide),
              (_breathEnd, [100, 100, 100], null),
            ]),
          ),
          'ao': 0,
          'ip': 0,
          'op': _frame(duration),
          'st': 0,
          'bm': 0,
        },
        ...layers,
      ],
    };
  }

  /// Rahmen des Hauses – steht still.
  static Map<String, Object?> _frameLayer(int ind, Rect box, {int? until}) => _layer(
    ind,
    'Rahmen',
    [
      _group('Rahmen', [_shape(Brand.house(), box), _stroke(Brand.white, Brand.frame * box.width)]),
    ],
    until: until,
  );

  /// Unter den Schichten: Glas, Schatten des Hauses, Kachel und ihr Schatten (Ebenen ab [ind]).
  static List<Map<String, Object?>> _houseLayers(int ind, Rect box, {int? until}) {
    final s = box.width;
    final house = Brand.house();
    return [
      _layer(
        ind,
        'Glas',
        [
          _group('Spiegelung', [_shape(Brand.reflection(), box), _fill(Brand.white, opacity: 16)]),
          _group('Glas', [
            _shape(Brand.inside(), box),
            _gradientFill(
              start: Brand.at(box, const Offset(0.5, 0.18)),
              end: Brand.at(box, const Offset(0.5, 0.83)),
              colors: [(0, Brand.glass[0]), (1, Brand.glass[1])],
            ),
          ]),
        ],
        until: until,
      ),
      _layer(
        ind + 1,
        'Hausschatten',
        [
          _group('Rahmen', [_shape(house, box), _stroke(Brand.shadow, Brand.frame * s, opacity: Brand.shadowOpacity * 100)]),
          _group('Fläche', [_shape(Brand.inside(), box), _shade(Brand.shadowOpacity)]),
        ],
        offset: Offset(0, Brand.shadowOffset * s),
        blur: Brand.shadowBlur * s,
        until: until,
      ),
      _layer(
        ind + 2,
        'Kachel',
        [
          _group('Licht', [
            _path(Brand.squirclePoints(box)),
            _gradientFill(
              start: box.topLeft + Offset(s * 0.22, s * 0.08),
              end: box.topLeft + Offset(s * 0.22 + s * 0.95, s * 0.08),
              colors: [(0, Brand.white), (1, Brand.white)],
              alphas: [(0, 0.12), (1, 0)],
              radial: true,
            ),
          ]),
          _group('Verlauf', [
            _path(Brand.squirclePoints(box)),
            _gradientFill(
              start: box.topLeft + Offset(s * 0.1, 0),
              end: box.bottomRight - Offset(s * 0.1, 0),
              colors: [(0, Brand.gradient[0]), (0.5, Brand.gradient[1]), (1, Brand.gradient[2])],
            ),
          ]),
        ],
        until: until,
      ),
      _layer(
        ind + 3,
        'Kachelschatten',
        [
          _group('Schatten', [_path(Brand.squirclePoints(box)), _shade(0.26)]),
        ],
        offset: Offset(0, 0.03 * s),
        blur: 0.05 * s,
        until: until,
      ),
    ];
  }

  static Map<String, Object?> _liquid(Rect box, int i) =>
      _liquidGroup(box, i, _fillKeys(box, i, start: _fillStart + i * _fillStagger, duration: _fillDuration));

  /// Schicht [i] fließt von unten ein: steigt mit sanftem Abbremsen, schwappt (Wellen und leichtes
  /// Kippen, beides klingt ab) und kommt genau auf der Form des Icons zur Ruhe. Keyframes ab [start]
  /// über [duration] ms; der letzte ist die fertige Schicht.
  static List<(int, Map<String, Object?>, (double, double, double, double)?)> _fillKeys(Rect box, int i, {required int start, required int duration}) {
    final layer = Brand.layers[i];
    final phase = i * 1.7;

    BezierShape surface(double u) {
      final rise = _ease(u, _enter);
      final calm = math.pow(1 - u, 1.6).toDouble();
      // Erst nach dem Einschwappen voll schwingen, damit die Fläche nicht schon unten zappelt.
      final swell = math.min(u * 5, 1.0) * calm;
      return BezierShape.smooth([
        for (var k = 0; k < Brand.layerXs.length; k++)
          Offset(
            Brand.layerXs[k],
            _empty +
                (layer.top[k] - _empty) * rise +
                swell * (0.03 * math.sin(2 * math.pi * (1.3 * Brand.layerXs[k] - 2.2 * u) + phase) + 0.14 * (Brand.layerXs[k] - 0.5) * math.sin(2 * math.pi * 1.4 * u + phase)),
          ),
      ]).closedDownTo(0.95);
    }

    final keys = <(int, Map<String, Object?>, (double, double, double, double)?)>[];
    final steps = (duration * fps / 1000 / _slosh).round();
    for (var k = 0; k <= steps; k++) {
      final u = k / steps;
      keys.add((start + (u * duration).round(), _shapeValue(k == steps ? Brand.layerArea(i) : surface(u), box), k == steps ? null : _linear));
    }
    return keys;
  }

  /// Leere Schicht: flach unter dem Haus, wie vor dem Einfließen.
  static BezierShape _drained() => BezierShape.smooth([for (final x in Brand.layerXs) Offset(x, _empty)]).closedDownTo(0.95);

  static Map<String, Object?> _liquidGroup(Rect box, int i, List<(int, Map<String, Object?>, (double, double, double, double)?)> keys) {
    final layer = Brand.layers[i];
    final top = layer.top.reduce(math.min);
    return _group('Schicht ${i + 1}', [
      {'ty': 'sh', 'ks': _animShape(keys)},
      _gradientFill(
        start: Brand.at(box, Offset(0, top)),
        end: Brand.at(box, const Offset(0, 0.83)),
        colors: [(0, layer.colors[0]), (1, layer.colors[1])],
      ),
      // Weiße Fuge an der Oberkante; Seiten und Boden liegen außerhalb des Glases.
      _stroke(Brand.white, 0.01 * box.width, opacity: 50),
    ]);
  }

  /// Kubische Bézier-Kurve (x1, y1, x2, y2) bei [u] ausgewertet.
  static double _ease(double u, (double, double, double, double) curve) {
    final (x1, y1, x2, y2) = curve;
    double bez(double t, double a, double b) => 3 * (1 - t) * (1 - t) * t * a + 3 * (1 - t) * t * t * b + t * t * t;
    var lo = 0.0, hi = 1.0;
    for (var n = 0; n < 40; n++) {
      final mid = (lo + hi) / 2;
      bez(mid, x1, x2) < u ? lo = mid : hi = mid;
    }
    return bez((lo + hi) / 2, y1, y2);
  }

  static List<Map<String, Object?>> _dashes(double s) {
    final (on, off) = Brand.dash;
    return [
      {'n': 'd', 'nm': 'Strich', 'v': _static(_r(on * s))},
      {'n': 'g', 'nm': 'Lücke', 'v': _static(_r(off * s))},
      // Wie im Icon: erster Strich mit Abstand zum Punkt.
      {'n': 'o', 'nm': 'Versatz', 'v': _static(_r(-(off + Brand.halo * 0.5) * s))},
    ];
  }

  static Map<String, Object?> _shapeValue(BezierShape shape, Rect box) {
    Offset p(Offset u) => Brand.at(box, u);
    Offset t(Offset u) => Offset(u.dx * box.width, u.dy * box.height);
    return {
      'i': _points([for (final x in shape.ins) t(x)]),
      'o': _points([for (final x in shape.outs) t(x)]),
      'v': _points([for (final x in shape.vertices) p(x)]),
      'c': shape.closed,
    };
  }

  static Map<String, Object?> _shape(BezierShape shape, Rect box) => {'ty': 'sh', 'ks': _static(_shapeValue(shape, box))};

  /// Geschlossener, weicher Pfad durch [dense]: gleichmäßig nach Länge ausgedünnt, Tangenten nach
  /// Catmull-Rom. Für die Kachel reichen so 96 statt 720 Punkte.
  static Map<String, Object?> _path(List<Offset> dense, {int count = 96}) {
    final points = _resample(dense, count);
    final ins = <Offset>[], outs = <Offset>[];
    for (var k = 0; k < count; k++) {
      final tangent = (points[(k + 1) % count] - points[(k - 1 + count) % count]) / 6;
      ins.add(-tangent);
      outs.add(tangent);
    }
    return {
      'ty': 'sh',
      'ks': _static({'i': _points(ins), 'o': _points(outs), 'v': _points(points), 'c': true}),
    };
  }

  static List<Offset> _resample(List<Offset> dense, int count) {
    final lengths = [0.0];
    for (var k = 1; k <= dense.length; k++) {
      lengths.add(lengths.last + (dense[k % dense.length] - dense[k - 1]).distance);
    }
    final total = lengths.last;
    final result = <Offset>[];
    var j = 0;
    for (var k = 0; k < count; k++) {
      final target = total * k / count;
      while (lengths[j + 1] < target) {
        j++;
      }
      final t = (target - lengths[j]) / (lengths[j + 1] - lengths[j]);
      result.add(Offset.lerp(dense[j], dense[(j + 1) % dense.length], t)!);
    }
    return result;
  }

  static Map<String, Object?> _mask(BezierShape shape, Rect box) => {
    'inv': false,
    'mode': 'a',
    'pt': _static(_shapeValue(shape, box)),
    'o': _static(100),
    'x': _static(0),
  };

  static Map<String, Object?> _layer(
    int ind,
    String name,
    List<Map<String, Object?>> shapes, {
    List<Map<String, Object?>>? masks,
    Offset offset = Offset.zero,
    double? blur,
    int? until,
  }) => {
    'ddd': 0,
    'ind': ind,
    'ty': 4,
    'nm': name,
    'parent': _null,
    'sr': 1,
    'ks': _transform(position: _static([_r(offset.dx), _r(offset.dy), 0])),
    'ao': 0,
    if (masks != null) 'hasMask': true,
    'masksProperties': ?masks,
    // Gaußscher Weichzeichner; Lottie rechnet Radius r in Sigma = 0,577·r + 0,5 um.
    if (blur != null)
      'ef': [
        {
          'ty': 29,
          'nm': 'Gaussian Blur',
          'en': 1,
          'ef': [
            {'ty': 0, 'nm': 'Blurriness', 'v': _static(_r((blur - 0.5) / 0.57735))},
          ],
        },
      ],
    'shapes': shapes,
    'ip': 0,
    'op': _frame(until ?? duration),
    'st': 0,
    'bm': 0,
  };

  static Map<String, Object?> _transform({Map<String, Object?>? anchor, Map<String, Object?>? position, Map<String, Object?>? scale}) => {
    'o': _static(100),
    'r': _static(0),
    'p': position ?? _static([0, 0, 0]),
    'a': anchor ?? _static([0, 0, 0]),
    's': scale ?? _static([100, 100, 100]),
  };

  static Map<String, Object?> _group(
    String name,
    List<Map<String, Object?>> items, {
    Offset anchor = Offset.zero,
    Map<String, Object?>? position,
    Map<String, Object?>? scale,
    Map<String, Object?>? opacity,
    double rotation = 0,
  }) => {
    'ty': 'gr',
    'nm': name,
    'it': [
      ...items,
      {
        'ty': 'tr',
        'p': position ?? _static([0, 0]),
        'a': _static([_r(anchor.dx), _r(anchor.dy)]),
        's': scale ?? _static([100, 100]),
        'r': _static(rotation),
        'o': opacity ?? _static(100),
        'sk': _static(0),
        'sa': _static(0),
      },
    ],
  };

  static Map<String, Object?> _rect(Map<String, Object?> size, Map<String, Object?> position, double radius) => {
    'ty': 'rc',
    'd': 1,
    's': size,
    'p': position,
    'r': _static(_r(radius)),
  };

  static Map<String, Object?> _ellipse(Offset center, double diameter) => {
    'ty': 'el',
    'd': 1,
    's': _static([_r(diameter), _r(diameter)]),
    'p': _static([_r(center.dx), _r(center.dy)]),
  };

  static Map<String, Object?> _fill(Color color, {double opacity = 100}) => {
    'ty': 'fl',
    'c': _static(_color(color)),
    'o': _static(_r(opacity)),
    'r': 1,
  };

  /// Fläche in [Brand.shadow] für weichgezeichnete Schatten – als Verlauf mit einer Farbe, denn bei
  /// einfachen Flächen wendet lottie 3.6 den Weichzeichner nur im ersten Bild an.
  static Map<String, Object?> _shade(double opacity) => _gradientFill(
    start: Offset.zero,
    end: const Offset(1, 0),
    colors: [(0, Brand.shadow), (1, Brand.shadow)],
    alphas: [(0, opacity), (1, opacity)],
  );

  static Map<String, Object?> _stroke(Color color, double width, {double opacity = 100, List<Map<String, Object?>>? dashes}) => {
    'ty': 'st',
    'c': _static(_color(color)),
    'o': _static(_r(opacity)),
    'w': _static(_r(width)),
    'lc': 2,
    'lj': 2,
    'ml': 4,
    'd': ?dashes,
  };

  static Map<String, Object?> _gradient(List<(double, Color)> colors, List<(double, double)>? alphas) => {
    'p': colors.length,
    'k': _static([
      for (final (at, c) in colors) ...[at, ..._color(c).take(3)],
      for (final (at, a) in alphas ?? [(0.0, 1.0), (1.0, 1.0)]) ...[at, a],
    ]),
  };

  static Map<String, Object?> _gradientFill({
    required Offset start,
    required Offset end,
    required List<(double, Color)> colors,
    List<(double, double)>? alphas,
    bool radial = false,
  }) => {
    'ty': 'gf',
    'o': _static(100),
    'r': 1,
    'g': _gradient(colors, alphas),
    's': _static([_r(start.dx), _r(start.dy)]),
    'e': _static([_r(end.dx), _r(end.dy)]),
    't': radial ? 2 : 1,
    if (radial) 'h': _static(0),
    if (radial) 'a': _static(0),
  };

  static Map<String, Object?> _trim(Map<String, Object?> end) => {
    'ty': 'tm',
    's': _static(0),
    'e': end,
    'o': _static(0),
    'm': 1,
  };

  static Map<String, Object?> _static(Object value) => {'a': 0, 'k': value};

  /// Keyframes (Zeit in ms, Wert, Kurve bis zum nächsten Keyframe; am letzten `null`).
  static Map<String, Object?> _anim(List<(int, List<num>, (double, double, double, double)?)> keys) => _keyframes([
    for (final (ms, value, ease) in keys) (ms, [for (final v in value) _r(v.toDouble())], ease),
  ]);

  static Map<String, Object?> _animShape(List<(int, Map<String, Object?>, (double, double, double, double)?)> keys) => _keyframes([
    for (final (ms, shape, ease) in keys) (ms, [shape], ease),
  ]);

  static Map<String, Object?> _keyframes(List<(int, List<Object>, (double, double, double, double)?)> keys) => {
    'a': 1,
    'k': [
      for (final (ms, value, ease) in keys)
        {
          't': _frame(ms),
          's': value,
          if (ease != null) 'o': {'x': [ease.$1], 'y': [ease.$2]},
          if (ease != null) 'i': {'x': [ease.$3], 'y': [ease.$4]},
        },
    ],
  };

  static double _frame(int ms) => _r(ms * fps / 1000);

  static List<double> _color(Color c) => [_r(c.r), _r(c.g), _r(c.b), 1];

  static List<List<double>> _points(List<Offset> points) => [
    for (final p in points) [_r(p.dx), _r(p.dy)],
  ];

  static double _r(double v) => (v * 1000).round() / 1000;
}
