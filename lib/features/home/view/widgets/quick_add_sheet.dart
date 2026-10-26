import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';

/// Was in der Schnellerfassung gewählt wurde.
sealed class QuickAddChoice {
  const QuickAddChoice();
}

/// Ein Wert für diesen Tracker.
final class QuickAddTracker extends QuickAddChoice {
  const QuickAddTracker(this.trackerId);

  final String trackerId;
}

/// Noch keine passende Kategorie: neue anlegen.
final class QuickAddCategory extends QuickAddChoice {
  const QuickAddCategory();
}

/// Schnellerfassung: Wofür soll ein Wert eingetragen werden? Darunter eine neue Kategorie anlegen.
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key, required this.categories});

  final List<Category> categories;

  static Future<QuickAddChoice?> show(BuildContext context, List<Category> categories) => AppSheet.show<QuickAddChoice>(
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
                if (tracker.entryFields.isNotEmpty)
                  AppListRow(
                    leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
                    title: tracker.name,
                    subtitle: category.name,
                    onTap: () => Navigator.of(context).pop(QuickAddTracker(tracker.id)),
                  ),
          ],
        ),
        const SizedBox(height: Spacing.m),
        AppListGroup(
          color: c.surfaceRaised,
          children: [
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.plus, color: c.accent),
              title: context.l10n.categoriesAdd,
              onTap: () => Navigator.of(context).pop(const QuickAddCategory()),
            ),
          ],
        ),
      ],
    );
  }
}
