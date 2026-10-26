import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/dashboard_figures.dart';

/// Name und Gruppe eines Zählers (Gruppe `null` = ohne).
class MeterDraft {
  const MeterDraft(this.name, this.group);

  final String name;
  final String? group;
}

/// Ergebnis von [MeterSheet]: der Zähler und beim ersten Hinzufügen der bisherige erste Zähler.
class MeterSheetResult {
  const MeterSheetResult(this.meter, {this.first});

  final MeterDraft meter;
  final MeterDraft? first;
}

/// Zähler hinzufügen ([meter] `null`) oder Name und Gruppe ändern. Beim Hinzufügen führt die Wahl
/// von Ort und Gruppe zum Namen („Bad“ + „Warmwasser“ → „Bad warm“). Hat der Tracker bisher nur
/// einen Zähler ohne Gruppe, lässt er sich gleich mit benennen – so trennt die Übersicht beide.
/// Mit [setup] wird der noch unbenannte Zähler aus der Vorlage zum ersten Zähler – wie beim
/// Hinzufügen, nur ohne neues Feld.
class MeterSheet extends StatefulWidget {
  const MeterSheet({super.key, required this.category, required this.tracker, this.meter, this.setup = false});

  final Category category;
  final Tracker tracker;
  final FieldDefinition? meter;
  final bool setup;

  static Future<MeterSheetResult?> show(
    BuildContext context, {
    required Category category,
    required Tracker tracker,
    FieldDefinition? meter,
    bool setup = false,
  }) => AppSheet.show<MeterSheetResult>(
    context,
    title: meter == null || setup ? context.l10n.meterAdd : context.l10n.meterEdit,
    child: MeterSheet(category: category, tracker: tracker, meter: meter, setup: setup),
  );

  /// Versorgungszähler, dessen einziger Zähler noch so heißt wie in der Vorlage und noch keinen
  /// Stand hat: Erst wird der Zähler angelegt, dann eingetragen.
  static bool needsSetup(BuildContext context, Tracker tracker) {
    final meter = tracker.meter;
    return tracker.isUtilityMeter &&
        tracker.meters.length == 1 &&
        meter!.meterGroup == null &&
        meter.name == context.l10n.tplFieldReading &&
        !tracker.entries.any((e) => e.values.containsKey(meter.id));
  }

  /// Wasser: Vorlage „Wasser“ oder Kubikmeter ohne Umrechnung (Gas rechnet in kWh um).
  static bool isWater(Category category, Tracker tracker) {
    final meter = tracker.meter;
    return category.templateKey == 'wasser' || (meter?.unit == 'm³' && meter?.consumptionUnit == null);
  }

  @override
  State<MeterSheet> createState() => _MeterSheetState();
}

class _MeterSheetState extends State<MeterSheet> {
  /// Neuer Zähler: Ort wählen, Name daraus vorschlagen.
  bool get _adding => widget.meter == null || widget.setup;

  late final _name = TextEditingController(text: _adding ? '' : widget.meter!.name);
  late final _group = TextEditingController(text: widget.meter?.meterGroup ?? '');

  /// Bisheriger erster Zähler ohne Gruppe – nur beim Hinzufügen des zweiten.
  late final FieldDefinition? _first = widget.meter == null && widget.tracker.meters.length == 1 && widget.tracker.meter!.meterGroup == null
      ? widget.tracker.meter
      : null;
  late final _firstName = TextEditingController(text: _first?.name ?? '');
  final _firstGroup = TextEditingController();

  String? _place;

  /// Name selbst getippt: Ort und Gruppe überschreiben ihn nicht mehr.
  bool _nameTyped = false;
  bool _firstTyped = false;

  bool get _water => MeterSheet.isWater(widget.category, widget.tracker);

