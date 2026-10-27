import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../core/di/lookup.dart';
import '../core/extensions/context_extensions.dart';
import '../core/theme/app_theme.dart';
import '../features/account/cubit/account_cubit.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/onboarding/view/onboarding_page.dart';
import '../features/plus/cubit/plus_cubit.dart';
import '../features/reminders/cubit/reminders_cubit.dart';
import '../features/reminders/data/reminder_service.dart';
import '../features/settings/cubit/appearance_cubit.dart';
import '../features/sharing/data/invite_links.dart';
import '../features/sharing/view/join_sheet.dart';
import '../features/shell/view/shell_page.dart';
import '../features/storage/cubit/storage_cubit.dart';
import '../features/storage/view/cloud_flow.dart';
import '../features/storage/view/start_gate.dart';
import '../features/update/cubit/update_cubit.dart';
import '../features/update/view/force_update_gate.dart';
import '../l10n/generated/app_localizations.dart';
import 'launch_splash.dart';

class KostenkurveApp extends StatefulWidget {
  const KostenkurveApp({super.key, this.launch});

  /// Startanimation ([LaunchSplash.load]); ohne sie startet die App direkt.
  final LottieComposition? launch;

  @override
  State<KostenkurveApp> createState() => _KostenkurveAppState();
}

class _KostenkurveAppState extends State<KostenkurveApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final StreamSubscription<String> _invites;

  @override
  void initState() {
    super.initState();
    // Erst zuhören, dann starten: Der Link, mit dem die App geöffnet wurde, kommt sofort.
    final links = lookup<InviteLinks>();
    _invites = links.codes.listen(_onInvite);
    links.start();
  }

  /// Einladungslink geöffnet: Beitreten-Sheet mit dem Code, sobald die App steht. Teilen gibt es
  /// nur in der Cloud – lokal erklärt ein Dialog warum.
  Future<void> _onInvite(String code) async {
    final context = _navigator.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onInvite(code));
      return;
    }
    if (await CloudFlow.require(context, context.l10n.cloudRequiredShare) && context.mounted) await JoinSheet.show(context, code: code);
  }

  @override
  void dispose() {
    _invites.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Über dem MaterialApp, damit auch Sheets und gepushte Seiten Darstellung, Erinnerungen, Konto,
    // Cloud-Abo und Speicherort sehen – und das Pflicht-Update über allem liegen kann.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => lookup<AppearanceCubit>()..load()),
        BlocProvider(create: (_) => lookup<RemindersCubit>()..load()),
        BlocProvider(create: (_) => lookup<AccountCubit>()..load()),
        BlocProvider(create: (_) => lookup<PlusCubit>()..load()),
        BlocProvider(create: (_) => lookup<StorageCubit>()..load()),
        BlocProvider(create: (_) => lookup<UpdateCubit>()..check()),
      ],
      child: BlocListener<AccountCubit, AccountState>(
        // Anderes Konto (anmelden, abmelden, löschen): dessen Abo-Stand laden.
        listenWhen: (previous, current) => previous.account.userId != current.account.userId,
        listener: (context, _) => context.read<PlusCubit>().load(),
        child: BlocBuilder<AppearanceCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            navigatorKey: _navigator,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.night,
            themeMode: mode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Statusleiste passend zum Design; beim Start liegt die Startanimation über allem, auch
            // über einem Beitreten-Sheet aus einem Einladungslink. Danach sperrt ein veralteter Build
            // die ganze App (Pflicht-Update).
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              child: _SyncOnResume(
                child: LaunchSplash(
                  composition: widget.launch,
                  child: ForceUpdateGate(child: TransferOverlay(child: child!)),
                ),
              ),
            ),
            home: const StartGate(child: OnboardingGate(child: ShellPage())),
          ),
        ),
      ),
    );
  }
}

/// Zurück in der App: offline erfasste Einträge senden, Erinnerungen auffrischen (z. B. nach
/// Änderungen des Partners) und nach einem neueren Build fragen.
class _SyncOnResume extends StatefulWidget {
  const _SyncOnResume({required this.child});

  final Widget child;

  @override
  State<_SyncOnResume> createState() => _SyncOnResumeState();
}

class _SyncOnResumeState extends State<_SyncOnResume> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        lookup<CategoriesRepository>().sync();
        lookup<ReminderService>().reschedule();
        context.read<RemindersCubit>().load();
        context.read<UpdateCubit>().check();
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
