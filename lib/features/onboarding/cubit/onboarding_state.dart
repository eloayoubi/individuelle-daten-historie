part of 'onboarding_cubit.dart';

enum OnboardingStep { welcome, templates, reminders }

/// Anlegen ging nicht (z. B. offline). Bewusst nicht `const`.
class OnboardingEvent {
  OnboardingEvent();
}

class OnboardingState extends Equatable {
  const OnboardingState({
    this.loaded = false,
    this.show = false,
    this.step = OnboardingStep.welcome,
    this.selected = OnboardingCubit.suggested,
    this.busy = false,
    this.created = const {},
    this.event,
  });

  final bool loaded;
  final bool show;
  final OnboardingStep step;

  /// Gewählte Vorlagen (Schlüssel).
  final Set<String> selected;
  final bool busy;

  /// Schon angelegte Vorlagen – ein zweiter Versuch nach einem Fehler legt sie nicht noch einmal an.
  final Set<String> created;
  final OnboardingEvent? event;

  OnboardingState copyWith({bool? loaded, bool? show, OnboardingStep? step, Set<String>? selected, bool? busy, Set<String>? created, OnboardingEvent? event}) => OnboardingState(
    loaded: loaded ?? this.loaded,
    show: show ?? this.show,
    step: step ?? this.step,
    selected: selected ?? this.selected,
    busy: busy ?? this.busy,
    created: created ?? this.created,
    event: event,
  );

  @override
  List<Object?> get props => [loaded, show, step, selected, busy, created, event];
}
