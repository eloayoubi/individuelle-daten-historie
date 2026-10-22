import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/widgets/widgets.dart';
import 'package:kostenkurve/features/home/view/home_page.dart';
import 'package:kostenkurve/features/home/view/widgets/quick_add_sheet.dart';
import 'package:kostenkurve/features/settings/view/settings_page.dart';
import 'package:kostenkurve/features/shell/view/shell_page.dart';

import 'support/pump_app.dart';

/// Jede Seite rendert mit den Mock-Repositories in Hell und Dunkel ohne Fehler.
void main() {
  setUpAll(() async {
    await ensureMockDependencies();
    await loadAppFonts();
  });

  final pages = <(String, Widget)>[
    ('shell', const ShellView()),
    ('home', const HomePage()),
    ('settings', const SettingsPage()),
    ('placeholder', const PlaceholderPage(title: 'Kategorien', icon: CupertinoIcons.square_grid_2x2_fill, description: 'Kommt bald.')),
  ];

  for (final (mode, theme) in [('hell', AppTheme.light), ('dunkel', AppTheme.night)]) {
    group(mode, () {
      for (final (name, page) in pages) {
        testWidgets('$name rendert', (t) async {
          await pumpPage(t, page, theme: theme);
          await t.pump(const Duration(seconds: 1));
          expect(t.takeException(), isNull);
        });
      }

      testWidgets('Schnellerfassung öffnet das Sheet und meldet sich per Toast', (t) async {
        await pumpPage(t, const HomePage(), theme: theme);
        await t.tap(find.bySemanticsLabel('Eintrag erfassen'));
        await t.pumpAndSettle();
        expect(find.byType(QuickAddSheet), findsOneWidget);
        await t.tap(find.text('Hauptzähler').last);
        await t.pumpAndSettle();
        expect(find.byType(QuickAddSheet), findsNothing);
        expect(find.text('Das Erfassen kommt im nächsten Schritt.'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('Tab-Leiste wechselt zu den Einstellungen', (t) async {
        await pumpPage(t, const ShellView(), theme: theme);
        await t.tap(find.text('Einstellungen'));
        await t.pumpAndSettle();
        expect(find.byType(AppSegmented<ThemeMode>), findsOneWidget);
      });
    });
  }

  testWidgets('englische Texte rendern', (t) async {
    await pumpPage(t, const ShellView(), locale: const Locale('en'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Overview'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
