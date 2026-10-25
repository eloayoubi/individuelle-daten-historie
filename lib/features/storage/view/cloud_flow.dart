import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../plus/cubit/plus_cubit.dart';
import '../../plus/view/paywall_page.dart';
import '../cubit/storage_cubit.dart';

/// Gemeinsame Schritte auf dem Weg in die Cloud.
abstract final class CloudFlow {
  /// Nach dem Kauf oder einer Anmeldung mit laufendem Abo in die Cloud wechseln. Liegen im Konto
  /// schon Daten, fragt die App, ob die vom Gerät dazukommen. `true`, wenn die App jetzt in der
  /// Cloud ist; der `StartGate` schließt dann alle Seiten darüber.
  static Future<bool> activate(BuildContext context) async {
    final storage = context.read<StorageCubit>();
    final l10n = context.l10n;
    var result = await storage.activateCloud();
    if (result == StorageEventKind.askUpload) {
      if (!context.mounted) return false;
      final upload = await AppDialog.confirm(
        context,
        title: l10n.storageAskUploadTitle,
        message: l10n.storageAskUploadBody,
        confirmLabel: l10n.storageAskUploadYes,
        cancelLabel: l10n.storageAskUploadNo,
      );
      result = await storage.activateCloud(upload: upload);
    }
    return result == StorageEventKind.cloud || result == StorageEventKind.uploaded;
  }

  /// Teilen und Beitreten gehen nur in der Cloud. Lokal erklärt ein Dialog warum und öffnet auf
  /// Wunsch die Paywall; `true` heißt: weitermachen.
  static Future<bool> require(BuildContext context, String message) async {
    if (context.read<StorageCubit>().state.isCloud) return true;
    final l10n = context.l10n;
    final open = await AppDialog.confirm(context, title: l10n.cloudRequiredTitle, message: message, confirmLabel: l10n.cloudRequiredAction);
    if (open && context.mounted) await PaywallPage.open(context);
    return false;
  }

  /// Monatspreis aus dem Store; ohne Store (Android, Simulator) der Listenpreis.
  static String price(BuildContext context, PlusState plus) => plus.monthly?.label ?? context.l10n.cloudPriceFallback;
}
