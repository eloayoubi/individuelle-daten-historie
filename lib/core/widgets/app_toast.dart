import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_text.dart';

/// Kurze Rückmeldung als dunkle Kapsel über der Tab-Leiste. `AppToast.show(context, 'Text')`.
abstract final class AppToast {
  static void show(BuildContext context, String message, {IconData icon = CupertinoIcons.checkmark_circle_fill}) {
    final c = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.spotlight,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.tabBarClearance - Spacing.l),
          shape: const StadiumBorder(),
          duration: Motion.toast,
          content: Row(
            spacing: Spacing.s,
            children: [
              Icon(icon, size: 20, color: c.spotlightAccent),
              Expanded(child: AppText(message, style: (t) => t.subheadlineEmphasized, color: c.onSpotlight)),
            ],
          ),
        ),
      );
  }
}