  @override
  void dispose() {
    for (final c in [_name, _group, _firstName, _firstGroup]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _places(BuildContext context) {
    final l10n = context.l10n;
    return _water
        ? [if (widget.setup) l10n.meterPlaceFlat, l10n.meterPlaceBath, l10n.meterPlaceKitchen, l10n.meterPlaceToilet, l10n.meterPlaceGuestToilet, l10n.meterPlaceBasement, l10n.meterPlaceGarden]
        : [l10n.meterPlaceFlat, l10n.meterPlaceBasement, l10n.meterPlaceGarage, l10n.meterPlaceGarden];
  }

  /// Vorschläge: Kalt- und Warmwasser beim Wasser, dazu die Gruppen, die es in der Kategorie schon gibt.
  List<String> _groups(BuildContext context) {
    final l10n = context.l10n;
    return {
      if (_water) ...[l10n.meterGroupCold, l10n.meterGroupWarm],
      ...DashboardFigures.groups(widget.category),
    }.toList();
  }

  /// „kalt“/„warm“ für den Namen aus Ort und Gruppe.
  String? _short(BuildContext context, String group) {
    final l10n = context.l10n;
    if (group == l10n.meterGroupCold) return l10n.meterShortCold;
    if (group == l10n.meterGroupWarm) return l10n.meterShortWarm;
    return null;
  }

  void _suggestName(BuildContext context) {
    if (!_adding || _nameTyped || _place == null) return;
    setState(() => _name.text = [_place!, ?_short(context, _group.text.trim())].join(' '));
  }

  void _pickGroup(BuildContext context, String group) {
    setState(() => _group.text = group);
    _suggestName(context);
    // Zweiter Zähler Warmwasser: der bisherige ist dann meist Kaltwasser (und umgekehrt).
    final l10n = context.l10n;
    if (_first != null && _firstGroup.text.trim().isEmpty) {
      final other = group == l10n.meterGroupWarm ? l10n.meterGroupCold : (group == l10n.meterGroupCold ? l10n.meterGroupWarm : null);
      if (other != null) _pickFirstGroup(context, other);
    }
  }

  void _pickFirstGroup(BuildContext context, String group) {
    setState(() {
      _firstGroup.text = group;
      if (!_firstTyped && _first?.name == context.l10n.tplFieldReading && group.isNotEmpty) _firstName.text = group;
    });
  }

  bool get _valid => _name.text.trim().isNotEmpty && (_first == null || _firstName.text.trim().isNotEmpty);

  static MeterDraft _draft(TextEditingController name, TextEditingController group) =>
      MeterDraft(name.text.trim(), group.text.trim().isEmpty ? null : group.text.trim());

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(MeterSheetResult(_draft(_name, _group), first: _first == null ? null : _draft(_firstName, _firstGroup)));
  }

  Widget _chip(BuildContext context, String label, {required bool selected, required VoidCallback onTap}) {
    final c = context.colors;
    return AppPressable(
      onTap: onTap,
      child: AppChip(label: label, background: selected ? c.accentSoft : c.fill, foreground: selected ? c.accent : c.textSecondary),
    );
  }

  Widget _groupPicker(BuildContext context, TextEditingController controller, void Function(String) pick, {required Color color}) {
    final l10n = context.l10n;
    final current = controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.s,
      children: [
        Wrap(
          spacing: Spacing.s,
          runSpacing: Spacing.s,
          children: [
            _chip(context, l10n.meterGroupNone, selected: current.isEmpty, onTap: () => pick('')),
            for (final g in _groups(context)) _chip(context, g, selected: current == g, onTap: () => pick(g)),
          ],
        ),
        AppTextField(controller: controller, hint: l10n.meterGroupHint, maxLength: 40, color: color, onChanged: (_) => setState(() {})),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final first = _first;
    Widget label(String text) => AppText(text, style: (t) => t.footnoteEmphasized, color: c.textSecondary);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          if (_adding) ...[
            label(l10n.meterPlace),
            Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.s,
              children: [
                for (final p in _places(context))
                  _chip(
                    context,
                    p,
                    selected: _place == p,
                    onTap: () {
                      setState(() => _place = _place == p ? null : p);
                      _suggestName(context);
                    },
                  ),
              ],
            ),
          ],
          label(l10n.meterGroup),
          _groupPicker(context, _group, (g) => _pickGroup(context, g), color: c.surfaceRaised),
          label(l10n.meterName),
          AppTextField(
            controller: _name,
            hint: l10n.meterNameHint,
            maxLength: 60,
            color: c.surfaceRaised,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _nameTyped = true),
            onSubmitted: (_) => _save(),
          ),
          AppText(l10n.meterGroupFooter, style: (t) => t.footnote, color: c.textSecondary),
          if (first != null)
            AppCard(
              color: c.surfaceRaised,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spacing.s,
                children: [
                  AppText(l10n.meterFirstTitle, style: (t) => t.headline),
                  AppText(l10n.meterFirstBody(first.name), style: (t) => t.footnote, color: c.textSecondary),
                  _groupPicker(context, _firstGroup, (g) => _pickFirstGroup(context, g), color: c.fill),
                  AppTextField(
                    controller: _firstName,
                    hint: l10n.meterNameHint,
                    maxLength: 60,
                    color: c.fill,
                    onChanged: (_) => setState(() => _firstTyped = true),
                  ),
                ],
              ),
            ),
          AppButton(label: _adding ? l10n.meterAdd : l10n.actionSave, onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}
