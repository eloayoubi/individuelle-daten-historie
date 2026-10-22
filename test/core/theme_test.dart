import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/theme/app_theme.dart';
import 'package:kostenkurve/core/theme/color_config.dart';
import 'package:kostenkurve/core/theme/text_styles.dart';

/// Kontrast nach WCAG: (L1 + 0.05) / (L2 + 0.05).
double contrast(Color a, Color b) {
  final (l1, l2) = (a.computeLuminance(), b.computeLuminance());
  return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
}

void main() {
  for (final (name, theme, colors) in [('hell', AppTheme.light, AppColors.light), ('dunkel', AppTheme.night, AppColors.night)]) {
    group('Theme $name', () {
      test('trägt beide Extensions', () {
        expect(theme.extension<AppColors>(), colors);
        expect(theme.extension<AppTextStyles>()?.color, colors.textPrimary);
        expect(theme.brightness, colors.dark ? Brightness.dark : Brightness.light);
      });

      test('hat für jede Kategoriefarbe einen Wert', () {
        for (final s in CategorySwatch.values) {
          expect(colors.swatches.containsKey(s), isTrue, reason: s.name);
        }
      });

      test('Hervorhebungs-Karte bleibt dunkel und gut lesbar', () {
        expect(colors.spotlight.computeLuminance(), lessThan(0.05));
        expect(contrast(colors.onSpotlight, colors.spotlight), greaterThan(7));
        expect(contrast(colors.spotlightAccent, colors.spotlight), greaterThan(3));
      });

      test('Text ist auf Karten und Akzent gut lesbar', () {
        expect(contrast(colors.textPrimary, colors.surface), greaterThan(7));
        expect(contrast(colors.onAccent, colors.accent), greaterThan(4.5));
      });
    });
  }

  group('AppColors', () {
    test('lerp liefert an den Enden die beiden Paletten', () {
      expect(AppColors.light.lerp(AppColors.night, 0).background, AppColors.light.background);
      expect(AppColors.light.lerp(AppColors.night, 1).background, AppColors.night.background);
      expect(AppColors.light.lerp(AppColors.night, 1).dark, isTrue);
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });

    test('copyWith ersetzt nur das Angegebene', () {
      final copy = AppColors.light.copyWith(accent: AppColors.night.accent);
      expect(copy.accent, AppColors.night.accent);
      expect(copy.background, AppColors.light.background);
    });
  });

  group('AppTextStyles', () {
    const styles = AppTextStyles(color: Palette.labelLight);

    test('nutzt die gebündelten Schriften', () {
      expect(styles.largeTitle.fontFamily, AppFonts.headline);
      expect(styles.numberXL.fontFamily, AppFonts.headline);
      expect(styles.body.fontFamily, AppFonts.body);
      expect(styles.caption2.fontFamily, AppFonts.body);
    });

    test('setzt Gewicht auch als Variable-Font-Achse', () {
      final wght = styles.headline.fontVariations!.firstWhere((v) => v.axis == 'wght');
      expect(wght.value, 600);
      expect(styles.numberM.fontFeatures, isNotEmpty);
    });

    test('lerp und copyWith wechseln die Farbe', () {
      expect(styles.copyWith(color: Palette.labelDark).color, Palette.labelDark);
      expect(styles.lerp(const AppTextStyles(color: Palette.labelDark), 1).color, Palette.labelDark);
    });
  });
}
