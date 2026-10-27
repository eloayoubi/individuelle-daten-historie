part of 'launch_animation.dart';

/// Animation des Pflicht-Updates als Lottie, in Schleife: Ein Ring um die Kachel lädt, Pfeile fallen
/// ins leere Glashaus, und mit dem Fortschritt steigen Wasser, Heizung und Strom. Ist der Ring voll,
/// wird er grün, die Kostenkurve zeichnet sich bis „heute“, und an der Ecke setzt ein Haken auf – die
/// neue Version ist da. Kurz Ruhe, dann läuft das Haus leer, und alles beginnt von vorn.
///
/// Geometrie und Bewegung wie die Startanimation ([LaunchAnimation]): ruhige Kurven, die Flüssigkeit
/// schwappt; nur der Haken springt kurz über sein Ziel. Bild 0 und das letzte Bild sind gleich, damit
/// die Schleife nicht springt. Der Marker „fertig“ zeigt das Ruhebild für „Weniger Bewegung“.
abstract final class UpdateAnimation {
  static const size = LaunchAnimation.size;
  static const duration = 3600;
  static const marker = 'fertig';

  static final _tile = LaunchAnimation.tileRect;

  /// Pixel statt Einheitsquadrat: [BezierShape]s für Ring und Haken liegen in px auf der Fläche.
  static const _pixels = Rect.fromLTWH(0, 0, 1, 1);

  // Ablauf in Millisekunden.
  static const _load = 150;
  static const _loaded = 1550;
  static const _drops = [150, 550, 950];
  static const _drop = 600;
  static const _fillStart = 200;
  static const _fillStagger = 180;
  static const _fillDuration = 900;
  static const _greenStart = 1500;
  static const _greenEnd = 1650;
  static const _curveStart = 1480;
  static const _curveEnd = 1720;
  static const _forecastStart = 1640;
  static const _forecastEnd = 1900;
  static const _dotStart = 1640;
  static const _dotPeak = 1800;
  static const _dotSettle = 1940;
  static const _rippleEnd = 2120;
  static const _badgeStart = 1600;
  static const _badgePeak = 1760;
  static const _badgeSettle = 1900;
  static const _checkStart = 1700;
  static const _checkEnd = 1900;
  static const _breathPeak = 1800;
  static const _breathEnd = 2060;
  static const _sheenStart = 1750;
  static const _sheenEnd = 2250;
  static const _done = 2400;
  static const _leave = 2900;
  static const _gone = 3150;
  static const _drainStart = 2980;
  static const _drainStagger = 60;
  static const _drainDuration = 420;

  /// Unsichtbar zurückstellen (Ring und Kurve schon ausgeblendet), damit Bild 0 wieder passt.
  static const _reset = 3250;

  static const _enter = LaunchAnimation._enter;
  static const _glide = LaunchAnimation._glide;
  static const _linear = LaunchAnimation._linear;

  /// Abgang beschleunigt (Material 3 „Accelerate“), auch der Fall der Pfeile.
  static const _accelerate = (0.3, 0.0, 1.0, 1.0);

  static const _green = Palette.green;

  /// Ring um die Kachel: Radius und Stärke relativ zur Kachel.
  static const _ring = 0.69;
  static const _ringWidth = 0.032;

  /// Haken an der Ecke oben rechts: Versatz der Mitte, Radius, Rand und Strich relativ zur Kachel.
  static const _badgeOffset = 0.34;
  static const _badge = 0.13;
  static const _badgeBorder = 0.022;
  static const _checkWidth = 0.032;

