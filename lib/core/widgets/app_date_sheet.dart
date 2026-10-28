import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';
import '../extensions/format_x.dart';
import '../theme/dimensions.dart';
import 'app_button.dart';
import 'app_list.dart';
import 'app_sheet.dart';

/// Datum wählen mit dem iOS-Rad. Liefert das Datum (lokale Mitternacht) oder `null` bei Abbruch.
class AppDateSheet extends StatefulWidget {
  const AppDateSheet({super.key, required this.initial, this.minimum, this.maximum});

  final DateTime initial;
  final DateTime? minimum;
  final DateTime? maximum;

  /// [title] statt „Datum wählen“, z. B. „Beginn des Zeitraums“.
  static Future<DateTime?> show(BuildContext context, {required DateTime initial, DateTime? minimum, DateTime? maximum, String? title}) =>
      AppSheet.show<DateTime>(
        context,
        title: title ?? context.l10n.datePickerTitle,
        child: AppDateSheet(initial: initial, minimum: minimum, maximum: maximum),
      );

  /// Erst Schnellwahl – Anfang des Monats, Anfang des Jahres, Heute –, darunter „Individuell“ mit
  /// dem Rad. [selected] ist abgehakt; liefert das Datum (lokale Mitternacht) oder `null`.
  static Future<DateTime?> choose(BuildContext context, {required DateTime selected, DateTime? minimum, DateTime? maximum, String? title, DateTime? today}) {
    final now = today ?? DateTime.now();
    return AppSheet.show<DateTime>(
      context,
      title: title ?? context.l10n.datePickerTitle,
      child: _PresetList(selected: DateTime(selected.year, selected.month, selected.day), today: DateTime(now.year, now.month, now.day), minimum: minimum, maximum: maximum),
    );
  }

  @override
  State<AppDateSheet> createState() => _AppDateSheetState();
}

class _PresetList extends StatelessWidget {
  const _PresetList({required this.selected, required this.today, this.minimum, this.maximum});

  final DateTime selected;
  final DateTime today;
  final DateTime? minimum;
  final DateTime? maximum;

  Future<void> _custom(BuildContext context) async {
    final navigator = Navigator.of(context);
    final picked = await AppDateSheet.show(context, initial: selected, minimum: minimum, maximum: maximum);
    if (picked != null) navigator.pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final presets = [
      (l10n.datePresetMonthStart, DateTime(today.year, today.month)),
      (l10n.datePresetYearStart, DateTime(today.year)),
      (l10n.datePresetToday, today),
    ];
    final custom = !presets.any((p) => p.$2 == selected);
    Widget? check(bool on) => on ? Icon(CupertinoIcons.checkmark_alt, color: c.accent) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: AppListGroup(
        color: c.surfaceRaised,
        dividerIndent: Spacing.l,
        children: [
          for (final (label, date) in presets)
            AppListRow(
              title: label,
              subtitle: context.shortDate(date),
              trailing: check(date == selected),
              chevron: false,
              onTap: () => Navigator.of(context).pop(date),
            ),
          AppListRow(
            title: l10n.datePresetCustom,
            subtitle: custom ? context.shortDate(selected) : null,
            trailing: check(custom),
            onTap: () => _custom(context),
          ),
        ],
      ),
    );
  }
}

class _AppDateSheetState extends State<AppDateSheet> {
  /// Höhe des Rads wie bei Apple.
  static const _wheelHeight = 216.0;

  late var _date = DateTime(widget.initial.year, widget.initial.month, widget.initial.day);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.m,
        children: [
          SizedBox(
            height: _wheelHeight,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date,
              minimumDate: widget.minimum,
              maximumDate: widget.maximum,
              onDateTimeChanged: (date) => _date = DateTime(date.year, date.month, date.day),
            ),
          ),
          AppButton(label: context.l10n.actionDone, onPressed: () => Navigator.of(context).pop(_date)),
        ],
      ),
    );
  }
}
