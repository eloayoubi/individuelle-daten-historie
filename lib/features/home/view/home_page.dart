import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/view/category_detail_page.dart';
import '../../categories/view/category_setup_page.dart';
import '../../entries/view/entry_form_page.dart';
import '../../entries/view/tracker_page.dart';
import '../../reminders/cubit/reminders_cubit.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/home_cubit.dart';
import '../data/home_overview.dart';
import 'widgets/category_rows.dart';
import 'widgets/forecast_card.dart';
import 'widgets/quick_add_sheet.dart';
import 'widgets/reminder_rows.dart';
import 'widgets/year_to_date_card.dart';

/// Übersicht: Prognose fürs nächste Jahr, Kosten seit Januar, Kategorien und was ansteht.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<HomeCubit>()..load(), child: const _HomeView());
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => switch ((state.status, state.overview)) {
        (_, final HomeOverview overview) => _Content(overview: overview, sync: state.sync),
        (HomeStatus.failure, null) => _Failure(onRetry: context.read<HomeCubit>().load),
        _ => const Center(child: CupertinoActivityIndicator()),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview, required this.sync});

  final HomeOverview overview;
  final SyncState sync;

  /// Schnellerfassung: Tracker wählen, dann direkt ins Formular.
  Future<void> _quickAdd(BuildContext context) async {
    final editable = [for (final s in overview.categories) if (s.category.canEdit) s.category];
    final trackerId = await QuickAddSheet.show(context, editable);
    if (trackerId != null && context.mounted) _openForm(context, trackerId);
  }

  void _openForm(BuildContext context, String trackerId) {
    for (final s in overview.categories) {
      for (final tracker in s.category.trackers) {
        if (tracker.id == trackerId) {
          EntryFormPage.open(context, category: s.category, tracker: tracker);
          return;
        }
      }
    }
  }

  /// Ablesen öffnet das Formular, ein Stichtag den Verlauf des Trackers.
  void _openReminder(BuildContext context, Reminder r) {
    if (r.kind == ReminderKind.readMeter && r.category.canEdit) {
      _openForm(context, r.trackerId);
    } else {
      TrackerPage.open(context, categoryId: r.category.id, trackerId: r.trackerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HomeCubit>();
    final canAdd = overview.categories.any((s) => s.category.canEdit && s.category.trackers.any((t) => t.fields.isNotEmpty));
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: cubit.load),
        SliverToBoxAdapter(
          child: AppHeader(
            title: l10n.tabOverview,
            overline: context.weekdayDate(overview.today),
            actions: [
              if (canAdd) AppIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.homeQuickAdd, filled: true, onPressed: () => _quickAdd(context)),
            ],
          ),
        ),
        if (sync.pending > 0 || sync.rejected > 0) SliverToBoxAdapter(child: _SyncBanner(sync: sync, onDismiss: cubit.acknowledgeRejected)),
        if (overview.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _Empty())
        else
          SliverList.list(
            children: [
              ForecastCard(overview: overview),
              const SizedBox(height: Spacing.m),
              YearToDateCard(overview: overview),
              SectionHeader(title: l10n.homeCategories, action: l10n.homeSeeAll, onAction: () => context.read<ShellCubit>().select(ShellTab.categories)),
              CategoryRows(summaries: overview.categories, onTap: (category) => CategoryDetailPage.open(context, category.id)),
              if (overview.reminders.isNotEmpty) ...[
                SectionHeader(title: l10n.homeNext),
                ReminderRows(reminders: overview.reminders, onTap: (r) => _openReminder(context, r)),
                const _EnableReminders(),
              ],
              const SizedBox(height: Spacing.tabBarClearance),
            ],
          ),
      ],
    );
  }
}

/// Offline erfasste Einträge: warten noch oder wurden abgelehnt (antippen blendet aus).
class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.sync, required this.onDismiss});

  final SyncState sync;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.m),
      child: AppListGroup(
        children: [
          if (sync.pending > 0)
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.cloud_upload_fill, color: c.warning),
              title: l10n.homeSyncPending(sync.pending),
              subtitle: l10n.homeSyncPendingHint,
            ),
          if (sync.rejected > 0)
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.exclamationmark_triangle_fill, color: c.danger),
              title: l10n.homeSyncRejected(sync.rejected),
              subtitle: l10n.homeSyncRejectedHint,
              chevron: false,
              onTap: onDismiss,
            ),
        ],
      ),
    );
  }
}

/// Unter „Als Nächstes“: Erinnerungen einschalten, solange sie aus sind.
class _EnableReminders extends StatelessWidget {
  const _EnableReminders();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) => !state.loaded || state.enabled
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: Spacing.m),
              child: AppListGroup(
                children: [
                  AppListRow(
                    leading: AppIconTile(icon: CupertinoIcons.bell_fill, color: context.colors.accent),
                    title: l10n.remindersEnable,
                    subtitle: state.denied ? l10n.settingsRemindersDenied : l10n.remindersEnableHint,
                    chevron: false,
                    onTap: () => context.read<RemindersCubit>().setEnabled(true),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxxl, 0, Spacing.xxxl, Spacing.tabBarClearance),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: Spacing.m,
        children: [
          AppIconTile(icon: CupertinoIcons.chart_bar_alt_fill, color: c.accent, size: 64),
          AppText(context.l10n.homeEmptyTitle, style: (t) => t.title3, align: TextAlign.center),
          AppText(context.l10n.homeEmptyBody, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
          const SizedBox(height: Spacing.s),
          AppButton(label: context.l10n.categoriesChooseTemplate, icon: CupertinoIcons.plus, expand: false, onPressed: () => CategorySetupPage.start(context)),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxxl, 0, Spacing.xxxl, Spacing.tabBarClearance),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: Spacing.l,
        children: [
          Icon(CupertinoIcons.wifi_exclamationmark, size: 44, color: c.textTertiary),
          AppText(context.l10n.errorLoad, style: (t) => t.body, color: c.textSecondary, align: TextAlign.center),
          AppButton(label: context.l10n.actionRetry, variant: AppButtonVariant.tinted, expand: false, onPressed: onRetry),
        ],
      ),
    );
  }
}
