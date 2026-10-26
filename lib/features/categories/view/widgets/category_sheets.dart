import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import 'appearance_pickers.dart';

/// Ergebnis des Bearbeiten-Sheets: neue Werte oder der Wunsch, einen weiteren Tracker anzulegen.
sealed class CategoryEditResult {
  const CategoryEditResult();
}

class CategoryEdited extends CategoryEditResult {
  const CategoryEdited({required this.name, required this.icon, required this.swatch});

  final String name;
  final CategoryIcon icon;
  final CategorySwatch swatch;
}

class CategoryAddTracker extends CategoryEditResult {
  const CategoryAddTracker();
}

/// Name, Symbol und Farbe einer Kategorie ändern; mit [canAddTracker] darunter „Weiteren Tracker
/// hinzufügen“. Liefert das Ergebnis oder `null` bei Abbruch.
class CategoryEditSheet extends StatefulWidget {
  const CategoryEditSheet({super.key, required this.category, this.canAddTracker = false});

  final Category category;
  final bool canAddTracker;

  static Future<CategoryEditResult?> show(BuildContext context, Category category, {bool canAddTracker = false}) => AppSheet.show<CategoryEditResult>(
    context,
    title: context.l10n.detailEditCategory,
    child: CategoryEditSheet(category: category, canAddTracker: canAddTracker),
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
        if (widget.canAddTracker) ...[
          const SizedBox(height: Spacing.s),
          AppButton(
            label: l10n.detailAddAnotherTracker,
            icon: CupertinoIcons.plus,
            variant: AppButtonVariant.tinted,
            onPressed: () => Navigator.of(context).pop(const CategoryAddTracker()),
          ),
        ],
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
