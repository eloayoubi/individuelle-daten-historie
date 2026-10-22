import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_header.dart';
import 'app_icon_tile.dart';
import 'app_text.dart';

/// Übergangsseite für Tabs, die noch nicht umgesetzt sind.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.icon, this.description});

  final String title;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(title: title),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xxxl, 0, Spacing.xxxl, Spacing.tabBarClearance),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Spacing.m,
              children: [
                AppIconTile(icon: icon, color: c.accent, size: 64),
                AppText(context.l10n.comingSoon, style: (t) => t.title3, align: TextAlign.center),
                if (description != null) AppText(description!, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
