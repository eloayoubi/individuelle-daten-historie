import 'package:flutter/widgets.dart';

import '../theme/dimensions.dart';

/// Antipp-Rückmeldung wie auf iOS: kurz kleiner und blasser statt Material-Welle.
/// Ohne [onTap] ist das Kind einfach sichtbar, ohne Reaktion.
class AppPressable extends StatefulWidget {
  const AppPressable({super.key, required this.child, this.onTap, this.semanticLabel, this.scale = Motion.pressedScale});

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double scale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  var _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.fast,
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: _down ? Motion.pressedOpacity : 1,
            duration: Motion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
