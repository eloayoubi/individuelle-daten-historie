import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/di/lookup.dart';
import 'features/reminders/data/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await configureDependencies();
  // Erinnerungen nach dem Start und nach jeder Datenänderung neu planen.
  lookup<ReminderService>().start();
  runApp(const KostenkurveApp());
}
