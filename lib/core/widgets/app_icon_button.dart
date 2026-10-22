import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_pressable.dart';

/// Runder 44-pt-Button (Kopfzeile, Sheets). [filled] zeigt die Akzentfarbe für die Hauptaktion.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.filled = false,
    this.size = Sizes.tap,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background ?? (filled ? c.accent : c.surface), shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.45, color: foreground ?? (filled ? c.onAccent : c.textPrimary)),
      ),
    );
  }
}
