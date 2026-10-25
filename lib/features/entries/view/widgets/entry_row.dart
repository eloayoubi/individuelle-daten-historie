import 'package:flutter/widgets.dart';

import '../../../../core/core.dart';

/// Ein Eintrag in der Liste: Datum (bei einer Rechnung der Zeitraum), darunter wer ihn erfasst hat und
/// die Werte. Antippen öffnet ihn zum Bearbeiten.
class EntryRow extends StatelessWidget {
  const EntryRow({super.key, required this.category, required this.tracker, required this.entry, this.onTap});

  final Category category;
  final Tracker tracker;
  final Entry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = entry;
    final bill = tracker.isBill(e);
    return AppListRow(
      title: bill ? l10n.entryPeriodRange(context.shortDate(e.periodStart!), context.shortDate(e.periodEnd!)) : context.shortWeekdayDate(e.date),
      subtitle: context.joinParts([
        if (category.sharedWith.where((m) => m.userId == e.createdBy).firstOrNull case final CategoryMember by) l10n.entryBy(by.name.isEmpty ? l10n.shareNoName : by.name),
        if (bill) l10n.entryKindBill,
        if (e.meterChange) l10n.trackerMeterChanged,
        for (final f in tracker.fields)
          if (!f.isDetail)
            if (e.values[f.id] case final Object v)
              bill && f.role == FieldRole.meterReading && v is num
                  ? l10n.entryFieldValue(l10n.entryBillConsumption, context.amount(v.toDouble(), f.usageUnit))
                  : l10n.entryFieldValue(f.name, context.fieldValue(f, v)),
        e.note,
      ]),
      onTap: onTap,
    );
  }
}
