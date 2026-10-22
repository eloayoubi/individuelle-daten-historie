import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/reminder_service.dart';

part 'reminders_state.dart';

/// Erinnerungen an oder aus. Liegt über dem `MaterialApp`, weil Übersicht und Einstellungen
/// denselben Stand zeigen.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit(this._service) : super(const RemindersState());

  final ReminderService _service;

  Future<void> load() async {
    final enabled = await _service.isEnabled();
    final granted = !enabled || await _service.hasPermission();
    if (!isClosed) emit(RemindersState(loaded: true, enabled: enabled && granted, denied: !granted));
  }

  Future<void> setEnabled(bool on) async {
    if (on) {
      final granted = await _service.enable();
      if (!isClosed) emit(RemindersState(loaded: true, enabled: granted, denied: !granted));
    } else {
      await _service.disable();
      if (!isClosed) emit(const RemindersState(loaded: true));
    }
  }
}
