import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
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
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) => current.event != null && current.event != previous.event,
      listener: (context, state) => AppToast.show(
        context,
        switch (state.event!.kind) {
          HomeEventKind.captureSoon => context.l10n.quickAddSoon,
          HomeEventKind.detailsSoon => context.l10n.categoryDetailsSoon,
        },
        icon: CupertinoIcons.hammer_fill,
      ),
      builder: (context, state) => switch ((state.status, state.overview)) {
        (_, final HomeOverview overview) => _Content(overview: overview),
        (HomeStatus.failure, null) => _Failure(onRetry: context.read<HomeCubit>().load),
        _ => const Center(child: CupertinoActivityIndicator()),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final HomeOverview overview;

  Future<void> _quickAdd(BuildContext context) async {
    final cubit = context.read<HomeCubit>();
    final trackerId = await QuickAddSheet.show(context, [for (final s in overview.categories) s.category]);
    if (trackerId != null) cubit.capture(trackerId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HomeCubit>();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: cubit.load),
        SliverToBoxAdapter(
          child: AppHeader(
            title: l10n.tabOverview,
            overline: context.weekdayDate(overview.today),
            actions: [
              if (!overview.isEmpty)
                AppIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.homeQuickAdd, filled: true, onPressed: () => _quickAdd(context)),
            ],
          ),
        ),
        if (overview.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _Empty())
        else
          SliverList.list(
            children: [
              ForecastCard(overview: overview),
              const SizedBox(height: Spacing.m),
              YearToDateCard(overview: overview),
              SectionHeader(title: l10n.homeCategories, action: l10n.homeSeeAll, onAction: () => context.read<ShellCubit>().select(ShellTab.categories)),
              CategoryRows(summaries: overview.categories, onTap: (category) => cubit.openCategory(category.id)),
              if (overview.reminders.isNotEmpty) ...[
                SectionHeader(title: l10n.homeNext),
                ReminderRows(reminders: overview.reminders, onTap: (r) => cubit.capture(r.trackerId)),
              ],
              const SizedBox(height: Spacing.tabBarClearance),
            ],
          ),
      ],
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
