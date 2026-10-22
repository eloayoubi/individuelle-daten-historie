import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/lookup.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/cubit/appearance_cubit.dart';
import '../features/shell/view/shell_page.dart';
import '../l10n/generated/app_localizations.dart';

class KostenkurveApp extends StatelessWidget {
  const KostenkurveApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Über dem MaterialApp, damit auch Sheets und gepushte Seiten die Darstellung sehen.
    return BlocProvider(
      create: (_) => lookup<AppearanceCubit>()..load(),
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
            child: child!,
          ),
          home: const ShellPage(),
        ),
      ),
    );
  }
}
