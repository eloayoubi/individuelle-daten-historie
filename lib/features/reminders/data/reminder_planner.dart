import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../core/models/tracking.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Eine geplante Benachrichtigung.
class PlannedReminder extends Equatable {
  const PlannedReminder({required this.id, required this.at, required this.title, required this.body});

  final int id;

  /// Ortszeit.
  final DateTime at;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, at, title, body];
}

/// Plant Erinnerungen aus den Daten – bei jeder Änderung neu, alte werden ersetzt:
///
/// - **Ablesen:** 30 Tage nach dem letzten Zählerstand um 18 Uhr; ist das vorbei, beim nächsten
///   18-Uhr-Termin (eine Erinnerung je Zähler, keine Serie).
/// - **Stichtage:** 30, 7 und 1 Tag vorher um 9 Uhr, nur künftige.
/// - Höchstens [limit] (iOS erlaubt 64 geplante), die frühesten zuerst.
abstract final class ReminderPlanner {
  static const readAfterDays = 30;
  static const deadlineOffsets = [30, 7, 1];
  static const readHour = 18;
  static const deadlineHour = 9;
  static const limit = 60;

  static List<PlannedReminder> plan(List<Category> categories, DateTime now, AppLocalizations l10n) {
    final dates = DateFormat.yMd(l10n.localeName);
    final planned = <PlannedReminder>[];
    for (final category in categories) {
      if (category.isArchived || !category.canEdit) continue;
      for (final tracker in category.trackers) {
        if (tracker.firstWithRole(FieldRole.meterReading) case final FieldDefinition meter) {
          final last = _latest(tracker, meter.id)?.date;
          if (last != null) {
            var at = DateTime(last.year, last.month, last.day + readAfterDays, readHour);
            if (!at.isAfter(now)) at = _nextAt(now, readHour);
            final days = DateTime(at.year, at.month, at.day).difference(DateTime(last.year, last.month, last.day)).inDays;
            planned.add(PlannedReminder(id: _id('read:${tracker.id}'), at: at, title: l10n.homeReadMeter(tracker.name), body: l10n.notifyReadBody(days)));
          }
        }
        for (final field in tracker.withRole(FieldRole.deadline)) {
          final due = _latest(tracker, field.id)?.values[field.id];
          if (due is! DateTime) continue;
          for (final offset in deadlineOffsets) {
            final at = DateTime(due.year, due.month, due.day - offset, deadlineHour);
            if (!at.isAfter(now)) continue;
            planned.add(
              PlannedReminder(
                id: _id('deadline:${tracker.id}:${field.id}:$offset'),
                at: at,
                title: l10n.homeDeadlineTitle(field.name, tracker.name),
                body: l10n.notifyDeadlineBody(offset, dates.format(due)),
              ),
            );
          }
        }
      }
    }
    planned.sort((a, b) => a.at.compareTo(b.at));
    return planned.take(limit).toList();
  }

  /// Neuester Eintrag mit einem Wert für das Feld.
  static Entry? _latest(Tracker tracker, String fieldId) {
    Entry? latest;
    for (final e in tracker.entries) {
      if (e.values.containsKey(fieldId) && (latest == null || e.date.isAfter(latest.date))) latest = e;
    }
    return latest;
  }

  static DateTime _nextAt(DateTime now, int hour) {
    final today = DateTime(now.year, now.month, now.day, hour);
    return today.isAfter(now) ? today : DateTime(now.year, now.month, now.day + 1, hour);
  }

  /// Gleiche Erinnerung, gleiche Id (FNV-1a, 31 Bit) – unabhängig von `String.hashCode`.
  static int _id(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
