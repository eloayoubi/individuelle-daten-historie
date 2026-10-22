import 'package:flutter/cupertino.dart';

import '../../../core/core.dart';
import '../data/category_templates.dart';

/// Ergebnis der Auswahl: eine Vorlage, `template == null` für eine eigene Kategorie oder [join].
class AddCategoryChoice {
  const AddCategoryChoice(this.template, {this.join = false});

  final CategoryTemplate? template;

  /// Einladung annehmen statt anlegen.
  final bool join;
}

/// „Neue Kategorie“: eigene oder aus einer der Startvorlagen.
class AddCategorySheet extends StatelessWidget {
  const AddCategorySheet({super.key});

  static Future<AddCategoryChoice?> show(BuildContext context) =>
      AppSheet.show<AddCategoryChoice>(context, title: context.l10n.newCategoryTitle, child: const AddCategorySheet());

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: [
        AppListGroup(
          color: c.surfaceRaised,
          children: [
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.plus, color: c.accent),
              title: l10n.newCategoryCustom,
              subtitle: l10n.newCategoryCustomHint,
              onTap: () => Navigator.of(context).pop(const AddCategoryChoice(null)),
            ),
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.person_2_fill, color: c.swatch(CategorySwatch.teal)),
              title: l10n.joinTitle,
              subtitle: l10n.joinRowHint,
              onTap: () => Navigator.of(context).pop(const AddCategoryChoice(null, join: true)),
            ),
          ],
        ),
        SectionHeader(title: l10n.newCategoryTemplates),
        AppListGroup(
          color: c.surfaceRaised,
          children: [
            for (final template in CategoryTemplates.all(l10n))
              AppListRow(
                leading: AppIconTile(icon: template.icon.data, color: c.swatch(template.swatch)),
                title: template.name,
                subtitle: template.description,
                onTap: () => Navigator.of(context).pop(AddCategoryChoice(template)),
              ),
          ],
        ),
      ],
    );
  }
}
