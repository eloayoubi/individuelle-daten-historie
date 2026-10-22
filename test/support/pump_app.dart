import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/injection.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/theme/text_styles.dart';
import 'package:kostenkurve/features/reminders/cubit/reminders_cubit.dart';
import 'package:kostenkurve/features/reminders/data/notification_gateway.dart';
import 'package:kostenkurve/features/settings/cubit/appearance_cubit.dart';
import 'package:kostenkurve/features/shell/cubit/shell_cubit.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

/// Registriert die Mock-Abhängigkeiten einmal pro Testlauf.
Future<void> ensureMockDependencies() async {
  if (getIt.isRegistered<ShellCubit>()) return;
  await configureDependencies();
  // Im Test gibt es kein System für Benachrichtigungen.
  getIt
    ..unregister<NotificationGateway>()
    ..registerLazySingleton<NotificationGateway>(MemoryNotificationGateway.new);
}

/// Lädt die gebündelten Schriften, damit Golden-/Screenshot-Tests wie die App aussehen.
Future<void> loadAppFonts() async {
  for (final (family, file) in [(AppFonts.headline, 'InterTight'), (AppFonts.body, 'Inter')]) {
    final loader = FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file.ttf'));
    await loader.load();
  }
}

/// Pumpt eine Seite mit Theme, L10n, AppearanceCubit und RemindersCubit (über der App, wie in
/// `app.dart`) und ShellCubit. [theme] ist standardmäßig Hell, `AppTheme.night` für Dunkel.
Future<void> pumpPage(WidgetTester tester, Widget page, {ThemeData? theme, Size size = const Size(390, 844), Locale locale = const Locale('de')}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => lookup<AppearanceCubit>()),
        BlocProvider(create: (_) => lookup<RemindersCubit>()..load()),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: BlocProvider(create: (_) => lookup<ShellCubit>(), child: Scaffold(body: page)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
