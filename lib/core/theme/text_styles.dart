import 'package:flutter/material.dart';

/// Gebündelte Schriftfamilien (assets/fonts, Variable Fonts, OFL) – gebündelt statt zur Laufzeit
/// geladen, damit die App auch offline vollständig rendert.
///
/// Wie bei Apple (SF Pro Display / SF Pro Text): [headline] für große Titel und Zahlen,
/// [body] für alles andere – Inter mit optischer Größe (`opsz`), also feiner bei kleinem Text.
abstract final class AppFonts {
  static const headline = 'InterTight';
  static const body = 'Inter';
}

/// Alle Textstile der App, benannt nach Apples Typografie-Skala, als [ThemeExtension] im Theme.
///
/// Zugriff: `context.textStyles.headline`. Farbe ist `textPrimary`; abweichend per
/// `.withColor(context.colors.textSecondary)` oder `AppText(..., color: …)`.
///
/// | Stil | Größe | Gewicht |
/// |---|---|---|
/// | `largeTitle` | 34 | Bold |
/// | `title1` · `title2` · `title3` | 28 · 22 · 20 | Bold · Bold · Semibold |
/// | `headline` | 17 | Semibold |
/// | `body` · `callout` · `subheadline` | 17 · 16 · 15 | Regular |
/// | `footnote` · `caption` · `caption2` | 13 · 12 · 11 | Regular |
///
/// `…Emphasized` ist die Semibold-Variante. Für Beträge und Zählerstände gibt es `numberXL`,
/// `numberL` und `numberM` mit gleich breiten Ziffern, damit Spalten nicht springen.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({required this.color});

  final Color color;

  static const _regular = FontWeight.w400;
  static const _medium = FontWeight.w500;
  static const _semibold = FontWeight.w600;
  static const _bold = FontWeight.w700;

  static const _tabular = [FontFeature.tabularFigures()];

  TextStyle _text(double size, FontWeight weight, {double height = 1.3, double spacing = 0, bool tabular = false}) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble()), FontVariation('opsz', size.clamp(14, 32).toDouble())],
    fontFeatures: tabular ? _tabular : null,
    height: height,
    letterSpacing: spacing,
    color: color,
  );

  TextStyle _display(double size, FontWeight weight, {double height = 1.15, double spacing = -0.4, bool tabular = false}) => TextStyle(
    fontFamily: AppFonts.headline,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    fontFeatures: tabular ? _tabular : null,
    height: height,
    letterSpacing: spacing,
    color: color,
  );

  TextStyle get largeTitle => _display(34, _bold, height: 1.12);
  TextStyle get title1 => _display(28, _bold, height: 1.15);
  TextStyle get title2 => _display(22, _bold, height: 1.2, spacing: -0.3);
  TextStyle get title3 => _display(20, _semibold, height: 1.25, spacing: -0.2);

  TextStyle get headline => _text(17, _semibold, spacing: -0.2);
  TextStyle get body => _text(17, _regular, spacing: -0.2);
  TextStyle get callout => _text(16, _regular, spacing: -0.15);
  TextStyle get calloutEmphasized => _text(16, _semibold, spacing: -0.15);
  TextStyle get subheadline => _text(15, _regular, spacing: -0.1);
  TextStyle get subheadlineEmphasized => _text(15, _semibold, spacing: -0.1);
  TextStyle get footnote => _text(13, _regular);
  TextStyle get footnoteEmphasized => _text(13, _semibold);
  TextStyle get caption => _text(12, _regular);
  TextStyle get captionEmphasized => _text(12, _semibold);
  TextStyle get caption2 => _text(11, _medium, spacing: 0.1);
  TextStyle get caption2Emphasized => _text(11, _bold, spacing: 0.1);

  TextStyle get numberXL => _display(40, _bold, height: 1.05, spacing: -0.8, tabular: true);
  TextStyle get numberL => _display(22, _bold, height: 1.15, spacing: -0.3, tabular: true);
  TextStyle get numberM => _text(17, _semibold, spacing: -0.2, tabular: true);

  /// Grundlage für das Material-[TextTheme], damit auch Standard-Widgets (Dialoge, Snackbars,
  /// Textfelder) die App-Schrift nutzen.
  TextTheme toTextTheme() => TextTheme(
    displaySmall: largeTitle,
    headlineMedium: title1,
    headlineSmall: title2,
    titleLarge: title3,
    titleMedium: headline,
    titleSmall: subheadlineEmphasized,
    bodyLarge: body,
    bodyMedium: subheadline,
    bodySmall: footnote,
    labelLarge: headline,
    labelMedium: footnoteEmphasized,
    labelSmall: caption2,
  );

  @override
  AppTextStyles copyWith({Color? color}) => AppTextStyles(color: color ?? this.color);

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) => other == null ? this : AppTextStyles(color: Color.lerp(color, other.color, t)!);
}

extension TextStyleX on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
}
