import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'color_config.dart';
import 'text_styles.dart';

/// Hell und Dunkel, beide aus denselben Tokens gebaut ([AppColors], [AppTextStyles]).
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light);

  static ThemeData get night => _build(AppColors.night);

  static ThemeData _build(AppColors colors) {
    final textStyles = AppTextStyles(color: colors.textPrimary);
    final brightness = colors.dark ? Brightness.dark : Brightness.light;
    // Auf beiden Plattformen wie iOS: Wisch-Zurück und seitliche Übergänge.
    const transitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.accent,
        onSecondary: colors.onAccent,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.danger,
        onError: colors.onAccent,
      ),
      fontFamily: AppFonts.body,
      textTheme: textStyles.toTextTheme(),
      dividerColor: colors.separator,
      // Keine Material-Welle: Antippen zeigt AppPressable (kleiner und blasser), wie auf iOS.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      pageTransitionsTheme: transitions,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.accent,
        scaffoldBackgroundColor: colors.background,
        barBackgroundColor: colors.glass,
      ),
      extensions: [colors, textStyles],
    );
  }
}
