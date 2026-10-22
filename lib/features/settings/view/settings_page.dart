import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/appearance_cubit.dart';

/// Einstellungen: vorerst Darstellung (Automatisch / Hell / Dunkel) und ein Satz zur App.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.tabBarClearance),
      children: [
        AppHeader(title: l10n.tabSettings),
        SectionHeader(title: l10n.settingsAppearance),
        Padding(
          padding: Spacing.screen,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.m,
              children: [
                BlocBuilder<AppearanceCubit, ThemeMode>(
                  builder: (context, mode) => AppSegmented<ThemeMode>(
                    value: mode,
                    segments: {
                      ThemeMode.system: l10n.appearanceSystem,
                      ThemeMode.light: l10n.appearanceLight,
                      ThemeMode.dark: l10n.appearanceDark,
                    },
                    onChanged: context.read<AppearanceCubit>().select,
                  ),
                ),
                AppText(l10n.settingsAppearanceHint, style: (t) => t.footnote, color: c.textSecondary),
              ],
            ),
          ),
        ),
        SectionHeader(title: l10n.settingsAbout),
        Padding(
          padding: Spacing.screen,
          child: AppCard(child: AppText(l10n.settingsAboutBody, style: (t) => t.subheadline, color: c.textSecondary)),
        ),
      ],
    );
  }
}
