import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/view/category_detail_page.dart';
import '../../categories/view/category_setup_page.dart';
import '../../entries/view/entry_form_page.dart';
import '../../entries/view/tracker_page.dart';
import '../../reminders/cubit/reminders_cubit.dart';
import '../cubit/home_cubit.dart';
import '../data/home_overview.dart';
import 'widgets/category_rows.dart';
import 'widgets/forecast_card.dart';
import 'widgets/home_categories_sheet.dart';
import 'widgets/quick_add_sheet.dart';
import 'widgets/reminder_rows.dart';
import 'widgets/start_card.dart';
import 'widgets/year_to_date_card.dart';

/// Übersicht: Prognose fürs nächste Jahr (ohne Einträge: erste Schritte), Kosten seit Januar, Kategorien und was ansteht.
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
        (_, final HomeOverview overview) => _Content(overview: overview, sync: state.sync, shown: state.shown, reordering: state.reordering),
        (HomeStatus.failure, null) => _Failure(onRetry: context.read<HomeCubit>().load),
        _ => const Center(child: CupertinoActivityIndicator()),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview, required this.sync, required this.shown, required this.reordering});

  final HomeOverview overview;
  final SyncState sync;

  /// Gewählte Kategorien unter „Kategorien“; leer: nur „Kategorie hinzufügen“.
  final List<CategorySummary> shown;
  final bool reordering;

  /// Kategorien der Übersicht wählen – oder eine neue anlegen.
  Future<void> _pickCategories(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final choice = await HomeCategoriesSheet.show(
      context,
      categories: [for (final s in overview.categories) s.category],
      selected: [for (final s in shown) s.category.id],
    );
    if (!context.mounted) return;
    switch (choice) {
      case HomeCategoriesPicked(:final ids):
        await cubit.setPinned(ids);
      case HomeCategoriesCreate():
        await CategorySetupPage.start(context);
      case null:
    }
  }

  /// Schnellerfassung: Tracker wählen, dann direkt ins Formular – oder eine neue Kategorie anlegen.
  Future<void> _quickAdd(BuildContext context) async {
    final editable = [for (final s in overview.categories) if (s.category.canEdit) s.category];
    final choice = await QuickAddSheet.show(context, editable);
    if (!context.mounted) return;
    switch (choice) {
      case QuickAddTracker(:final trackerId):
        _openForm(context, trackerId);
      case QuickAddCategory():
        await CategorySetupPage.start(context);
      case null:
    }
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
    final canAdd = overview.categories.any((s) => s.category.canEdit && s.category.trackers.any((t) => t.entryFields.isNotEmpty));
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
        if (sync.pending > 0 || sync.rejected > 0 || sync.held > 0)
          SliverToBoxAdapter(child: _SyncBanner(sync: sync, onDismiss: cubit.acknowledgeRejected, onDiscard: cubit.discardHeld)),
        if (overview.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _Empty())
        else
          SliverList.list(
            children: [
              // Noch kein Eintrag: Schritte zum Start statt leerer Kurve und 0 €.
              if (overview.trackedSince == null)
                StartCard(year: overview.year, onAdd: canAdd ? () => _quickAdd(context) : null)
              else ...[
                ForecastCard(overview: overview),
                const SizedBox(height: Spacing.m),
                YearToDateCard(overview: overview),
              ],
              SectionHeader(
                title: l10n.homeCategories,
                action: shown.isEmpty ? null : (reordering ? l10n.actionDone : l10n.actionEdit),
                onAction: reordering ? () => cubit.setReordering(false) : () => _pickCategories(context),
              ),
              if (shown.isEmpty)
                AppListGroup(
                  children: [
                    AppListRow(
                      leading: AppIconTile(icon: CupertinoIcons.plus, color: context.colors.accent),
                      title: l10n.categoriesAdd,
                      subtitle: l10n.homeCategoriesAddHint,
                      onTap: () => _pickCategories(context),
                    ),
                  ],
                )
              else
                CategoryRows(
                  summaries: shown,
                  reordering: reordering,
                  onTap: (category) => CategoryDetailPage.open(context, category.id),
                  onReorderStart: () => cubit.setReordering(true),
                  onReorder: cubit.reorder,
                ),
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
  const _SyncBanner({required this.sync, required this.onDismiss, required this.onDiscard});

  final SyncState sync;
  final VoidCallback onDismiss;
  final Future<void> Function() onDiscard;

  Future<void> _discard(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.homeSyncDiscardTitle(sync.held),
      message: l10n.homeSyncDiscardBody,
      confirmLabel: l10n.homeSyncDiscard,
      destructive: true,
    );
    if (confirmed) await onDiscard();
  }

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
          if (sync.held > 0)
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.lock_fill, color: c.warning),
              title: l10n.homeSyncHeld(sync.held),
              subtitle: l10n.homeSyncHeldHint,
              trailing: AppText(l10n.homeSyncDiscard, style: (t) => t.body, color: c.danger),
              chevron: false,
              onTap: () => _discard(context),
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
                    // Abgelehnt: iOS fragt nicht noch einmal – dann direkt in die Systemeinstellungen der App.
                    chevron: state.denied,
                    onTap: () => state.denied ? launchUrl(Uri.parse('app-settings:')) : context.read<RemindersCubit>().setEnabled(true),
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
