import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import 'appearance_pickers.dart';

/// Name, Symbol und Farbe einer Kategorie ändern. Liefert die neuen Werte oder `null`.
class CategoryEditSheet extends StatefulWidget {
  const CategoryEditSheet({super.key, required this.category});

  final Category category;

  static Future<({String name, CategoryIcon icon, CategorySwatch swatch})?> show(BuildContext context, Category category) =>
      AppSheet.show(context, title: context.l10n.detailEditCategory, child: CategoryEditSheet(category: category));

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
          onPressed: _name.text.trim().isEmpty ? null : () => Navigator.of(context).pop((name: _name.text.trim(), icon: _icon, swatch: _swatch)),
        ),
      ],
    );
  }
}

/// Was im Tracker-Sheet passiert ist: gespeichert (Name, wohin die Kosten zählen) oder archivieren.
sealed class TrackerSheetResult {
  const TrackerSheetResult();
}

class TrackerRenamed extends TrackerSheetResult {
  const TrackerRenamed(this.name, {this.includedIn});

  final String name;

  /// Kategorie, in deren Kosten der Tracker steckt (`null` = eigene Kosten).
  final String? includedIn;
}

class TrackerArchiveRequested extends TrackerSheetResult {
  const TrackerArchiveRequested();
}

/// Tracker anlegen (ohne [tracker]) oder umbenennen, Kosten einer anderen Kategorie zuordnen
/// ([others]) und archivieren.
class TrackerSheet extends StatefulWidget {
  const TrackerSheet({super.key, this.tracker, this.others = const []});

  final Tracker? tracker;
  final List<Category> others;

  static Future<TrackerSheetResult?> show(BuildContext context, {Tracker? tracker, List<Category> others = const []}) => AppSheet.show<TrackerSheetResult>(
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
          if (widget.tracker != null)
            AppButton(
              label: l10n.trackerArchive,
              variant: AppButtonVariant.destructive,
              onPressed: () => Navigator.of(context).pop(const TrackerArchiveRequested()),
            ),
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
