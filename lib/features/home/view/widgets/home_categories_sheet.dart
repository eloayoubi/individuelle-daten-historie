import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';

/// Was im Sheet „Kategorien auf der Übersicht“ gewählt wurde.
sealed class HomeCategoriesChoice {
  const HomeCategoriesChoice();
}

/// Diese Kategorien zeigen, in dieser Reihenfolge (neu gewählte hinten).
final class HomeCategoriesPicked extends HomeCategoriesChoice {
  const HomeCategoriesPicked(this.ids);

  final List<String> ids;
}

/// Die passende Kategorie gibt es noch nicht: neue anlegen.
final class HomeCategoriesCreate extends HomeCategoriesChoice {
  const HomeCategoriesCreate();
}

/// Kategorien für die Übersicht an- und abwählen; darunter eine neue Kategorie anlegen.
class HomeCategoriesSheet extends StatefulWidget {
  const HomeCategoriesSheet({super.key, required this.categories, required this.selected});

  final List<Category> categories;
  final List<String> selected;

  static Future<HomeCategoriesChoice?> show(BuildContext context, {required List<Category> categories, required List<String> selected}) =>
      AppSheet.show<HomeCategoriesChoice>(
        context,
        title: context.l10n.homeCategoriesPick,
        child: HomeCategoriesSheet(categories: categories, selected: selected),
      );

  @override
  State<HomeCategoriesSheet> createState() => _HomeCategoriesSheetState();
}

class _HomeCategoriesSheetState extends State<HomeCategoriesSheet> {
  late final _selected = [
    for (final id in widget.selected)
      if (widget.categories.any((c) => c.id == id)) id,
  ];

  void _toggle(String id, bool on) => setState(() {
    _selected.remove(id);
    if (on) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: [
        AppListGroup(
          color: c.surfaceRaised,
          footer: l10n.homeCategoriesPickHint,
          children: [
            for (final category in widget.categories)
              AppListRow(
                leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
                title: category.name,
                chevron: false,
                trailing: AppSwitch(value: _selected.contains(category.id), semanticLabel: category.name, onChanged: (on) => _toggle(category.id, on)),
                onTap: () => _toggle(category.id, !_selected.contains(category.id)),
              ),
          ],
        ),
        const SizedBox(height: Spacing.m),
        AppListGroup(
          color: c.surfaceRaised,
          children: [
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.plus, color: c.accent),
              title: l10n.homeCategoriesNew,
              onTap: () => Navigator.of(context).pop(const HomeCategoriesCreate()),
            ),
          ],
        ),
        const SizedBox(height: Spacing.l),
        Padding(
          padding: Spacing.screen,
          child: AppButton(label: l10n.actionSave, onPressed: () => Navigator.of(context).pop(HomeCategoriesPicked([..._selected]))),
        ),
      ],
    );
  }
}
