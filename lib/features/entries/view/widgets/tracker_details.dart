import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/cost_engine.dart';
import '../../../../core/utils/numbers.dart';

/// Details eines Trackers (Anbieter, Vertragsnummer, Vertragsende): Name links, Wert rechts.
/// Antippen ändert den Wert, Ja/Nein schaltet direkt. Ohne [onSave] nur lesen.
class TrackerDetailsGroup extends StatelessWidget {
  const TrackerDetailsGroup({super.key, required this.tracker, this.onSave});

  final Tracker tracker;

  /// Neuer Wert eines Details, `null` entfernt es.
  final Future<void> Function(FieldDefinition field, Object? value)? onSave;

  @override
  Widget build(BuildContext context) {
    return AppListGroup(
      dividerIndent: Spacing.l,
      children: [
        for (final field in tracker.detailFields)
          _DetailRow(field: field, value: tracker.detailValue(field.id), onSave: onSave == null ? null : (value) => onSave!(field, value)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.field, required this.value, required this.onSave});

  /// Platz für den Wert rechts (längere werden gekürzt).
  static const _valueWidth = 180.0;

  /// Ab so vielen Tagen zählt ein Stichtag in Monaten.
  static const _daysBeforeMonths = 60;

  final FieldDefinition field;
  final Object? value;
  final ValueChanged<Object?>? onSave;

  Future<void> _edit(BuildContext context) async {
    final result = await DetailSheet.show(context, field: field, value: value);
    if (result != null) onSave?.call(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    if (field.kind == FieldKind.toggle) {
      return AppListRow(
        title: field.name,
        trailing: AppSwitch(value: value == true, semanticLabel: field.name, onChanged: onSave == null ? null : (on) => onSave!(on)),
      );
    }
    final due = _due(context);
    return AppListRow(
      title: field.name,
      subtitleWidget: due == null ? null : AppText(due.$1, style: (t) => t.footnote, color: due.$2),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _valueWidth),
        child: switch (value) {
          final Object v => AppText(
            context.fieldValue(field, v),
            style: (t) => t.body,
            color: c.textSecondary,
            maxLines: 1,
            align: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
          null when onSave != null => AppText(l10n.detailAdd, style: (t) => t.body, color: c.accent),
          null => AppText('–', style: (t) => t.body, color: c.textTertiary),
        },
      ),
      onTap: onSave == null ? null : () => _edit(context),
    );
  }

  /// Bei Stichtagen: wie lange noch – rot, wenn vorbei, orange im letzten Monat.
  (String, Color)? _due(BuildContext context) {
    final date = value;
    if (field.role != FieldRole.deadline || date is! DateTime) return null;
    final c = context.colors;
    final l10n = context.l10n;
    final days = CostEngine.day(date).difference(CostEngine.day(DateTime.now())).inDays;
    if (days < 0) return (l10n.detailOverdue, c.danger);
    if (days > _daysBeforeMonths) return (l10n.detailDueInMonths((days / 30.44).round()), c.textSecondary);
    return (l10n.detailDueIn(days), days <= 30 ? c.warning : c.textSecondary);
  }
}

/// Ein Detail ändern: Eingabe passend zum Feldtyp, Speichern und – wenn es schon einen Wert gibt –
/// Entfernen. Liefert `(value: …)` (`null` = entfernen) oder `null` bei Abbruch.
class DetailSheet extends StatefulWidget {
  const DetailSheet({super.key, required this.field, this.value, required this.decimalSeparator});

  final FieldDefinition field;
  final Object? value;
  final String decimalSeparator;

  static Future<({Object? value})?> show(BuildContext context, {required FieldDefinition field, Object? value}) => AppSheet.show<({Object? value})>(
    context,
    title: field.name,
    child: DetailSheet(field: field, value: value, decimalSeparator: context.decimalSeparator),
  );

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  /// Höhe des Datums-Rads wie bei Apple.
  static const _wheelHeight = 216.0;

  late final _text = TextEditingController(
    text: switch (widget.value) {
      final num n => formatNumberInput(n, decimalSeparator: widget.decimalSeparator),
      final String s => s,
      _ => '',
    },
  );
  late var _date = switch (widget.value) {
    final DateTime d => DateTime(d.year, d.month, d.day),
    _ => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  };
  late String? _choice = switch (widget.value) {
    final String s => s,
    _ => null,
  };

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Was gespeichert würde; `null`, solange die Eingabe leer oder keine Zahl ist.
  Object? get _result => switch (widget.field.kind) {
    FieldKind.number || FieldKind.currency || FieldKind.percent => parseNumber(_text.text, decimalSeparator: widget.decimalSeparator),
    FieldKind.text when _text.text.trim().isNotEmpty => _text.text.trim(),
    FieldKind.date => CostEngine.day(_date),
    FieldKind.choice => _choice,
    _ => null,
  };

  /// Speichert, was jetzt eingegeben ist (nicht den Stand des letzten Frames).
  void _save() {
    if (_result case final Object value) Navigator.of(context).pop((value: value));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final field = widget.field;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          switch (field.kind) {
            FieldKind.date => SizedBox(
              height: _wheelHeight,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _date,
                minimumDate: DateTime(2000),
                maximumDate: DateTime(DateTime.now().year + 30, 12, 31),
                onDateTimeChanged: (d) => _date = DateTime(d.year, d.month, d.day),
              ),
            ),
            FieldKind.choice => Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.s,
              children: [
                for (final choice in field.choices)
                  AppPressable(
                    onTap: () => setState(() => _choice = choice),
                    child: AppChip(
                      label: choice,
                      background: _choice == choice ? c.accentSoft : c.fill,
                      foreground: _choice == choice ? c.accent : c.textSecondary,
                    ),
                  ),
              ],
            ),
            _ => AppTextField(
              controller: _text,
              autofocus: true,
              color: c.surfaceRaised,
              maxLength: field.kind == FieldKind.text ? 500 : 24,
              keyboardType: field.kind == FieldKind.text ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true, signed: true),
              textInputAction: TextInputAction.done,
              suffix: switch (field.kind) {
                FieldKind.percent => AppText('%', style: (t) => t.body, color: c.textSecondary),
                FieldKind.text => null,
                _ when (field.unit ?? '').isEmpty => null,
                _ => AppText(field.unit!, style: (t) => t.body, color: c.textSecondary),
              },
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
          },
          AppButton(label: l10n.actionSave, onPressed: _result == null ? null : _save),
          if (widget.value != null)
            AppButton(label: l10n.detailRemove, variant: AppButtonVariant.destructive, onPressed: () => Navigator.of(context).pop((value: null))),
        ],
      ),
    );
  }
}
