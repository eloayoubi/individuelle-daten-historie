import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_pressable.dart';
import 'app_text.dart';

/// Gefüllt (Hauptaktion), getönt (zweite Aktion), schlicht (nur Schrift) oder zerstörend
/// (rote Schrift, z. B. „Archivieren“), wie die iOS-Buttons.
enum AppButtonVariant { filled, tinted, plain, destructive }

/// Kapsel-Button in voller Breite (oder [expand] `false` für so breit wie der Inhalt).
class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, this.onPressed, this.variant = AppButtonVariant.filled, this.icon, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final (background, foreground) = switch (variant) {
      AppButtonVariant.filled => (enabled ? c.accent : c.fill, enabled ? c.onAccent : c.textTertiary),
      AppButtonVariant.tinted => (c.accentSoft, enabled ? c.accent : c.textTertiary),
      AppButtonVariant.plain => (Colors.transparent, enabled ? c.accent : c.textTertiary),
      AppButtonVariant.destructive => (Colors.transparent, enabled ? c.danger : c.textTertiary),
    };
    return AppPressable(
      onTap: onPressed,
      child: Container(
        height: Sizes.buttonHeight,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: Spacing.s,
          children: [
            if (icon != null) Icon(icon, size: 19, color: foreground),
            Flexible(child: AppText(label, style: (t) => t.headline, color: foreground, maxLines: 1)),
          ],
        ),
      ),
    );
  }
}
