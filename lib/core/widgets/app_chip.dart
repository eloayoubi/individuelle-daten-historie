import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_text.dart';

/// Kleine Kapsel für Status und Kennzahlen (`+4,2 %`, `Geteilt mit Anna`).
/// Standard: neutrale Füllung; [background]/[foreground] für Akzent- und Spotlight-Varianten.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.icon, this.background, this.foreground});

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s, vertical: Spacing.xxs),
      decoration: ShapeDecoration(color: background ?? context.colors.fill, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.xxs,
        children: [
          if (icon != null) Icon(icon, size: 12, color: fg),
          Flexible(child: AppText(label, style: (t) => t.captionEmphasized, color: fg, maxLines: 1)),
        ],
      ),
    );
  }
}
