import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Schnellerfassung: Wofür soll ein Wert eingetragen werden? Liefert die Tracker-Id zurück.
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key, required this.categories});

  final List<Category> categories;

  static Future<String?> show(BuildContext context, List<Category> categories) => AppSheet.show<String>(
    context,
    title: context.l10n.quickAddTitle,
    child: QuickAddSheet(categories: categories),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: [
        AppListGroup(
          color: c.surfaceRaised,
          children: [
            for (final category in categories)
              for (final tracker in category.trackers)
                if (tracker.fields.isNotEmpty)
                  AppListRow(
                    leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
                    title: tracker.name,
                    subtitle: category.name,
                    onTap: () => Navigator.of(context).pop(tracker.id),
                  ),
          ],
        ),
      ],
    );
  }
}
