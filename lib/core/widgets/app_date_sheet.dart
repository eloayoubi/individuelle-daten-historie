import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// Datum wählen mit dem iOS-Rad. Liefert das Datum (lokale Mitternacht) oder `null` bei Abbruch.
class AppDateSheet extends StatefulWidget {
  const AppDateSheet({super.key, required this.initial, this.minimum, this.maximum});

  final DateTime initial;
  final DateTime? minimum;
  final DateTime? maximum;

  static Future<DateTime?> show(BuildContext context, {required DateTime initial, DateTime? minimum, DateTime? maximum}) => AppSheet.show<DateTime>(
    context,
    title: context.l10n.datePickerTitle,
    child: AppDateSheet(initial: initial, minimum: minimum, maximum: maximum),
  );

  @override
  State<AppDateSheet> createState() => _AppDateSheetState();
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
