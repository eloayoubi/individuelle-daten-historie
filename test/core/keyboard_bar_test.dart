import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/widgets/widgets.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  const height = 844.0;
  const keyboard = 300.0;
  const form = Key('form');
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

  /// Zwei Zahlenfelder und ein Textfeld; die Tastatur ist offen.
  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, height)
      ..devicePixelRatio = 1
      ..viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppKeyboardBar(child: child!),
        home: const Scaffold(
          body: Column(
            key: form,
            children: [
              AppTextField(hint: 'Zählerstand', keyboardType: TextInputType.numberWithOptions(decimal: true)),
              AppTextField(hint: 'Code', keyboardType: TextInputType.number),
              AppTextField(hint: 'Notiz'),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  FocusNode node(WidgetTester tester, int index) => tester.widget<EditableText>(find.byType(EditableText).at(index)).focusNode;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Zahlenfeld: Leiste über der Tastatur, der Inhalt rückt über sie', (tester) async {
    await pump(tester);
    expect(tester.getRect(find.byKey(form)).bottom, height - keyboard);

    await tap(tester, find.byType(TextField).first);

    expect(find.text('Fertig'), findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(find.text('Fertig')).text.style?.decoration, isNot(TextDecoration.underline), reason: 'keine Fehler-Unterstreichung ohne Material');
    expect(tester.getRect(find.byKey(form)).bottom, height - keyboard - AppKeyboardBar.height);
    expect(tester.getRect(find.byType(AppKeyboardBar).last).bottom, height);
  }, variant: ios);

  testWidgets('Textfeld: keine Leiste, die Eingabetaste schließt', (tester) async {
    await pump(tester);
    await tap(tester, find.byType(TextField).last);

    expect(find.text('Fertig'), findsNothing);
    expect(tester.getRect(find.byKey(form)).bottom, height - keyboard);
  }, variant: ios);

  testWidgets('Android hat die Fertig-Taste in der Tastatur: keine Leiste', (tester) async {
    await pump(tester);
    await tap(tester, find.byType(TextField).first);

    expect(find.text('Fertig'), findsNothing);
  });

  testWidgets('Fertig schließt die Tastatur, die Leiste fährt mit ihr weg', (tester) async {
    await pump(tester);
    await tap(tester, find.byType(TextField).first);
    expect(node(tester, 0).hasFocus, isTrue);

    await tap(tester, find.text('Fertig'));

    expect(node(tester, 0).hasFocus, isFalse);
    expect(find.text('Fertig'), findsOneWidget, reason: 'bis die Tastatur unten ist');

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(find.text('Fertig'), findsNothing);
    expect(tester.getRect(find.byKey(form)).bottom, height);
  }, variant: ios);

  testWidgets('Pfeile springen zum vorigen und nächsten Textfeld', (tester) async {
    await pump(tester);
    await tap(tester, find.byType(TextField).first);

    await tap(tester, find.byIcon(CupertinoIcons.chevron_up));
    expect(node(tester, 0).hasFocus, isTrue, reason: 'erstes Feld: kein Feld davor');

    await tap(tester, find.byIcon(CupertinoIcons.chevron_down));
    expect(node(tester, 1).hasFocus, isTrue);

    await tap(tester, find.byIcon(CupertinoIcons.chevron_down));
    expect(node(tester, 2).hasFocus, isTrue);
    expect(find.text('Fertig'), findsNothing, reason: 'Textfeld mit Eingabetaste');
  }, variant: ios);

  testWidgets('Tipp daneben schließt die Tastatur, Tipp in ein anderes Feld nicht', (tester) async {
    await pump(tester);
    await tap(tester, find.byType(TextField).last);

    await tap(tester, find.byType(TextField).first);
    expect(node(tester, 0).hasFocus, isTrue);

    await tester.tapAt(const Offset(195, 400));
    await tester.pump();
    expect(node(tester, 0).hasFocus, isFalse);
  }, variant: TargetPlatformVariant.mobile());
}
