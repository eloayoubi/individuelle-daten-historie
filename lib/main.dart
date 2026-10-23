import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/launch_splash.dart';
import 'core/di/injection.dart';
import 'core/di/lookup.dart';
import 'features/plus/data/plus_store.dart';
import 'features/reminders/data/reminder_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Kein Bild vor runApp: Ein leeres erstes Bild ließe iOS den Splash schon ausblenden, und die
  // Kachel verschwände kurz, bevor die Startanimation sie übernimmt.
  binding.deferFirstFrame();
  // Startanimation nebenher laden: Sie muss stehen, bevor das erste Bild den nativen Splash ablöst.
  final launch = LaunchSplash.load();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await configureDependencies();
  // Erinnerungen nach dem Start und nach jeder Datenänderung neu planen.
  lookup<ReminderService>().start();
  // Käufe und Verlängerungen, die abgeschlossen wurden, während die App zu war.
  lookup<PlusStore>().start();
  runApp(KostenkurveApp(launch: await launch));
  binding.allowFirstFrame();
}
