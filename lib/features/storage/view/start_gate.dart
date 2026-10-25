import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../plus/cubit/plus_cubit.dart';
import '../cubit/storage_cubit.dart';
import '../data/storage_mode.dart';
import '../../plus/data/plus_store.dart';
import '../../plus/view/paywall_page.dart';
import 'cloud_flow.dart';
import 'cloud_paused_page.dart';
import 'start_page.dart';

/// Vor dem Onboarding: ohne gewählten Speicherort der Start-Bildschirm, in der Cloud ohne laufendes
/// Abo „Cloud pausiert“ (nur wenn der Server das bestätigt hat), sonst die App.
///
/// Ändert sich der Speicherort, schließt der Gate alle Seiten darüber (Registrieren, Paywall,
/// Einstellungen) – die App beginnt neu im gewählten Speicher. Meldungen zum Umzug zeigt er als Toast.
class StartGate extends StatelessWidget {
  const StartGate({super.key, required this.child});

  final Widget child;

  void _onEvent(BuildContext context, StorageState state) {
    final l10n = context.l10n;
    switch (state.event!.kind) {
      case StorageEventKind.uploaded:
        AppToast.show(context, l10n.storageUploaded, icon: CupertinoIcons.cloud_upload_fill);
      case StorageEventKind.downloaded:
        AppToast.show(context, l10n.storageDownloaded, icon: CupertinoIcons.device_phone_portrait);
      case StorageEventKind.failed:
        AppToast.show(context, l10n.storageFailed, icon: CupertinoIcons.exclamationmark_circle_fill);
      case StorageEventKind.local || StorageEventKind.cloud || StorageEventKind.askUpload:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select((StorageCubit s) => s.state.mode);
    final paused = context.select((PlusCubit p) => p.state.checked && !p.state.active) && mode == StorageMode.cloud;
    return MultiBlocListener(
      listeners: [
        BlocListener<StorageCubit, StorageState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
        ),
        BlocListener<StorageCubit, StorageState>(
          listenWhen: (previous, current) => previous.mode != current.mode,
          listener: (context, _) => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        // Kauf, der erst nach dem Schließen der Paywall bestätigt wurde: jetzt in die Cloud wechseln.
        BlocListener<PlusCubit, PlusState>(
          listenWhen: (previous, current) => current.event != previous.event && current.event?.kind == PlusStoreUpdateKind.unlocked && PaywallPage.openCount == 0,
          listener: (context, _) {
            if (context.read<StorageCubit>().state.mode != StorageMode.cloud) CloudFlow.activate(context);
          },
        ),
      ],
      child: AnimatedSwitcher(
        duration: Motion.normal,
        child: switch ((mode, paused)) {
          (null, _) => const StartPage(key: ValueKey('start')),
          (_, true) => const CloudPausedPage(key: ValueKey('paused')),
          _ => KeyedSubtree(key: ValueKey(mode), child: child),
        },
      ),
    );
  }
}

/// Über allem, solange Daten umziehen: Hinweis mit Fortschritt, Eingaben gesperrt.
class TransferOverlay extends StatelessWidget {
  const TransferOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final transfer = context.select((StorageCubit s) => s.state.transfer);
    return Stack(
      children: [
        child,
        if (transfer != null) ...[
          ModalBarrier(color: c.shadow, dismissible: false),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xxl),
              child: AppCard(
                color: c.sheet,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Spacing.m,
                  children: [
                    const CupertinoActivityIndicator(radius: 14),
                    AppText(
                      transfer == StorageTransferKind.upload ? l10n.storageUploading : l10n.storageDownloading,
                      style: (t) => t.subheadline,
                      align: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
