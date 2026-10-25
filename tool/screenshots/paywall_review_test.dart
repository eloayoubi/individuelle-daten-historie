import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/di/lookup.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/features/account/cubit/account_cubit.dart';
import 'package:kostenkurve/features/auth/data/auth_repository.dart';
import 'package:kostenkurve/features/plus/cubit/plus_cubit.dart';
import 'package:kostenkurve/features/plus/view/paywall_page.dart';
import 'package:kostenkurve/features/storage/cubit/storage_cubit.dart';
import 'package:kostenkurve/features/storage/data/storage_mode.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

import '../../test/support/pump_app.dart';
import '../branding/png_golden_comparator.dart';

/// Prüf-Screenshot der Paywall für das Abo in App Store Connect (1290 × 2796, iPhone 6,7″), DE und EN:
///
/// ```sh
/// flutter test tool/screenshots/paywall_review_test.dart --update-goldens
/// ```
///
/// Schreibt nach `build/asc/` (nicht im Git); hochladen unter Abo → Informationen zur Prüfung.
void main() {
  useOpaquePngGoldens();
  setUpAll(() async {
    await ensureMockDependencies();
    await loadAppFonts();
    for (final MapEntry(key: family, value: asset) in {
      'packages/cupertino_icons/CupertinoIcons': 'packages/cupertino_icons/assets/CupertinoIcons.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      for (final f in ['CupertinoSystemText', 'CupertinoSystemDisplay', '.SF Pro Text', '.SF Pro Display']) f: 'assets/fonts/${f.contains('Display') ? 'InterTight' : 'Inter'}.ttf',
    }.entries) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final (locale, file) in [(const Locale('de'), 'paywall_de'), (const Locale('en'), 'paywall_en')]) {
    testWidgets(file, (t) async {
      await lookup<StorageModeStore>().set(null);
      await lookup<AuthRepository>().signInWithApple();
      t.view.physicalSize = const Size(1290, 2796);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => lookup<AccountCubit>()..load()),
            BlocProvider(create: (_) => lookup<PlusCubit>()..load()),
            BlocProvider(create: (_) => lookup<StorageCubit>()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: const MediaQuery(data: MediaQueryData(size: Size(430, 932), devicePixelRatio: 3, padding: EdgeInsets.only(top: 59, bottom: 34)), child: PaywallPage()),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../build/asc/$file.png'));
      await lookup<AuthRepository>().signOut();
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
}
