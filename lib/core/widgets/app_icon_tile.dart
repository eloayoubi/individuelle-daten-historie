import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';

/// Farbiges Quadrat mit weißem Symbol, wie die Icons in den iOS-Einstellungen.
class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, required this.icon, required this.color, this.size = Sizes.iconTile});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(size * 0.28)),
      ),
      child: Icon(icon, size: size * 0.58, color: context.colors.onAccent),
    );
  }
}
