import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../attachments/view/entry_attachments.dart';
import '../../settings/data/review_prompter.dart';
import '../cubit/entry_form_cubit.dart';

/// Eintrag erfassen oder ändern – das Formular entsteht aus den Feldern des Trackers.
/// Alle Werte sind optional (ein Eintrag trägt nur, was sich ändert), mindestens einer muss da sein.
class EntryFormPage extends StatelessWidget {
  const EntryFormPage({super.key, required this.args});

  final EntryFormArgs args;

  /// Öffnet das Formular; die Zahleneingabe folgt der App-Sprache.
  static Future<void> open(BuildContext context, {required Category category, required Tracker tracker, Entry? entry}) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => EntryFormPage(
        args: EntryFormArgs(category: category, tracker: tracker, entry: entry, decimalSeparator: context.decimalSeparator),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<EntryFormCubit>(param1: args), child: _FormView(args: args));
  }
}

class _FormView extends StatefulWidget {
  const _FormView({required this.args});

  final EntryFormArgs args;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  late final EntryFormState _initial = context.read<EntryFormCubit>().state;
  late final _controllers = {
    for (final f in _initial.fields)
      if (f.kind.storage == FieldStorage.number || f.kind == FieldKind.text) f.id: TextEditingController(text: _initial.inputs[f.id] as String? ?? ''),
  };
  late final _note = TextEditingController(text: _initial.note);

