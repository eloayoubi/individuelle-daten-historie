import 'package:flutter/material.dart';

import '../models/tracking.dart';

/// Apples Systemfarben (Human Interface Guidelines), jeweils hell und dunkel.
///
/// Nur hier stehen Hex-Werte. Widgets nutzen ausschließlich [AppColors] über `context.colors`;
/// eine neue Farbe kommt erst hierher und als Token in [AppColors], dann in die Widgets.
abstract final class Palette {
  // Hintergründe und Flächen
  static const groupedLight = Color(0xFFF2F2F7);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const graphite = Color(0xFF1C1C1E);
  static const graphiteRaised = Color(0xFF2C2C2E);

  // Text
  static const labelLight = Color(0xFF000000);
  static const secondaryLabelLight = Color(0x993C3C43);
  static const tertiaryLabelLight = Color(0x4D3C3C43);
  static const labelDark = Color(0xFFFFFFFF);
  static const secondaryLabelDark = Color(0x99EBEBF5);
  static const tertiaryLabelDark = Color(0x4DEBEBF5);

  // Linien und Füllungen
  static const separatorLight = Color(0x4A3C3C43);
  static const separatorDark = Color(0x99545458);
  static const fillLight = Color(0x1F767680);
  static const fillDark = Color(0x3D767680);
  static const thumbDark = Color(0xFF636366);
  static const hairlineOnDark = Color(0x1FFFFFFF);

  // Systemfarben hell
  static const blue = Color(0xFF007AFF);
  static const indigo = Color(0xFF5856D6);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);
  static const yellow = Color(0xFFFFCC00);
  static const teal = Color(0xFF30B0C7);
  static const cyan = Color(0xFF32ADE6);
  static const purple = Color(0xFFAF52DE);
  static const pink = Color(0xFFFF2D55);
  static const brown = Color(0xFFA2845E);
  static const gray = Color(0xFF8E8E93);

  // Systemfarben dunkel
  static const blueDark = Color(0xFF0A84FF);
  static const indigoDark = Color(0xFF5E5CE6);
  static const greenDark = Color(0xFF30D158);
  static const orangeDark = Color(0xFFFF9F0A);
  static const redDark = Color(0xFFFF453A);
  static const yellowDark = Color(0xFFFFD60A);
  static const tealDark = Color(0xFF40C8E0);
  static const cyanDark = Color(0xFF64D2FF);
  static const purpleDark = Color(0xFFBF5AF2);
  static const pinkDark = Color(0xFFFF375F);
  static const brownDark = Color(0xFFAC8E68);
  static const grayDark = Color(0xFF98989D);

  /// Indigo mit erhöhtem Kontrast – Akzent auf dunklen Hervorhebungs-Karten.
  static const indigoBright = Color(0xFF7D7AFF);
  static const greenBright = Color(0xFF30DB5B);
  static const redBright = Color(0xFFFF6961);

  // Getönte Flächen (12 % Akzent)
  static const indigoSoftLight = Color(0x1F5856D6);
  static const indigoSoftDark = Color(0x335E5CE6);

  // Glas für schwebende Leisten
  static const glassLight = Color(0xC7FFFFFF);
  static const glassDark = Color(0xC71C1C1E);
  static const glassBorderLight = Color(0x0F000000);
  static const glassBorderDark = Color(0x1AFFFFFF);

  // Schatten
  static const shadowLight = Color(0x14000000);
  static const shadowDark = Color(0x66000000);
}

