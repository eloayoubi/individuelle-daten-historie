import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/core.dart';
import '../data/app_release.dart';
import '../data/installed_app.dart';

/// Pflicht-Update: Dieser Build ist veraltet, weiter geht es erst mit dem neuen. Oben lädt die
/// Animation ein Update ins App-Icon, darunter Titel, Erklärung, der Weg zu TestFlight (bzw. App
/// Store) und die Build-Nummern zum Vergleichen.
///
/// Kein Zurück und kein „Später“ – `ForceUpdateGate` legt die Seite über alles.
class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key, required this.installed, required this.release});

  final InstalledApp installed;
  final AppRelease release;

  /// Erzeugt von `tool/branding/render_icon_test.dart` (UpdateAnimation).
  static const asset = 'assets/branding/update_animation.json';

  /// Marker im Lottie: Ring voll, Haus gefüllt, Haken gesetzt – das Bild bei „Weniger Bewegung“.
  static const still = 'fertig';

  /// Kantenlänge der Animation; die Kachel darin ist halb so groß (132 pt).
  static const size = 264.0;

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> with TickerProviderStateMixin {
  late final _loop = AnimationController(vsync: this);

  /// Auftritt: erst die Animation, dann Titel, Text, Button und Build-Nummern nacheinander von unten.
  late final _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: _stagger * 4 + _rise));
  late final _hero = CurvedAnimation(parent: _enter, curve: const Interval(0, 0.6, curve: Motion.curve));
  late final _steps = [
    for (var i = 1; i <= 4; i++)
      CurvedAnimation(
        parent: _enter,
        curve: Interval(i * _stagger / _enter.duration!.inMilliseconds, (i * _stagger + _rise) / _enter.duration!.inMilliseconds, curve: Motion.curve),
      ),
  ];
  var _reduceMotion = false;

  static const _stagger = 70;
  static const _rise = 500;
  static const _riseDistance = 16.0;

  @override
  void initState() {
    super.initState();
    // Die Seite liegt über der App: Eine offene Tastatur darunter soll mit verschwinden.
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _enter.value = 1;
    } else if (_enter.isDismissed) {
      _enter.forward();
    }
  }

  void _onLoaded(LottieComposition composition) {
    _loop.duration = composition.duration;
    if (_reduceMotion) {
      _loop.value = composition.getMarker(ForceUpdatePage.still)?.start ?? 1;
    } else {
      _loop.repeat();
    }
  }

  Future<void> _open() => launchUrl(Uri.parse(widget.release.url ?? AppConfig.testFlightUrl), mode: LaunchMode.externalApplication);

  /// Schritt [step] des Auftritts: blendet ein und steigt an seinen Platz.
  Widget _rising(int step, Widget child) {
    final animation = _steps[step - 1];
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(offset: Offset(0, _riseDistance * (1 - animation.value)), child: child),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.dispose();
    }
    _hero.dispose();
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final appStore = widget.installed.channel == ReleaseChannel.appStore;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: LayoutBuilder(
          // Mit großer Schrift scrollbar, sonst mittig mit dem Button unten.
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: _hero,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.92, end: 1.0).animate(_hero),
                        child: ExcludeSemantics(
                          child: Lottie.asset(
                            ForceUpdatePage.asset,
                            controller: _loop,
                            onLoaded: _onLoaded,
                            width: ForceUpdatePage.size,
                            height: ForceUpdatePage.size,
                            frameRate: FrameRate.max,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.l),
                    _rising(
                      1,
                      Semantics(header: true, child: AppText(l10n.forceUpdateTitle, style: (t) => t.title1, align: TextAlign.center)),
                    ),
                    const SizedBox(height: Spacing.s),
                    _rising(
                      2,
                      AppText(
                        appStore ? l10n.forceUpdateBodyAppStore : l10n.forceUpdateBodyTestFlight,
                        style: (t) => t.body,
                        color: c.textSecondary,
                        align: TextAlign.center,
                      ),
                    ),
                    const Spacer(flex: 4),
                    const SizedBox(height: Spacing.xxl),
                    _rising(
                      3,
                      AppButton(
                        label: appStore ? l10n.forceUpdateAppStore : l10n.forceUpdateTestFlight,
                        icon: CupertinoIcons.arrow_down_circle_fill,
                        onPressed: _open,
                      ),
                    ),
                    const SizedBox(height: Spacing.m),
                    _rising(
                      4,
                      AppText(
                        l10n.forceUpdateBuilds('${widget.installed.build}', '${widget.release.build}'),
                        style: (t) => t.footnote,
                        color: c.textTertiary,
                        align: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Spacing.l),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
