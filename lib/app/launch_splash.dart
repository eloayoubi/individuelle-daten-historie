import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/core.dart';

/// Startanimation über der App: Die Kachel vom nativen Splash zeichnet Monatsbalken, Kurve und den
/// Punkt „heute“ – das App-Icon entsteht –, dann tritt sie zurück und gibt die App frei.
///
/// Die App darunter baut sich sofort auf und lädt, während die Animation läuft. Die Animation
/// erzeugt `tool/branding/render_icon_test.dart`; ihr erstes Bild ist der native Splash.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.composition, required this.child});

  /// Vorab geladen ([load]), damit schon das erste Bild steht – sonst blitzt zwischen nativem Splash
  /// und Animation der leere Hintergrund auf. Ohne Animation (Tests, Ladefehler) gleich die App.
  final LottieComposition? composition;
  final Widget child;

  static const asset = 'assets/branding/launch_animation.json';

  /// Kantenlänge wie das Logo des nativen Splashs (1152 px als @4x), damit die Kachel nicht springt.
  static const size = 288.0;

  /// Ausblenden: die Kachel kommt leicht näher, die App rückt an ihren Platz.
  static const exitScale = 1.04;
  static const appScale = 0.98;

  static Future<LottieComposition?> load() async {
    try {
      return await AssetLottie(asset).load();
    } on Object {
      // Ohne Animation startet die App wie bisher.
      return null;
    }
  }

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> with TickerProviderStateMixin {
  late final _draw = AnimationController(vsync: this, duration: widget.composition?.duration);
  late final _exit = AnimationController(vsync: this, duration: Motion.normal, value: widget.composition == null ? 1 : 0);
  late final _leave = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);
  late final _arrive = CurvedAnimation(parent: _exit, curve: Motion.curve);
  late var _visible = widget.composition != null;
  var _started = false;
  var _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible && !_started) {
      _started = true;
      _reduceMotion = MediaQuery.disableAnimationsOf(context);
      _play();
    }
  }

  Future<void> _play() async {
    // Weniger Bewegung: gleich das fertige Icon, dann nur ausblenden.
    if (_reduceMotion) {
      _draw.value = 1;
    } else {
      await _draw.forward();
    }
    if (!mounted) return;
    await _exit.forward();
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _leave.dispose();
    _arrive.dispose();
    _draw.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composition = widget.composition;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Immer an derselben Stelle im Baum, damit die App beim Ausblenden nicht neu startet.
        ScaleTransition(
          scale: Tween(begin: _reduceMotion ? 1.0 : LaunchSplash.appScale, end: 1.0).animate(_arrive),
          child: widget.child,
        ),
        if (_visible && composition != null)
          ExcludeSemantics(
            child: FadeTransition(
              opacity: ReverseAnimation(_leave),
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: _reduceMotion ? 1.0 : LaunchSplash.exitScale).animate(_leave),
                child: ColoredBox(
                  color: context.colors.background,
                  child: Center(
                    child: Lottie(
                      composition: composition,
                      controller: _draw,
                      width: LaunchSplash.size,
                      height: LaunchSplash.size,
                      frameRate: FrameRate.max,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
