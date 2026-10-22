import 'reminder_planner.dart';

/// Lokale Benachrichtigungen des Systems.
abstract interface class NotificationGateway {
  /// Fragt das System (einmal pro Installation zeigt es den Dialog).
  Future<bool> requestPermission();

  Future<bool> hasPermission();

  /// Ersetzt alle geplanten Erinnerungen; [channel] ist der Kanalname unter Android.
  Future<void> replaceAll(List<PlannedReminder> reminders, {required String channel});
}

/// Für Tests: merkt sich nur, was geplant wäre.
class MemoryNotificationGateway implements NotificationGateway {
  MemoryNotificationGateway({this.granted = true});

  bool granted;
  var scheduled = <PlannedReminder>[];

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders, {required String channel}) async => scheduled = [...reminders];
}
