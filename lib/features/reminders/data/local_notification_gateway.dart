import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_gateway.dart';
import 'reminder_planner.dart';

/// Lokale Benachrichtigungen über `flutter_local_notifications`.
///
/// Geplant wird in UTC aus der Ortszeit der Erinnerung (gleicher Zeitpunkt, keine Zeitzonen-Datenbank
/// nötig). Android plant ungenau (`inexactAllowWhileIdle`) – ohne Sonderrecht für exakte Wecker.
class LocalNotificationGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Erst fragen, wenn der Nutzer Erinnerungen einschaltet.
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
      )
      .then((_) {});

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (_ios case final ios?) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    // Vor Android 13 gibt es keine Abfrage (null) – dann ist es erlaubt.
    return await _android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<bool> hasPermission() async {
    await _init();
    if (_ios case final ios?) return (await ios.checkPermissions())?.isEnabled ?? false;
    return await _android?.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders, {required String channel}) async {
    await _init();
    await _plugin.cancelAll();
    final details = NotificationDetails(android: AndroidNotificationDetails('reminders', channel), iOS: const DarwinNotificationDetails());
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
      );
    }
  }
}
