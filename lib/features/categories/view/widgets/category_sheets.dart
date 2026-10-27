import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import 'appearance_pickers.dart';

/// Auswahl im Menü „Kategorie bearbeiten“; ausgeführt wird sie von der Kategorie-Seite.
sealed class CategoryMenuChoice {
  const CategoryMenuChoice();
}

/// Name, Symbol und Farbe ändern.
class CategoryMenuAppearance extends CategoryMenuChoice {
  const CategoryMenuAppearance();
}

/// Felder und Einstellungen eines Trackers öffnen.
class CategoryMenuTrackerSetup extends CategoryMenuChoice {
  const CategoryMenuTrackerSetup(this.trackerId);

  final String trackerId;
}

class CategoryMenuAddTracker extends CategoryMenuChoice {
  const CategoryMenuAddTracker();
}

class CategoryMenuArchive extends CategoryMenuChoice {
  const CategoryMenuArchive();
}

class CategoryMenuDelete extends CategoryMenuChoice {
  const CategoryMenuDelete();
}

/// Alles zum Bearbeiten einer Kategorie an einer Stelle: Darstellung, Felder und Einstellungen je
/// Tracker, weiteren Tracker hinzufügen; für den owner darunter Archivieren und Löschen.
class CategoryMenuSheet extends StatelessWidget {
  const CategoryMenuSheet({super.key, required this.category, this.addLabel});

  final Category category;

  /// Statt „Tracker hinzufügen“, z. B. „Abo hinzufügen“.
  final String? addLabel;

  static Future<CategoryMenuChoice?> show(BuildContext context, Category category, {String? addLabel}) => AppSheet.show<CategoryMenuChoice>(
    context,
    title: context.l10n.detailEditCategory,
    child: CategoryMenuSheet(category: category, addLabel: addLabel),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    void choose(CategoryMenuChoice choice) => Navigator.of(context).pop(choice);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: [
        AppListGroup(
          color: c.surfaceRaised,
          children: [
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.paintbrush_fill, color: c.swatch(category.swatch)),
              title: l10n.detailAppearance,
              subtitle: l10n.detailAppearanceHint,
              onTap: () => choose(const CategoryMenuAppearance()),
            ),
            for (final tracker in category.trackers)
              AppListRow(
                leading: AppIconTile(icon: CupertinoIcons.slider_horizontal_3, color: c.accent),
                title: l10n.trackerSetup,
                subtitle: tracker.name,
                onTap: () => choose(CategoryMenuTrackerSetup(tracker.id)),
              ),
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.plus, color: c.accent),
              title: addLabel ?? (category.trackers.isEmpty ? l10n.detailAddTracker : l10n.detailAddAnotherTracker),
              chevron: false,
              onTap: () => choose(const CategoryMenuAddTracker()),
            ),
          ],
        ),
        // Archivieren behält alles (nur ausgeblendet), Löschen ist endgültig.
        if (category.isOwner)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xl, Spacing.l, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spacing.s,
              children: [
                if (!category.isArchived)
                  AppButton(label: l10n.detailArchive, variant: AppButtonVariant.destructive, onPressed: () => choose(const CategoryMenuArchive())),
                AppButton(label: l10n.detailDelete, variant: AppButtonVariant.destructive, onPressed: () => choose(const CategoryMenuDelete())),
              ],
            ),
          ),
      ],
    );
  }
}

/// Neue Darstellung einer Kategorie aus dem [CategoryEditSheet].
class CategoryEdited {
  const CategoryEdited({required this.name, required this.icon, required this.swatch});

  final String name;
  final CategoryIcon icon;
  final CategorySwatch swatch;
}

/// Darstellung einer Kategorie ändern: Name, Symbol und Farbe. Liefert die neuen Werte oder `null`
/// bei Abbruch.
class CategoryEditSheet extends StatefulWidget {
  const CategoryEditSheet({super.key, required this.category});

  final Category category;

