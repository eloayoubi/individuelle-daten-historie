import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';

/// Durchscheinende, weichgezeichnete Fläche („Liquid Glass“) für schwebende Leisten.
class GlassSurface extends StatelessWidget {
  const GlassSurface({super.key, required this.child, this.radius = Radii.pill});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: c.glassBorder, width: 0.5),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: Motion.glassBlur, sigmaY: Motion.glassBlur),
          child: DecoratedBox(
            decoration: ShapeDecoration(color: c.glass, shape: shape),
            child: child,
          ),
        ),
      ),
    );
  }
}
