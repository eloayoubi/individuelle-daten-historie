import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../core/utils/formulas.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/field_editor_cubit.dart';

/// Feld anlegen oder ändern: Name, Feldtyp, Zeitverhalten und was der Typ braucht
/// (Einheit, Umrechnung beim Zähler, Fälligkeit, Auswahlwerte).
class FieldEditorPage extends StatelessWidget {
  const FieldEditorPage({super.key, required this.args});

  final FieldEditorArgs args;

  static Future<void> open(BuildContext context, FieldEditorArgs args) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => FieldEditorPage(args: args)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<FieldEditorCubit>(param1: args), child: const _EditorView());
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  late final FieldEditorState _initial = context.read<FieldEditorCubit>().state;
  late final _name = TextEditingController(text: _initial.name);
  late final _unit = TextEditingController(text: _initial.unit);
  late final _consumptionUnit = TextEditingController(text: _initial.consumptionUnit);
  late final _factor = TextEditingController(text: _initial.factorText);
  final _choice = TextEditingController();
  late final _formula = TextEditingController(text: _initial.formula);

  /// Text an der Cursor-Stelle einsetzen; [cursor] = Abstand der neuen Cursor-Position vom Anfang.
  void _insert(FieldEditorCubit cubit, String text, {int? cursor}) {
    final value = _formula.text;
    final selection = _formula.selection;
    final start = selection.isValid ? selection.start : value.length;
    final end = selection.isValid ? selection.end : value.length;
    final next = value.replaceRange(start, end, text);
    _formula.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + (cursor ?? text.length)));
    cubit.setFormula(next);
  }

  @override
  void dispose() {
    for (final c in [_name, _unit, _consumptionUnit, _factor, _choice, _formula]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onEvent(BuildContext context, FieldEditorState state) {
    final l10n = context.l10n;
    switch (state.event!.kind) {
      case FieldEditorEventKind.saved:
        AppToast.show(context, l10n.fieldSaved);
        Navigator.of(context).pop();
      case FieldEditorEventKind.archived:
        AppToast.show(context, l10n.fieldArchived, icon: CupertinoIcons.archivebox_fill);
        Navigator.of(context).pop();
      case FieldEditorEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  void _addChoice(FieldEditorCubit cubit) {
    cubit.addChoice(_choice.text);
    _choice.clear();
  }

  Future<void> _archive(BuildContext context, FieldEditorCubit cubit, String name) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.fieldArchiveTitle(name),
      message: l10n.fieldArchiveBody,
      confirmLabel: l10n.fieldArchive,
      destructive: true,
    );
    if (confirmed) await cubit.archive();
  }

  /// Passende Einheiten zum Antippen, je nach Zeitverhalten.
  static List<String> _unitSuggestions(FieldEditorState s, AppLocalizations l10n) => switch ((s.kind, s.role)) {
    (_, FieldRole.meterReading) => const ['kWh', 'm³', 'km', 'l'],
    (_, FieldRole.unitPrice) => const ['€/kWh', '€/m³', '€/l'],
    (_, FieldRole.recurringCost) => [l10n.unitPerMonth, l10n.unitPerYear],
    (_, FieldRole.oneOffCost) => const ['€'],
    (FieldKind.currency, _) => ['€', l10n.unitPerMonth],
    _ => const ['kg', 'l', 'GB', 'h'],
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<FieldEditorCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<FieldEditorCubit, FieldEditorState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) => ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
            children: [
              AppHeader(title: s.isNew ? l10n.fieldNew : _initial.name, onBack: () => Navigator.of(context).pop()),
              Padding(
                padding: Spacing.screen,
                child: AppTextField(
                  controller: _name,
                  hint: l10n.fieldNameHint,
                  maxLength: FieldEditorState.maxName,
                  autofocus: s.isNew,
                  textInputAction: TextInputAction.done,
                  onChanged: cubit.setName,
                ),
              ),
              SectionHeader(title: l10n.fieldKind),
              AppListGroup(
                children: [
                  for (final kind in FieldKind.values)
                    Opacity(
                      opacity: s.canPick(kind) ? 1 : 0.45,
                      child: AppListRow(
                        leading: AppIconTile(icon: kind.icon, color: c.accent),
                        title: kind.label(l10n),
                        subtitle: s.canPick(kind) ? null : l10n.fieldKindLocked,
                        trailing: kind == s.kind ? Icon(CupertinoIcons.checkmark_alt, size: 20, color: c.accent) : null,
                        chevron: false,
                        onTap: s.canPick(kind) ? () => cubit.setKind(kind) : null,
                      ),
                    ),
                ],
              ),
              SectionHeader(title: l10n.fieldRole),
              AppListGroup(
                dividerIndent: Spacing.l,
                footer: l10n.fieldRoleFooter,
                children: [
                  for (final role in s.kind.roles)
                    AppListRow(
                      title: role.label(l10n),
                      subtitle: role.hint(l10n),
                      trailing: role == s.role ? Icon(CupertinoIcons.checkmark_alt, size: 20, color: c.accent) : null,
                      chevron: false,
                      onTap: () => cubit.setRole(role),
                    ),
                ],
              ),
              if (s.kind.hasUnit) ...[
                SectionHeader(title: l10n.fieldUnit),
                Padding(
                  padding: Spacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.s,
                    children: [
                      AppTextField(
                        controller: _unit,
                        hint: l10n.fieldUnitHint,
                        maxLength: FieldEditorState.maxUnit,
                        textCapitalization: TextCapitalization.none,
                        onChanged: cubit.setUnit,
                      ),
                      Wrap(
                        spacing: Spacing.s,
                        runSpacing: Spacing.s,
                        children: [
                          for (final unit in _unitSuggestions(s, l10n))
                            AppPressable(
                              onTap: () {
                                _unit.text = unit;
                                cubit.setUnit(unit);
                              },
                              child: AppChip(
                                label: unit,
                                background: s.unit == unit ? c.accentSoft : null,
                                foreground: s.unit == unit ? c.accent : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (s.kind == FieldKind.formula) ...[
                SectionHeader(title: l10n.fieldFormula),
                Padding(padding: Spacing.screen, child: _FormulaEditor(state: s, controller: _formula, onInsert: (text, cursor) => _insert(cubit, text, cursor: cursor))),
              ],
              if (s.role == FieldRole.meterReading) ...[
                SectionHeader(title: l10n.fieldMeter),
                Padding(
                  padding: Spacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.s,
                    children: [
                      AppTextField(
                        controller: _consumptionUnit,
                        label: l10n.fieldConsumptionUnitLabel,
                        hint: l10n.fieldConsumptionUnitHint,
                        maxLength: FieldEditorState.maxUnit,
                        textCapitalization: TextCapitalization.none,
                        onChanged: cubit.setConsumptionUnit,
                      ),
                      AppTextField(
                        controller: _factor,
                        label: l10n.fieldFactorLabel,
                        hint: '1',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: cubit.setFactor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                        child: AppText(
                          s.factorValid ? l10n.fieldFactorFooter : l10n.fieldFactorInvalid,
                          style: (t) => t.footnote,
                          color: s.factorValid ? c.textSecondary : c.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (s.role == FieldRole.recurringCost) ...[
                SectionHeader(title: l10n.fieldInterval),
                Padding(
                  padding: Spacing.screen,
                  child: AppSegmented<int>(
                    value: FieldIntervals.values.contains(s.intervalMonths) ? s.intervalMonths : 1,
                    segments: {for (final months in FieldIntervals.values) months: FieldIntervals.label(l10n, months)},
                    onChanged: cubit.setInterval,
                  ),
                ),
              ],
              if (s.kind == FieldKind.choice) ...[
                SectionHeader(title: l10n.fieldChoices),
                if (s.choices.isNotEmpty) ...[
                  AppListGroup(
                    dividerIndent: Spacing.l,
                    children: [
                      for (final choice in s.choices)
                        AppListRow(
                          title: choice,
                          chevron: false,
                          trailing: AppIconButton(
                            icon: CupertinoIcons.minus_circle_fill,
                            semanticLabel: l10n.fieldChoiceRemove(choice),
                            size: 32,
                            background: c.surface,
                            foreground: c.danger,
                            onPressed: () => cubit.removeChoice(choice),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.s),
                ],
                Padding(
                  padding: Spacing.screen,
                  child: Row(
                    spacing: Spacing.s,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _choice,
                          hint: l10n.fieldChoiceHint,
                          maxLength: FieldEditorState.maxChoice,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addChoice(cubit),
                        ),
                      ),
                      AppIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.fieldChoiceHint, filled: true, onPressed: () => _addChoice(cubit)),
                    ],
                  ),
                ),
                if (s.choices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, 0),
                    child: AppText(l10n.fieldChoicesEmpty, style: (t) => t.footnote, color: c.textSecondary),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
                child: AppButton(label: l10n.actionSave, onPressed: s.canSave ? cubit.save : null),
              ),
              if (!s.isNew)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, 0),
                  child: AppButton(
                    label: l10n.fieldArchive,
                    variant: AppButtonVariant.destructive,
                    onPressed: s.saving ? null : () => _archive(context, cubit, _initial.name),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ausdruck, Prüfung mit Fehlerstelle oder Vorschau, dazu Namen und Funktionen zum Antippen.
class _FormulaEditor extends StatelessWidget {
  const _FormulaEditor({required this.state, required this.controller, required this.onInsert});

  final FieldEditorState state;
  final TextEditingController controller;
  final void Function(String text, int? cursor) onInsert;

  /// So viele Nachkommastellen, wie das Ergebnis braucht (höchstens zwei).
  static int _decimals(double v) => v == v.roundToDouble() ? 0 : ((v * 10).roundToDouble() == v * 10 ? 1 : 2);

  static const _functionsDe = [('min(;)', 4), ('max(;)', 4), ('runden(;2)', 7), ('wenn(;;)', 5), ('abs()', 4)];
  static const _functionsEn = [('min(;)', 4), ('max(;)', 4), ('round(;2)', 6), ('if(;;)', 3), ('abs()', 4)];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final english = l10n.localeName.startsWith('en');
    final tracker = state.tracker;
    final check = state.formulaCheck;
    final (status, statusColor) = switch ((state.formula.trim().isEmpty, check.error, check.formula, tracker)) {
      (true, _, _, _) => (null, c.textSecondary),
      (false, final error?, _, _) => (error.message(l10n), c.danger),
      (false, null, final formula?, final t?) => switch (Formulas.preview(formula, t)) {
        final double v => (l10n.fieldFormulaPreview(context.amount(v, state.unit.trim(), decimals: _decimals(v))), c.success),
        null => (l10n.fieldFormulaNoPreview, c.textSecondary),
      },
      _ => (null, c.textSecondary),
    };
    Widget chips(Iterable<(String, int?)> items) => Wrap(
      spacing: Spacing.s,
      runSpacing: Spacing.s,
      children: [
        for (final (text, cursor) in items)
          AppPressable(
            onTap: () => onInsert(text, cursor),
            child: AppChip(label: text, background: c.accentSoft, foreground: c.accent),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.s,
      children: [
        AppTextField(
          controller: controller,
          hint: l10n.fieldFormulaHint,
          maxLength: 500,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          onChanged: context.read<FieldEditorCubit>().setFormula,
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
            child: AppText(status, style: (t) => t.footnoteEmphasized, color: statusColor),
          ),
        if (tracker != null) ...[
          AppText(l10n.fieldFormulaValues.toUpperCase(), style: (t) => t.caption2Emphasized, color: c.textSecondary),
          chips([for (final name in Formulas.available(tracker, english: english)) (name, null)]),
        ],
        AppText(l10n.fieldFormulaFunctions.toUpperCase(), style: (t) => t.caption2Emphasized, color: c.textSecondary),
        chips(english ? _functionsEn : _functionsDe),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
          child: AppText(l10n.fieldFormulaFooter, style: (t) => t.footnote, color: c.textSecondary),
        ),
      ],
    );
  }
}