  @override
  void dispose() {
    for (final c in [..._controllers.values, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onEvent(BuildContext context, EntryFormState state) {
    final l10n = context.l10n;
    switch (state.event!.kind) {
      case EntryFormEventKind.saved:
        AppToast.show(context, l10n.entrySaved);
        Navigator.of(context).pop();
        lookup<ReviewPrompter>().entrySaved();
      case EntryFormEventKind.savedOffline:
        AppToast.show(context, l10n.entrySavedOffline, icon: CupertinoIcons.cloud_upload_fill);
        Navigator.of(context).pop();
        lookup<ReviewPrompter>().entrySaved();
      case EntryFormEventKind.deleted:
        AppToast.show(context, l10n.entryDeleted, icon: CupertinoIcons.trash_fill);
        Navigator.of(context).pop();
      case EntryFormEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime current, ValueChanged<DateTime> onPicked) async {
    final picked = await AppDateSheet.show(context, initial: current, minimum: DateTime(2000), maximum: DateTime(DateTime.now().year + 5, 12, 31));
    if (picked != null) onPicked(picked);
  }

  Future<void> _delete(BuildContext context, EntryFormCubit cubit, DateTime date) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.entryDeleteTitle(context.shortDate(date)),
      message: l10n.entryDeleteBody,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (confirmed) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<EntryFormCubit>();
    final swatch = c.swatch(widget.args.category.swatch);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<EntryFormCubit, EntryFormState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) => ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
            children: [
              AppHeader(title: s.tracker.name, overline: s.isNew ? l10n.entryNew : l10n.entryEdit, onBack: () => Navigator.of(context).pop()),
              AppListGroup(
                children: [
                  AppListRow(
                    leading: AppIconTile(icon: CupertinoIcons.calendar, color: swatch),
                    title: s.validFrom ? l10n.entryValidFrom : l10n.entryDate,
                    trailing: AppText(context.shortDate(s.date), style: (t) => t.body, color: c.accent),
                    chevron: false,
                    onTap: () => _pickDate(context, s.date, cubit.setDate),
                  ),
                ],
              ),
              if (s.fields.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.xl, Spacing.xl, 0),
                  child: AppText(l10n.entryNoFields, style: (t) => t.subheadline, color: c.textSecondary),
                ),
              for (final field in s.fields) ...[
                const SizedBox(height: Spacing.l),
                Padding(padding: Spacing.screen, child: _FieldInput(field: field, state: s, controller: _controllers[field.id], onPickDate: _pickDate)),
              ],
              if (s.hasMeter) ...[
                const SizedBox(height: Spacing.l),
                AppListGroup(
                  dividerIndent: Spacing.l,
                  footer: l10n.entryMeterChangeHint,
                  children: [
                    AppListRow(
                      title: l10n.entryMeterChange,
                      trailing: AppSwitch(value: s.meterChange, semanticLabel: l10n.entryMeterChange, onChanged: cubit.setMeterChange),
                    ),
                  ],
                ),
              ],
              if (s.hasOneOff) ...[
                const SizedBox(height: Spacing.l),
                AppListGroup(
                  dividerIndent: Spacing.l,
                  footer: s.periodInvalid ? l10n.entryPeriodInvalid : l10n.entryPeriodHint,
                  children: [
                    AppListRow(
                      title: l10n.entryPeriod,
                      trailing: AppSwitch(value: s.hasPeriod, semanticLabel: l10n.entryPeriod, onChanged: cubit.setPeriodEnabled),
                    ),
                    if (s.periodStart case final DateTime from)
                      AppListRow(
                        title: l10n.entryPeriodFrom,
                        trailing: AppText(context.shortDate(from), style: (t) => t.body, color: c.accent),
                        chevron: false,
                        onTap: () => _pickDate(context, from, cubit.setPeriodStart),
                      ),
                    if (s.periodEnd case final DateTime to)
                      AppListRow(
                        title: l10n.entryPeriodTo,
                        trailing: AppText(context.shortDate(to), style: (t) => t.body, color: s.periodInvalid ? c.danger : c.accent),
                        chevron: false,
                        onTap: () => _pickDate(context, to, cubit.setPeriodEnd),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.l),
              Padding(
                padding: Spacing.screen,
                child: AppTextField(controller: _note, hint: l10n.entryNoteHint, maxLength: EntryFormState.maxNote, onChanged: cubit.setNote),
              ),
              EntryAttachments(
                categoryId: widget.args.category.id,
                entryId: s.entryId,
                isNew: s.isNew,
                canEdit: widget.args.category.canEdit,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
                child: AppButton(label: l10n.entrySave, onPressed: s.canSave ? cubit.save : null),
              ),
              if (s.values.isEmpty && s.fields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, 0),
                  child: AppText(l10n.entryNeedsValue, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
                ),
              if (!s.isNew)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, 0),
                  child: AppButton(
                    label: l10n.entryDelete,
                    variant: AppButtonVariant.destructive,
                    onPressed: s.saving ? null : () => _delete(context, cubit, s.date),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eingabe für ein Feld, passend zum Feldtyp, darunter ein Hinweis (letzter Wert, Verbrauch seitdem,
/// Fehler).
class _FieldInput extends StatelessWidget {
  const _FieldInput({required this.field, required this.state, required this.controller, required this.onPickDate});

  final FieldDefinition field;
  final EntryFormState state;
  final TextEditingController? controller;
  final Future<void> Function(BuildContext, DateTime, ValueChanged<DateTime>) onPickDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<EntryFormCubit>();
    final input = switch (field.kind) {
      FieldKind.number || FieldKind.currency || FieldKind.percent || FieldKind.text => AppTextField(
        controller: controller,
        label: field.name,
        maxLength: field.kind == FieldKind.text ? EntryFormState.maxText : 24,
        keyboardType: switch (field.kind) {
          FieldKind.text => TextInputType.text,
          // Guthaben sind negativ: dafür braucht es das Minus.
          _ when field.role == FieldRole.oneOffCost => const TextInputType.numberWithOptions(decimal: true, signed: true),
          _ => const TextInputType.numberWithOptions(decimal: true),
        },
        suffix: field.kind == FieldKind.text || _unit(field).isEmpty ? null : AppText(_unit(field), style: (t) => t.body, color: c.textSecondary),
        onChanged: (text) => cubit.setText(field.id, text),
      ),
      FieldKind.toggle => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.s),
        child: Row(
          children: [
            Expanded(child: AppText(field.name, style: (t) => t.body)),
            AppSwitch(value: state.inputs[field.id] == true, semanticLabel: field.name, onChanged: (v) => cubit.setToggle(field.id, v)),
          ],
        ),
      ),
      FieldKind.choice => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.s,
          children: [
            AppText(field.name, style: (t) => t.body),
            Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.s,
              children: [
                for (final choice in field.choices)
                  AppPressable(
                    onTap: () => cubit.setChoice(field.id, state.inputs[field.id] == choice ? null : choice),
                    child: AppChip(
                      label: choice,
                      background: state.inputs[field.id] == choice ? c.accentSoft : null,
                      foreground: state.inputs[field.id] == choice ? c.accent : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      FieldKind.date => AppCard(
        padding: EdgeInsets.zero,
        child: AppListRow(
          title: field.name,
          chevron: false,
          trailing: switch (state.inputs[field.id]) {
            final DateTime d => AppText(context.shortDate(d), style: (t) => t.body, color: c.accent),
            _ => Icon(CupertinoIcons.calendar_badge_plus, color: c.accent),
          },
          onTap: () => onPickDate(context, (state.inputs[field.id] as DateTime?) ?? state.date, (d) => cubit.setFieldDate(field.id, d)),
        ),
      ),
      FieldKind.formula => const SizedBox.shrink(),
    };
    final hint = _hint(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.xs,
      children: [
        input,
        if (hint case (final String text, final Color color))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
            child: AppText(text, style: (t) => t.footnote, color: color),
          ),
      ],
    );
  }

  static String _unit(FieldDefinition f) => switch (f.kind) {
    FieldKind.percent => '%',
    _ => f.unit ?? '',
  };

  /// Fehler zuerst, dann Hinweis auf einen Zählerwechsel, dann Verbrauch seitdem bzw. letzter Wert.
  (String, Color)? _hint(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    if (state.invalid.contains(field.id)) return (l10n.entryInvalidNumber, c.danger);
    final previous = state.previous(field);
    if (previous == null) return null;
    final (date, value) = previous;
    final last = context.fieldValue(field, value);
    if (state.meterBelow(field)) return (l10n.entryBelowLast(last), c.warning);
    if (state.meterDelta(field) case final double delta) {
      final sign = delta >= 0 ? '+' : '';
      return (l10n.entryDelta('$sign${context.amount(delta, field.usageUnit, decimals: delta.abs() < 10 ? 1 : 0)}', context.shortDate(date)), c.textSecondary);
    }
    if (field.role == FieldRole.unitPrice || field.role == FieldRole.recurringCost) {
      return (l10n.entryCurrent(last, context.shortDate(date)), c.textSecondary);
    }
    return (l10n.entryLast(last, context.shortDate(date)), c.textSecondary);
  }
}