  static Future<CategoryEdited?> show(BuildContext context, Category category) => AppSheet.show<CategoryEdited>(
    context,
    title: context.l10n.detailAppearance,
    child: CategoryEditSheet(category: category),
  );

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  late final _name = TextEditingController(text: widget.category.name);
  late var _icon = widget.category.icon;
  late var _swatch = widget.category.swatch;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      children: [
        Row(
          spacing: Spacing.m,
          children: [
            AppIconTile(icon: _icon.data, color: c.swatch(_swatch), size: 52),
            Expanded(
              child: AppTextField(
                controller: _name,
                hint: l10n.setupNameHint,
                maxLength: 60,
                color: c.surfaceRaised,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.l),
        AppCard(
          color: c.surfaceRaised,
          child: IconPicker(selected: _icon, swatch: _swatch, onSelect: (icon) => setState(() => _icon = icon)),
        ),
        const SizedBox(height: Spacing.m),
        AppCard(
          color: c.surfaceRaised,
          child: SwatchPicker(selected: _swatch, onSelect: (swatch) => setState(() => _swatch = swatch)),
        ),
        const SizedBox(height: Spacing.xl),
        AppButton(
          label: l10n.actionSave,
          onPressed: _name.text.trim().isEmpty ? null : () => Navigator.of(context).pop(CategoryEdited(name: _name.text.trim(), icon: _icon, swatch: _swatch)),
        ),
      ],
    );
  }
}

/// Im Tracker-Sheet gespeichert: Name und wohin die Kosten zählen.
class TrackerRenamed {
  const TrackerRenamed(this.name, {this.includedIn});

  final String name;

  /// Kategorie, in deren Kosten der Tracker steckt (`null` = eigene Kosten).
  final String? includedIn;
}

/// Tracker anlegen (ohne [tracker]) oder umbenennen und Kosten einer anderen Kategorie zuordnen
/// ([others]). Archivieren geht auf der Seite „Felder und Einstellungen“.
class TrackerSheet extends StatefulWidget {
  const TrackerSheet({super.key, this.tracker, this.others = const []});

  final Tracker? tracker;
  final List<Category> others;

  static Future<TrackerRenamed?> show(BuildContext context, {Tracker? tracker, List<Category> others = const []}) => AppSheet.show<TrackerRenamed>(
    context,
    title: tracker == null ? context.l10n.trackerNew : context.l10n.detailEditTracker,
    child: TrackerSheet(tracker: tracker, others: others),
  );

  @override
  State<TrackerSheet> createState() => _TrackerSheetState();
}

class _TrackerSheetState extends State<TrackerSheet> {
  late final _name = TextEditingController(text: widget.tracker?.name ?? '');
  late String? _includedIn = widget.tracker?.includedIn;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(TrackerRenamed(name, includedIn: _includedIn));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.m,
        children: [
          AppTextField(
            controller: _name,
            hint: l10n.trackerNameHint,
            maxLength: 60,
            autofocus: widget.tracker == null,
            color: context.colors.surfaceRaised,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          if (widget.tracker != null && widget.others.isNotEmpty) _includedPicker(context),
          AppButton(label: l10n.actionSave, onPressed: _name.text.trim().isEmpty ? null : _save),
        ],
      ),
    );
  }

  /// „Kosten enthalten in“: eigene Kosten oder eine andere Kategorie.
  Widget _includedPicker(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    Widget chip(String label, String? value, {Color? swatch}) => AppPressable(
      onTap: () => setState(() => _includedIn = value),
      child: AppChip(
        label: label,
        background: _includedIn == value ? c.accentSoft : c.fill,
        foreground: _includedIn == value ? c.accent : c.textSecondary,
      ),
    );
    return AppCard(
      color: c.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.s,
        children: [
          AppText(l10n.trackerIncludedIn, style: (t) => t.headline),
          Wrap(
            spacing: Spacing.s,
            runSpacing: Spacing.s,
            children: [
              chip(l10n.trackerIncludedNone, null),
              for (final other in widget.others) chip(other.name, other.id),
            ],
          ),
          AppText(l10n.trackerIncludedHint, style: (t) => t.footnote, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// Symbol eines Trackers wählen (Stremio, Fitnessfirst …) in der Farbe der Kategorie. Liefert das
/// gewählte Symbol oder `null` bei Abbruch; das der Kategorie heißt: ihr folgen.
class TrackerIconSheet extends StatelessWidget {
  const TrackerIconSheet({super.key, required this.category, required this.tracker});

  final Category category;
  final Tracker tracker;

  static Future<CategoryIcon?> show(BuildContext context, {required Category category, required Tracker tracker}) => AppSheet.show<CategoryIcon>(
    context,
    title: context.l10n.trackerIcon,
    child: TrackerIconSheet(category: category, tracker: tracker),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      children: [
        AppCard(
          color: c.surfaceRaised,
          child: IconPicker(selected: tracker.iconIn(category), swatch: category.swatch, onSelect: (icon) => Navigator.of(context).pop(icon)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xs, Spacing.s, Spacing.xs, 0),
          child: AppText(context.l10n.trackerIconHint, style: (t) => t.footnote, color: c.textSecondary),
        ),
      ],
    );
  }
}
