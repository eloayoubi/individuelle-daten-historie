import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../data/home_overview.dart';

/// „Als Nächstes“: Stichtage, die näher rücken, und Zähler, die abgelesen werden wollen.
class ReminderRows extends StatelessWidget {
  const ReminderRows({super.key, required this.reminders, required this.onTap});

  final List<Reminder> reminders;
  final ValueChanged<Reminder> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return AppListGroup(
      children: [
        for (final r in reminders)
          switch (r.kind) {
            ReminderKind.readMeter => AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.speedometer, color: c.swatch(r.category.swatch)),
              title: l10n.homeReadMeter(r.trackerName),
              subtitle: l10n.homeReadMeterDue(r.days),
              onTap: () => onTap(r),
            ),
            ReminderKind.deadline => AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.calendar, color: c.swatch(r.category.swatch)),
              title: l10n.homeDeadlineTitle(r.fieldName ?? '', r.trackerName),
              subtitle: l10n.homeDeadlineDue(r.days, context.shortDate(r.date!)),
              onTap: () => onTap(r),
            ),
          },
      ],
    );
  }
}
