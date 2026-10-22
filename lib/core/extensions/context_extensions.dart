import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/color_config.dart';
import '../theme/text_styles.dart';

extension BuildContextX on BuildContext {
  /// `context.colors.accent`
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// `context.textStyles.headline`
  AppTextStyles get textStyles => Theme.of(this).extension<AppTextStyles>()!;

  /// `context.l10n.tabOverview`
  AppLocalizations get l10n => AppLocalizations.of(this);
}
