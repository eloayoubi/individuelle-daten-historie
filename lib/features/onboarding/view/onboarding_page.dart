import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../categories/data/category_templates.dart';
import '../../reminders/cubit/reminders_cubit.dart';
import '../cubit/onboarding_cubit.dart';

/// Vor der App, solange es keine Kategorien gibt: Willkommen, Vorlagen, Erinnerungen.
/// Davor entscheidet [OnboardingGate], ob es nötig ist.
class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => lookup<OnboardingCubit>()..load(),
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        buildWhen: (previous, current) => previous.loaded != current.loaded || previous.show != current.show,
        builder: (context, s) => AnimatedSwitcher(
          duration: Motion.normal,
          child: switch (s) {
            OnboardingState(loaded: false) => ColoredBox(key: const ValueKey('wait'), color: context.colors.background, child: const SizedBox.expand()),
            OnboardingState(show: true) => const OnboardingPage(key: ValueKey('onboarding')),
            _ => KeyedSubtree(key: const ValueKey('app'), child: child),
          },
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: BlocConsumer<OnboardingCubit, OnboardingState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: (context, _) => AppToast.show(context, context.l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill),
          builder: (context, s) => AnimatedSwitcher(
            duration: Motion.normal,
            child: switch (s.step) {
              OnboardingStep.welcome => const _Welcome(key: ValueKey(OnboardingStep.welcome)),
              OnboardingStep.templates => _Templates(key: const ValueKey(OnboardingStep.templates), state: s),
              OnboardingStep.reminders => const _Reminders(key: ValueKey(OnboardingStep.reminders)),
            },
          ),
        ),
      ),
    );
  }
}

/// Seite mit Inhalt oben und Knöpfen unten.
class _Step extends StatelessWidget {
  const _Step({required this.children, required this.actions});

  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxxl, Spacing.l, Spacing.l), children: children),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, Spacing.l),
          child: Column(spacing: Spacing.s, children: actions),
        ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    Widget point(IconData icon, Color color, String title, String body) => AppListRow(leading: AppIconTile(icon: icon, color: color), title: title, subtitle: body, chevron: false);
    return _Step(
      actions: [AppButton(label: l10n.onboardingStart, onPressed: context.read<OnboardingCubit>().next)],
      children: [
        Center(child: AppIconTile(icon: CupertinoIcons.chart_bar_alt_fill, color: c.accent, size: 72)),
        const SizedBox(height: Spacing.xl),
        AppText(l10n.onboardingWelcomeTitle, style: (t) => t.largeTitle, align: TextAlign.center),
        const SizedBox(height: Spacing.s),
        AppText(l10n.onboardingWelcomeBody, style: (t) => t.body, color: c.textSecondary, align: TextAlign.center),
        const SizedBox(height: Spacing.xxl),
        AppListGroup(
          children: [
            point(CupertinoIcons.gauge, c.accent, l10n.onboardingPointTrack, l10n.onboardingPointTrackBody),
            point(CupertinoIcons.chart_bar_alt_fill, c.success, l10n.onboardingPointForecast, l10n.onboardingPointForecastBody),
            point(CupertinoIcons.person_2_fill, c.warning, l10n.onboardingPointShare, l10n.onboardingPointShareBody),
          ],
        ),
      ],
    );
  }
}

class _Templates extends StatelessWidget {
  const _Templates({super.key, required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<OnboardingCubit>();
    final templates = CategoryTemplates.all(l10n);
    return _Step(
      actions: [
        AppButton(
          label: state.selected.isEmpty ? l10n.onboardingSkip : l10n.onboardingCreate(state.selected.length),
          onPressed: state.busy ? null : () => cubit.create(templates),
        ),
      ],
      children: [
        AppText(l10n.onboardingTemplatesTitle, style: (t) => t.title1),
        const SizedBox(height: Spacing.s),
        AppText(l10n.onboardingTemplatesBody, style: (t) => t.subheadline, color: c.textSecondary),
        const SizedBox(height: Spacing.xl),
        AppListGroup(
          children: [
            for (final t in templates)
              AppListRow(
                leading: AppIconTile(icon: t.icon.data, color: c.swatch(t.swatch)),
                title: t.name,
                subtitle: t.description,
                chevron: false,
                trailing: Icon(
                  state.selected.contains(t.key) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  color: state.selected.contains(t.key) ? c.accent : c.textTertiary,
                  semanticLabel: state.selected.contains(t.key) ? l10n.onboardingSelected : null,
                ),
                onTap: () => cubit.toggle(t.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<OnboardingCubit>();
    return _Step(
      actions: [
        AppButton(
          label: l10n.onboardingRemindersAllow,
          icon: CupertinoIcons.bell_fill,
          onPressed: () async {
            await context.read<RemindersCubit>().setEnabled(true);
            await cubit.finish();
          },
        ),
        AppButton(label: l10n.onboardingLater, variant: AppButtonVariant.plain, onPressed: cubit.finish),
      ],
      children: [
        Center(child: AppIconTile(icon: CupertinoIcons.bell_fill, color: c.danger, size: 72)),
        const SizedBox(height: Spacing.xl),
        AppText(l10n.onboardingRemindersTitle, style: (t) => t.title1, align: TextAlign.center),
        const SizedBox(height: Spacing.s),
        AppText(l10n.onboardingRemindersBody, style: (t) => t.body, color: c.textSecondary, align: TextAlign.center),
      ],
    );
  }
}
