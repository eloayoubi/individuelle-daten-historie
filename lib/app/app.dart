import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/lookup.dart';
import '../core/theme/app_theme.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/reminders/cubit/reminders_cubit.dart';
import '../features/reminders/data/reminder_service.dart';
import '../features/settings/cubit/appearance_cubit.dart';
import '../features/shell/view/shell_page.dart';
import '../l10n/generated/app_localizations.dart';

class KostenkurveApp extends StatelessWidget {
  const KostenkurveApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Über dem MaterialApp, damit auch Sheets und gepushte Seiten Darstellung und Erinnerungen sehen.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => lookup<AppearanceCubit>()..load()),
        BlocProvider(create: (_) => lookup<RemindersCubit>()..load()),
      ],
      child: BlocBuilder<AppearanceCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.night,
          themeMode: mode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Statusleiste passend zum Design.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: _SyncOnResume(child: child!),
          ),
          home: const ShellPage(),
        ),
      ),
    );
  }
}

/// Zurück in der App: offline erfasste Einträge senden und Erinnerungen auffrischen
/// (z. B. nach Änderungen des Partners).
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