  static Map<String, Object?> build() {
    final box = _tile;
    final s = box.width;
    final center = box.center;
    final today = Brand.at(box, Brand.today);
    final badge = center + Offset(_badgeOffset * s, -_badgeOffset * s);
    final (past, forecast) = Brand.curve();
    final inside = [LaunchAnimation._mask(Brand.inside(), box)];
    final ring = _circle(center, _ring * s);

    final layers = <Map<String, Object?>>[
      _layer(2, 'Hakenwelle', [
        LaunchAnimation._group(
          'Welle',
          [_ellipse(badge, _badge * 2 * s), LaunchAnimation._stroke(_green, 0.016 * s)],
          anchor: badge,
          position: _static([badge.dx, badge.dy]),
          scale: _anim([(_checkStart + 20, [100, 100], _enter), (_rippleEnd + 40, [170, 170], null)]),
          opacity: _anim([(_checkStart + 20, [0], _enter), (_checkStart + 70, [60], _enter), (_rippleEnd + 40, [0], null)]),
        ),
      ]),
      _layer(3, 'Haken', [
        LaunchAnimation._group(
          'Haken',
          [
            LaunchAnimation._group('Zeichen', [
              LaunchAnimation._shape(_check(badge, _badge * s), _pixels),
              LaunchAnimation._trim(
                _anim([(_checkStart, [0], _glide), (_checkEnd, [100], _linear), (_reset, [100], _linear), (_reset + 10, [0], null)]),
              ),
              LaunchAnimation._stroke(Brand.white, _checkWidth * s),
            ]),
            LaunchAnimation._group('Plakette', [
              _ellipse(badge, _badge * 2 * s),
              LaunchAnimation._stroke(Brand.white, _badgeBorder * s),
              LaunchAnimation._fill(_green),
            ]),
          ],
          anchor: badge,
          position: _static([badge.dx, badge.dy]),
          // Springt kurz über sein Ziel: die eine verspielte Stelle, der Erfolg.
          scale: _anim([
            (_badgeStart, [0, 0], _enter),
            (_badgePeak, [118, 118], _glide),
            (_badgeSettle, [100, 100], _linear),
            (_leave, [100, 100], _accelerate),
            (_gone - 30, [0, 0], null),
          ]),
        ),
      ]),
      _layer(4, 'Ring', [
        LaunchAnimation._group(
          'Fortschritt',
          [
            LaunchAnimation._shape(ring, _pixels),
            LaunchAnimation._trim(_anim([(_load, [0], _glide), (_loaded, [100], _linear), (_reset, [100], _linear), (_reset + 10, [0], null)])),
            {
              'ty': 'st',
              'c': _anim([
                (_greenStart, LaunchAnimation._color(Brand.indigo), _glide),
                (_greenEnd, LaunchAnimation._color(_green), _linear),
                (_reset, LaunchAnimation._color(_green), _linear),
                (_reset + 10, LaunchAnimation._color(Brand.indigo), null),
              ]),
              'o': _static(100),
              'w': _static(_r(_ringWidth * s)),
              'lc': 2,
              'lj': 2,
              'ml': 4,
            },
          ],
          opacity: _anim([(_load - 10, [0], _linear), (_load + 10, [100], _linear), (_leave, [100], _accelerate), (_leave + 300, [0], null)]),
        ),
      ]),
      _layer(5, 'Ringspur', [
        // Hellerer Ton als der Fortschritt, damit die Spur auch auf Schwarz zu sehen ist.
        LaunchAnimation._group('Spur', [LaunchAnimation._shape(ring, _pixels), LaunchAnimation._stroke(Palette.indigoBright, _ringWidth * s, opacity: 26)]),
      ]),
      _layer(
        6,
        'Glanz',
        [
          LaunchAnimation._group(
            'Band',
            [
              LaunchAnimation._rect(_static([0.26 * s, 1.4 * s]), _static([0, 0]), 0),
              LaunchAnimation._gradientFill(
                start: Offset(-0.13 * s, 0),
                end: Offset(0.13 * s, 0),
                colors: [(0, Brand.white), (1, Brand.white)],
                alphas: [(0, 0), (0.5, 0.22), (1, 0)],
              ),
            ],
            position: _anim([
              (_sheenStart, [box.left + 0.05 * s, center.dy], _glide),
              (_sheenEnd, [box.right - 0.05 * s, center.dy], null),
            ]),
            rotation: 24,
          ),
        ],
        masks: inside,
      ),
      _layer(7, 'Punkt', [
        LaunchAnimation._group(
          'Punkt',
          [_ellipse(today, Brand.dot * 2 * s), LaunchAnimation._fill(Brand.white)],
          anchor: today,
          position: _static([today.dx, today.dy]),
          scale: _anim([
            (_dotStart, [0, 0], _enter),
            (_dotPeak, [112, 112], _glide),
            (_dotSettle, [100, 100], _linear),
            (_leave, [100, 100], _accelerate),
            (_gone, [0, 0], null),
          ]),
        ),
      ]),
      _layer(8, 'Hof', [
        LaunchAnimation._group(
          'Hof',
          [_ellipse(today, Brand.halo * 2 * s), LaunchAnimation._fill(Brand.white, opacity: 35)],
          anchor: today,
          position: _static([today.dx, today.dy]),
          scale: _anim([(_dotStart + 40, [40, 40], _enter), (_dotSettle - 40, [100, 100], _linear), (_leave, [100, 100], _accelerate), (_gone, [40, 40], null)]),
          opacity: _anim([(_dotStart + 40, [0], _enter), (_dotSettle - 40, [100], _linear), (_leave, [100], _accelerate), (_gone, [0], null)]),
        ),
      ]),
      _layer(9, 'Welle', [
        LaunchAnimation._group(
          'Welle',
          [_ellipse(today, Brand.halo * 2 * s), LaunchAnimation._stroke(Brand.white, 0.012 * s)],
          anchor: today,
          position: _static([today.dx, today.dy]),
          scale: _anim([(_dotStart + 60, [100, 100], _enter), (_rippleEnd, [220, 220], null)]),
          opacity: _anim([(_dotStart + 60, [0], _enter), (_dotStart + 110, [70], _enter), (_rippleEnd, [0], null)]),
        ),
      ]),
      _layer(
        10,
        'Kurve',
        [
          LaunchAnimation._group(
            'Prognose',
            [
              LaunchAnimation._shape(forecast, box),
              LaunchAnimation._trim(_drawn(_forecastStart, _forecastEnd)),
              LaunchAnimation._stroke(Brand.white, Brand.line * s, dashes: LaunchAnimation._dashes(s)),
            ],
            opacity: _fadeOut(),
          ),
          LaunchAnimation._group(
            'Verlauf',
            [
              LaunchAnimation._shape(past, box),
              LaunchAnimation._trim(_drawn(_curveStart, _curveEnd)),
              LaunchAnimation._stroke(Brand.white, Brand.line * s),
            ],
            opacity: _fadeOut(),
          ),
        ],
        masks: inside,
      ),
      _layer(11, 'Pfeile', [for (final (n, start) in _drops.indexed) _arrow(box, n, start)], masks: inside),
      LaunchAnimation._frameLayer(12, box, until: duration),
      _layer(
        13,
        'Schichten',
        [
          // Erste Gruppe liegt oben: Wasser über Heizung über Strom, jede reicht bis unter das Haus.
          for (var i = 0; i < Brand.layers.length; i++) _liquid(box, i),
        ],
        masks: inside,
      ),
      ...LaunchAnimation._houseLayers(14, box, until: duration),
    ];

    return {
      'v': '5.7.4',
      'fr': LaunchAnimation.fps,
      'ip': 0,
      'op': LaunchAnimation._frame(duration),
      'w': size,
      'h': size,
      'nm': 'Kostenkurve Update',
      'ddd': 0,
      'assets': <Object>[],
      'markers': [
        {'tm': LaunchAnimation._frame(_done), 'cm': marker, 'dr': 0},
      ],
      'layers': [
        // Unsichtbarer Träger: Alles atmet einmal, wenn Punkt und Haken aufsetzen.
        {
          'ddd': 0,
          'ind': LaunchAnimation._null,
          'ty': 3,
          'nm': 'Takt',
          'sr': 1,
          'ks': LaunchAnimation._transform(
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
          'op': LaunchAnimation._frame(duration),
          'st': 0,
          'bm': 0,
        },
        ...layers,
      ],
    };
  }

  /// Schicht [i] steigt mit dem Fortschritt (wie beim Start), bleibt bis zum Abgang und läuft dann
  /// beschleunigt leer – die oberste zuerst.
  static Map<String, Object?> _liquid(Rect box, int i) {
    final keys = LaunchAnimation._fillKeys(box, i, start: _fillStart + i * _fillStagger, duration: _fillDuration);
    final (end, full, _) = keys.removeLast();
    final drain = _drainStart + (Brand.layers.length - 1 - i) * _drainStagger;
    keys.addAll([
      (end, full, _linear),
      (drain, full, _accelerate),
      (drain + _drainDuration, LaunchAnimation._shapeValue(LaunchAnimation._drained(), box), null),
    ]);
    return LaunchAnimation._liquidGroup(box, i, keys);
  }

  /// Pfeil Nummer [n] fällt ab [start] durchs Dach und verblasst über der Flüssigkeit.
  static Map<String, Object?> _arrow(Rect box, int n, int start) {
    final s = box.width;
    return LaunchAnimation._group(
      'Pfeil ${n + 1}',
      [
        LaunchAnimation._shape(_polyline(const [Offset(0.5, 0.27), Offset(0.5, 0.4)]), box),
        LaunchAnimation._shape(_polyline(const [Offset(0.445, 0.345), Offset(0.5, 0.4), Offset(0.555, 0.345)]), box),
        LaunchAnimation._stroke(Brand.white, Brand.line * s),
      ],
      position: _anim([(start, [0, -0.05 * s], _accelerate), (start + _drop, [0, 0.06 * s], null)]),
      opacity: _anim([(start, [0], _enter), (start + 180, [100], _linear), (start + 380, [100], _glide), (start + _drop, [0], null)]),
    );
  }

  /// Strich von 0 auf 100 % zwischen [start] und [end]; zurückgestellt, wenn alles ausgeblendet ist.
  static Map<String, Object?> _drawn(int start, int end) =>
      _anim([(start, [0], _glide), (end, [100], _linear), (_reset, [100], _linear), (_reset + 10, [0], null)]);

  static Map<String, Object?> _fadeOut() => _anim([(_leave, [100], _accelerate), (_leave + 220, [0], null)]);

  /// Kreis im Uhrzeigersinn, Anfang oben – dort beginnt der Ring zu laden.
  static BezierShape _circle(Offset c, double r) {
    const k = 0.5523;
    return BezierShape(
      [c + Offset(0, -r), c + Offset(r, 0), c + Offset(0, r), c + Offset(-r, 0)],
      [Offset(-k * r, 0), Offset(0, -k * r), Offset(k * r, 0), Offset(0, k * r)],
      [Offset(k * r, 0), Offset(0, k * r), Offset(-k * r, 0), Offset(0, -k * r)],
      closed: true,
    );
  }

  /// Haken in der Plakette mit Mitte [c] und Radius [r].
  static BezierShape _check(Offset c, double r) => _polyline([c + Offset(-0.42 * r, 0.02 * r), c + Offset(-0.12 * r, 0.32 * r), c + Offset(0.45 * r, -0.3 * r)]);

  static BezierShape _polyline(List<Offset> points) => BezierShape(points, [for (final _ in points) Offset.zero], [for (final _ in points) Offset.zero], closed: false);

  static Map<String, Object?> _ellipse(Offset center, double diameter) => LaunchAnimation._ellipse(center, diameter);

  static Map<String, Object?> _layer(int ind, String name, List<Map<String, Object?>> shapes, {List<Map<String, Object?>>? masks}) =>
      LaunchAnimation._layer(ind, name, shapes, masks: masks, until: duration);

  static Map<String, Object?> _static(Object value) => LaunchAnimation._static(value);

  static Map<String, Object?> _anim(List<(int, List<num>, (double, double, double, double)?)> keys) => LaunchAnimation._anim(keys);

  static double _r(double v) => LaunchAnimation._r(v);
}