/// Alle Farben der App, als [ThemeExtension] im Theme hinterlegt. Zugriff: `context.colors.accent`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.dark,
    required this.background,
    required this.surface,
    required this.sheet,
    required this.surfaceRaised,
    required this.fill,
    required this.thumb,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.spotlight,
    required this.onSpotlight,
    required this.onSpotlightSecondary,
    required this.spotlightAccent,
    required this.spotlightLine,
    required this.spotlightSuccess,
    required this.spotlightDanger,
    required this.glass,
    required this.glassBorder,
    required this.shadow,
    required this.swatches,
  });

  final bool dark;

  /// Seitenhintergrund (gruppierte Listen).
  final Color background;

  /// Karten und Listenzeilen auf [background].
  final Color surface;

  /// Hintergrund von Sheets.
  final Color sheet;

  /// Karten und Zeilen auf [sheet].
  final Color surfaceRaised;

  /// Dezente Füllung für Felder, Chips, inaktive Balken.
  final Color fill;

  /// Schieber im Segment-Umschalter.
  final Color thumb;
  final Color separator;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Markenfarbe (Systemindigo) für Aktionen, aktive Tabs, Kurven.
  final Color accent;

  /// Schrift und Icons auf [accent] und auf den [swatches].
  final Color onAccent;

  /// Getönte Fläche hinter Akzent-Schrift (sekundäre Buttons, aktive Chips).
  final Color accentSoft;

  final Color success;
  final Color warning;
  final Color danger;

  /// Dunkle Hervorhebungs-Karte (Prognose) – in Hell wie in Dunkel dunkel.
  final Color spotlight;
  final Color onSpotlight;
  final Color onSpotlightSecondary;

  /// Akzent mit genug Kontrast auf [spotlight] (Kurve, Punkte).
  final Color spotlightAccent;

  /// Hilfslinien und Trenner auf [spotlight].
  final Color spotlightLine;
  final Color spotlightSuccess;
  final Color spotlightDanger;

  /// Durchscheinende Fläche schwebender Leisten (mit Blur dahinter).
  final Color glass;
  final Color glassBorder;
  final Color shadow;

  /// Kategoriefarben; Zugriff über [swatch].
  final Map<CategorySwatch, Color> swatches;

  Color swatch(CategorySwatch s) => swatches[s] ?? accent;

  static const light = AppColors(
    dark: false,
    background: Palette.groupedLight,
    surface: Palette.white,
    sheet: Palette.groupedLight,
    surfaceRaised: Palette.white,
    fill: Palette.fillLight,
    thumb: Palette.white,
    separator: Palette.separatorLight,
    textPrimary: Palette.labelLight,
    textSecondary: Palette.secondaryLabelLight,
    textTertiary: Palette.tertiaryLabelLight,
    accent: Palette.indigo,
    onAccent: Palette.white,
    accentSoft: Palette.indigoSoftLight,
    success: Palette.green,
    warning: Palette.orange,
    danger: Palette.red,
    spotlight: Palette.graphite,
    onSpotlight: Palette.labelDark,
    onSpotlightSecondary: Palette.secondaryLabelDark,
    spotlightAccent: Palette.indigoBright,
    spotlightLine: Palette.hairlineOnDark,
    spotlightSuccess: Palette.greenBright,
    spotlightDanger: Palette.redBright,
    glass: Palette.glassLight,
    glassBorder: Palette.glassBorderLight,
    shadow: Palette.shadowLight,
    swatches: {
      CategorySwatch.orange: Palette.orange,
      CategorySwatch.red: Palette.red,
      CategorySwatch.blue: Palette.blue,
      CategorySwatch.cyan: Palette.cyan,
      CategorySwatch.brown: Palette.brown,
      CategorySwatch.green: Palette.green,
      CategorySwatch.purple: Palette.purple,
      CategorySwatch.teal: Palette.teal,
      CategorySwatch.pink: Palette.pink,
      CategorySwatch.indigo: Palette.indigo,
      CategorySwatch.yellow: Palette.yellow,
      CategorySwatch.gray: Palette.gray,
    },
  );

  static const night = AppColors(
    dark: true,
    background: Palette.black,
    surface: Palette.graphite,
    sheet: Palette.graphite,
    surfaceRaised: Palette.graphiteRaised,
    fill: Palette.fillDark,
    thumb: Palette.thumbDark,
    separator: Palette.separatorDark,
    textPrimary: Palette.labelDark,
    textSecondary: Palette.secondaryLabelDark,
    textTertiary: Palette.tertiaryLabelDark,
    accent: Palette.indigoDark,
    onAccent: Palette.white,
    accentSoft: Palette.indigoSoftDark,
    success: Palette.greenDark,
    warning: Palette.orangeDark,
    danger: Palette.redDark,
    spotlight: Palette.graphiteRaised,
    onSpotlight: Palette.labelDark,
    onSpotlightSecondary: Palette.secondaryLabelDark,
    spotlightAccent: Palette.indigoBright,
    spotlightLine: Palette.hairlineOnDark,
    spotlightSuccess: Palette.greenBright,
    spotlightDanger: Palette.redBright,
    glass: Palette.glassDark,
    glassBorder: Palette.glassBorderDark,
    shadow: Palette.shadowDark,
    swatches: {
      CategorySwatch.orange: Palette.orangeDark,
      CategorySwatch.red: Palette.redDark,
      CategorySwatch.blue: Palette.blueDark,
      CategorySwatch.cyan: Palette.cyanDark,
      CategorySwatch.brown: Palette.brownDark,
      CategorySwatch.green: Palette.greenDark,
      CategorySwatch.purple: Palette.purpleDark,
      CategorySwatch.teal: Palette.tealDark,
      CategorySwatch.pink: Palette.pinkDark,
      CategorySwatch.indigo: Palette.indigoDark,
      CategorySwatch.yellow: Palette.yellowDark,
      CategorySwatch.gray: Palette.grayDark,
    },
  );

  @override
  AppColors copyWith({
    bool? dark,
    Color? background,
    Color? surface,
    Color? sheet,
    Color? surfaceRaised,
    Color? fill,
    Color? thumb,
    Color? separator,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? warning,
    Color? danger,
    Color? spotlight,
    Color? onSpotlight,
    Color? onSpotlightSecondary,
    Color? spotlightAccent,
    Color? spotlightLine,
    Color? spotlightSuccess,
    Color? spotlightDanger,
    Color? glass,
    Color? glassBorder,
    Color? shadow,
    Map<CategorySwatch, Color>? swatches,
  }) => AppColors(
    dark: dark ?? this.dark,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    sheet: sheet ?? this.sheet,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    fill: fill ?? this.fill,
    thumb: thumb ?? this.thumb,
    separator: separator ?? this.separator,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSoft: accentSoft ?? this.accentSoft,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    spotlight: spotlight ?? this.spotlight,
    onSpotlight: onSpotlight ?? this.onSpotlight,
    onSpotlightSecondary: onSpotlightSecondary ?? this.onSpotlightSecondary,
    spotlightAccent: spotlightAccent ?? this.spotlightAccent,
    spotlightLine: spotlightLine ?? this.spotlightLine,
    spotlightSuccess: spotlightSuccess ?? this.spotlightSuccess,
    spotlightDanger: spotlightDanger ?? this.spotlightDanger,
    glass: glass ?? this.glass,
    glassBorder: glassBorder ?? this.glassBorder,
    shadow: shadow ?? this.shadow,
    swatches: swatches ?? this.swatches,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      dark: t < 0.5 ? dark : other.dark,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      sheet: mix(sheet, other.sheet),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      fill: mix(fill, other.fill),
      thumb: mix(thumb, other.thumb),
      separator: mix(separator, other.separator),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      spotlight: mix(spotlight, other.spotlight),
      onSpotlight: mix(onSpotlight, other.onSpotlight),
      onSpotlightSecondary: mix(onSpotlightSecondary, other.onSpotlightSecondary),
      spotlightAccent: mix(spotlightAccent, other.spotlightAccent),
      spotlightLine: mix(spotlightLine, other.spotlightLine),
      spotlightSuccess: mix(spotlightSuccess, other.spotlightSuccess),
      spotlightDanger: mix(spotlightDanger, other.spotlightDanger),
      glass: mix(glass, other.glass),
      glassBorder: mix(glassBorder, other.glassBorder),
      shadow: mix(shadow, other.shadow),
      swatches: {for (final s in CategorySwatch.values) s: mix(swatch(s), other.swatch(s))},
    );
  }
}
