part of 'reminders_cubit.dart';

class RemindersState extends Equatable {
  const RemindersState({this.loaded = false, this.enabled = false, this.denied = false});

  final bool loaded;
  final bool enabled;

  /// Eingeschaltet gewollt, aber das System erlaubt keine Benachrichtigungen.
  final bool denied;

  @override
  List<Object?> get props => [loaded, enabled, denied];
}
