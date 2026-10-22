import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_pressable.dart';
import 'app_text.dart';

/// Abschnittstitel über einer Gruppe, optional mit Textaktion rechts („Alle“).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l + Spacing.xxs, Spacing.xxl, Spacing.l + Spacing.xxs, Spacing.s),
      child: Row(
        children: [
          Expanded(child: AppText(title, style: (t) => t.title3, maxLines: 1)),
          if (action != null)
            AppPressable(
              onTap: onAction,
              child: AppText(action!, style: (t) => t.subheadline, color: context.colors.accent),
            ),
        ],
      ),
    );
  }
}
