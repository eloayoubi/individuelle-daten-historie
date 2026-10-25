import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';
import 'app_text.dart';

/// Rückfragen als iOS-Alert. `await AppDialog.confirm(...)` liefert `true`, wenn bestätigt;
/// [cancelLabel] ersetzt „Abbrechen“, wenn die zweite Wahl eine echte Antwort ist.
abstract final class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final c = context.colors;
    final l10n = context.l10n;
    final result = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: AppText(title, style: (t) => t.headline),
        content: AppText(message, style: (t) => t.footnote, color: c.textSecondary),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppText(cancelLabel ?? l10n.actionCancel, style: (t) => t.body, color: c.accent),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppText(confirmLabel, style: (t) => t.headline, color: destructive ? c.danger : c.accent),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
