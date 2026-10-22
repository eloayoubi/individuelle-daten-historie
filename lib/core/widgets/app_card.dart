import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_pressable.dart';

/// Karte auf dem gruppierten Hintergrund, mit großen iOS-Radien und ohne Schatten.
/// Dunkle Hervorhebung: `color: context.colors.spotlight` (Schrift dann `onSpotlight`).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.l),
    this.radius = Radii.card,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      scale: 0.985,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color ?? context.colors.surface,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
