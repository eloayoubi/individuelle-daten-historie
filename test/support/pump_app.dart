import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/injection.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/theme/text_styles.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/features/account/cubit/account_cubit.dart';
import 'package:kostenkurve/features/home/data/home_categories_store.dart';
import 'package:kostenkurve/features/categories/data/local_categories_repository.dart';
import 'package:kostenkurve/features/plus/cubit/plus_cubit.dart';
import 'package:kostenkurve/features/reminders/cubit/reminders_cubit.dart';
import 'package:kostenkurve/features/reminders/data/notification_gateway.dart';
import 'package:kostenkurve/features/settings/cubit/appearance_cubit.dart';
import 'package:kostenkurve/features/settings/data/review_prompter.dart';
import 'package:kostenkurve/features/sharing/data/invite_links.dart';
import 'package:kostenkurve/features/shell/cubit/shell_cubit.dart';
import 'package:kostenkurve/features/storage/cubit/storage_cubit.dart';
import 'package:kostenkurve/features/storage/data/storage_mode.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

/// Registriert die Mock-Abhängigkeiten einmal pro Testlauf. Speicherort ist die Cloud (der Mock mit
/// den Beispieldaten); Tests für „Lokal“ setzen ihn selbst und danach mit [useMockCloud] zurück.
Future<void> ensureMockDependencies() async {
  if (getIt.isRegistered<ShellCubit>()) return useMockCloud();
  await configureDependencies();
  // Speicherort und lokale Daten im Speicher: Dateien gibt es im Test nicht, und ein Warten auf den
  // Plattformkanal hielte die Widget-Tests an.
  getIt
    ..unregister<StorageModeStore>()
    ..registerSingleton<StorageModeStore>(StorageModeStore(MemoryJsonStore()))
    ..unregister<LocalCategoriesRepository>()
    ..registerLazySingleton<LocalCategoriesRepository>(() => LocalCategoriesRepository(MemoryJsonStore()));
  await useMockCloud();
  // Im Test gibt es kein System für Benachrichtigungen, Links und Bewertungen.
  getIt
    ..unregister<NotificationGateway>()
    ..registerLazySingleton<NotificationGateway>(MemoryNotificationGateway.new)
    ..unregister<InviteLinks>()
    ..registerLazySingleton<InviteLinks>(() => const NoInviteLinks())
    ..unregister<ReviewPrompter>()
    ..registerLazySingleton<ReviewPrompter>(() => const NoReviewPrompter());
  // Übersicht: gewählte Kategorien im Speicher statt in einer Datei.
  getIt
    ..unregister<HomeCategoriesStore>()
    ..registerLazySingleton<HomeCategoriesStore>(() => HomeCategoriesStore(MemoryJsonStore()));
}

Future<void> useMockCloud() => lookup<StorageModeStore>().set(StorageMode.cloud);

/// Lädt die gebündelten Schriften, damit Golden-/Screenshot-Tests wie die App aussehen.
Future<void> loadAppFonts() async {
  for (final (family, file) in [(AppFonts.headline, 'InterTight'), (AppFonts.body, 'Inter')]) {
    final loader = FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file.ttf'));
    await loader.load();
  }
}

/// Pumpt eine Seite mit Theme, L10n, den Cubits über der App (Darstellung, Erinnerungen, Konto,
/// Cloud-Abo, Speicherort – wie in `app.dart`) und ShellCubit. [theme] ist standardmäßig Hell, `AppTheme.night` für Dunkel.
Future<void> pumpPage(WidgetTester tester, Widget page, {ThemeData? theme, Size size = const Size(390, 844), Locale locale = const Locale('de')}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => lookup<AppearanceCubit>()),
        BlocProvider(create: (_) => lookup<RemindersCubit>()..load()),
        BlocProvider(create: (_) => lookup<AccountCubit>()..load()),
        BlocProvider(create: (_) => lookup<PlusCubit>()..load()),
        BlocProvider(create: (_) => lookup<StorageCubit>()),
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
