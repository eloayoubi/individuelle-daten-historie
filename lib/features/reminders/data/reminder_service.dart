import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:intl/date_symbol_data_local.dart';

import '../../../core/utils/json_store.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../categories/data/categories_repository.dart';
import 'notification_gateway.dart';
import 'reminder_planner.dart';

/// Hält die geplanten Erinnerungen aktuell: nach dem Start und nach jeder Änderung an den Daten
/// (gebündelt), solange der Nutzer sie eingeschaltet hat. Die Wahl liegt auf dem Gerät.
class ReminderService {
  ReminderService(this._repository, this._gateway, this._store, {AppLocalizations Function()? texts, DateTime Function()? now, this.debounce = const Duration(seconds: 2)})
    : _texts = texts ?? _systemTexts,
      _now = now ?? DateTime.now;

  final CategoriesRepository _repository;
  final NotificationGateway _gateway;
  final JsonStore _store;
  final AppLocalizations Function() _texts;
  final DateTime Function() _now;
  final Duration debounce;

  bool? _enabled;
  StreamSubscription<void>? _subscription;
  Timer? _pending;

  Future<bool> isEnabled() async => _enabled ??= switch (await _store.read()) {
    {'enabled': true} => true,
    _ => false,
  };

  Future<bool> hasPermission() => _gateway.hasPermission();

  /// Fragt nach dem Recht; nur wenn erteilt, sind Erinnerungen an.
  Future<bool> enable() async {
    if (!await _gateway.requestPermission()) return false;
    _enabled = true;
    await _store.write({'enabled': true});
    await reschedule();
    return true;
  }

  Future<void> disable() async {
    _enabled = false;
    await _store.write({'enabled': false});
    await _gateway.replaceAll(const [], channel: _texts().notifyChannel);
  }

  /// Einmal in `main()`: plant sofort und nach jeder Änderung neu.
  void start() {
    _subscription ??= _repository.changes.listen((_) {
      _pending?.cancel();
      _pending = Timer(debounce, () => unawaited(reschedule()));
    });
    unawaited(reschedule());
  }

  Future<void> reschedule() async {
    if (!await isEnabled()) return;
    try {
      final texts = _texts();
      // Läuft außerhalb der Oberfläche: Datumsformate der Sprache selbst laden.
      await initializeDateFormatting(texts.localeName);
      final categories = await _repository.loadCategories();
      await _gateway.replaceAll(ReminderPlanner.plan(categories, _now(), texts), channel: texts.notifyChannel);
    } catch (_) {
      // Ohne Daten (offline beim ersten Start) bleibt der letzte Plan stehen.
    }
  }

  static AppLocalizations _systemTexts() {
    final supported = {for (final l in AppLocalizations.supportedLocales) l.languageCode};
    final locale = PlatformDispatcher.instance.locales.where((l) => supported.contains(l.languageCode)).firstOrNull;
    return lookupAppLocalizations(locale ?? AppLocalizations.supportedLocales.first);
  }
}
