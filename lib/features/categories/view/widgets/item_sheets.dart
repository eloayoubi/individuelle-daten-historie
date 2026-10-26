import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/numbers.dart';
import '../../data/category_templates.dart';
import '../../data/tracker_groups.dart';

/// Ein Abo (eine Versicherung …) hinzufügen: Name aus den Vorschlägen je Art oder selbst getippt,
/// Art, Betrag mit Intervall und ab wann er gilt. Vorschläge, die es in der Kategorie schon gibt,
/// fehlen. Liefert den [ItemDraft] oder `null` bei Abbruch.
class ItemSheet extends StatefulWidget {
  const ItemSheet({super.key, required this.item, required this.category});

  final ItemTemplate item;
  final Category category;

  static Future<ItemDraft?> show(BuildContext context, {required ItemTemplate item, required Category category}) =>
      AppSheet.show<ItemDraft>(context, title: item.add, child: ItemSheet(item: item, category: category));

  @override
  State<ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<ItemSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String? _group;
  late int _interval = widget.item.defaultInterval;
  DateTime _since = DateTime.now();

  /// Art selbst gewählt: Ein Vorschlag überschreibt sie nicht mehr.
  bool _groupPicked = false;

  late final Set<String> _existing = {for (final t in widget.category.trackers) t.name.toLowerCase()};

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? get _parsedAmount => parseNumber(_amount.text, decimalSeparator: context.decimalSeparator);

  bool get _amountInvalid => _amount.text.trim().isNotEmpty && (_parsedAmount == null || _parsedAmount! < 0);

  bool get _valid => _name.text.trim().isNotEmpty && !_amountInvalid;

  /// Vorschläge je Art, gefiltert nach dem getippten Namen.
  List<(ItemGroup, List<String>)> get _suggestions {
    final query = _name.text.trim().toLowerCase();
    return [
      for (final g in widget.item.groups)
        if ([
          for (final s in g.suggestions)
            if (!_existing.contains(s.toLowerCase()) && (query.isEmpty || s.toLowerCase().contains(query))) s,
        ] case final List<String> matches when matches.isNotEmpty)
          (g, matches),
    ];
  }

  void _pickSuggestion(ItemGroup group, String name) {
    setState(() {
      _name.text = name;
      _name.selection = TextSelection.collapsed(offset: name.length);
      if (!_groupPicked && group.name != null) _group = group.name;
    });
  }

  Future<void> _pickSince() async {
    final now = DateTime.now();
    final picked = await AppDateSheet.show(context, initial: _since, minimum: DateTime(2000), maximum: DateTime(now.year + 1, 12, 31));
    if (picked != null) setState(() => _since = picked);
  }

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(
      ItemDraft(
        name: _name.text.trim(),
        group: widget.item.groupName == null ? null : _group,
        amount: _parsedAmount,
        interval: _interval,
        since: _since,
      ),
    );
  }

  Widget _chip(String label, {required bool selected, required VoidCallback onTap}) {
    final c = context.colors;
    return AppPressable(
      onTap: onTap,
      child: AppChip(label: label, background: selected ? c.accentSoft : c.fill, foreground: selected ? c.accent : c.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final item = widget.item;
    final name = _name.text.trim();
    Widget label(String text) => AppText(text, style: (t) => t.footnoteEmphasized, color: c.textSecondary);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          AppTextField(
            controller: _name,
            hint: item.nameHint,
            maxLength: 60,
            color: c.surfaceRaised,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          for (final (group, suggestions) in _suggestions) ...[
            label(group.name ?? l10n.itemSuggestions),
            Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.s,
              children: [for (final s in suggestions) _chip(s, selected: s == name, onTap: () => _pickSuggestion(group, s))],
            ),
          ],
          if (item.groupName != null && item.groupNames.isNotEmpty) ...[
            label(item.groupName!),
            Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.s,
              children: [
                for (final g in item.groupNames)
                  _chip(
                    g,
                    selected: _group == g,
                    onTap: () => setState(() {
                      _group = _group == g ? null : g;
                      _groupPicked = true;
                    }),
                  ),
              ],
            ),
          ],
          AppTextField(
            controller: _amount,
            label: item.amountName,
            maxLength: 24,
            color: c.surfaceRaised,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: AppText(item.amountUnits[_interval] ?? '€', style: (t) => t.body, color: c.textSecondary),
            onChanged: (_) => setState(() {}),
          ),
          AppSegmented<int>(
            value: _interval,
            segments: {1: l10n.intervalMonthly, 12: l10n.intervalYearly},
            onChanged: (interval) => setState(() => _interval = interval),
          ),
          AppListGroup(
            color: c.surfaceRaised,
            dividerIndent: Spacing.l,
            footer: _amountInvalid ? l10n.entryInvalidNumber : l10n.itemAmountFooter,
            children: [
              AppListRow(
                title: l10n.itemSince,
                trailing: AppText(context.shortDate(_since), style: (t) => t.body, color: c.accent),
                chevron: false,
                onTap: _pickSince,
              ),
            ],
          ),
          AppButton(label: item.add, icon: CupertinoIcons.plus, onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}

/// „Wert eintragen für …“: Tracker nach Art gruppiert ([groupTrackers]), je Zeile der aktuelle Betrag.
class TrackerPickerSheet extends StatelessWidget {
  const TrackerPickerSheet({super.key, required this.trackers, this.order = const []});

  final List<Tracker> trackers;

  /// Reihenfolge der Arten (aus der Vorlage).
  final List<String> order;

  static Future<Tracker?> show(BuildContext context, {required List<Tracker> trackers, List<String> order = const []}) =>
      AppSheet.show<Tracker>(context, title: context.l10n.trackerAddEntryFor, child: TrackerPickerSheet(trackers: trackers, order: order));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final groups = groupTrackers(trackers, order: order);
    final named = groups.any((g) => g.name != null);
    final today = DateTime.now();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: [
        for (final group in groups) ...[
          if (named)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.xs),
              child: AppText(group.name ?? l10n.itemOtherGroup, style: (t) => t.footnoteEmphasized, color: c.textSecondary),
            ),
          AppListGroup(
            color: c.surfaceRaised,
            dividerIndent: Spacing.l,
            children: [
              for (final t in group.trackers)
                AppListRow(
                  title: t.name,
                  subtitle: switch (t.currentAmount(today)) {
                    (final field, final value) => context.fieldValue(field, value),
                    null => null,
                  },
                  onTap: () => Navigator.of(context).pop(t),
                ),
            ],
          ),
          const SizedBox(height: Spacing.m),
        ],
      ],
    );
  }
}
