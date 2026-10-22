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
    this.event,
  });

  final bool loaded;
  final bool show;
  final OnboardingStep step;

  /// Gewählte Vorlagen (Schlüssel).
  final Set<String> selected;
  final bool busy;
  final OnboardingEvent? event;

  OnboardingState copyWith({bool? loaded, bool? show, OnboardingStep? step, Set<String>? selected, bool? busy, OnboardingEvent? event}) => OnboardingState(
    loaded: loaded ?? this.loaded,
    show: show ?? this.show,
    step: step ?? this.step,
    selected: selected ?? this.selected,
    busy: busy ?? this.busy,
    event: event,
  );

  @override
  List<Object?> get props => [loaded, show, step, selected, busy, event];
}
