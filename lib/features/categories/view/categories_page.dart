import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/categories_cubit.dart';
import 'category_detail_page.dart';
import 'category_setup_page.dart';

/// Kategorien-Tab: alle Kategorien in meiner Reihenfolge, neue aus Vorlagen, „Bearbeiten“ zum
/// Umsortieren und unten die archivierten zum Wiederherstellen.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<CategoriesCubit>()..load(), child: const _CategoriesView());
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  void _onEvent(BuildContext context, CategoriesState state) {
    final event = state.event!;
    switch (event.kind) {
      case CategoriesEventKind.restored:
        AppToast.show(context, context.l10n.categoriesRestored(event.name ?? ''), icon: CupertinoIcons.arrow_counterclockwise);
      case CategoriesEventKind.failed:
        AppToast.show(context, context.l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesCubit, CategoriesState>(
      listenWhen: (previous, current) => current.event != null && current.event != previous.event,
      listener: _onEvent,
      builder: (context, state) => switch (state.status) {
        CategoriesStatus.loading => const Center(child: CupertinoActivityIndicator()),
        CategoriesStatus.failure => _Failure(onRetry: context.read<CategoriesCubit>().load),
        CategoriesStatus.ready => state.editing ? _Reorder(state: state) : _List(state: state),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final CategoriesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CategoriesCubit>();
    return AppHeader(
      title: l10n.tabCategories,
      actions: [
        if (state.active.length > 1 || state.editing)
          AppButton(label: state.editing ? l10n.actionDone : l10n.actionEdit, variant: AppButtonVariant.plain, expand: false, onPressed: cubit.toggleEditing),
        if (!state.editing)
          AppIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.categoriesAdd, filled: true, onPressed: () => CategorySetupPage.start(context)),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state});

  final CategoriesState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CategoriesCubit>();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: cubit.load),
        SliverToBoxAdapter(child: _Header(state: state)),
        if (state.active.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _Empty(onStart: () => CategorySetupPage.start(context)))
        else
          SliverToBoxAdapter(
            child: AppListGroup(
              children: [for (final category in state.active) _CategoryRow(category: category, onTap: () => CategoryDetailPage.open(context, category.id))],
            ),
          ),
        if (state.archived.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: l10n.categoriesArchived),
                AppListGroup(
                  children: [
                    for (final category in state.archived)
                      Opacity(
                        opacity: 0.7,
                        child: AppListRow(
                          leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
                          title: category.name,
                          chevron: false,
                          trailing: category.isOwner
                              ? AppButton(label: l10n.categoriesRestore, variant: AppButtonVariant.plain, expand: false, onPressed: () => cubit.restore(category))
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: Spacing.tabBarClearance)),
      ],
    );
  }
}

/// Bearbeiten: Kategorien einzeln als Karten, am Griff verschiebbar.
class _Reorder extends StatelessWidget {
  const _Reorder({required this.state});

  final CategoriesState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<CategoriesCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(state: state),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.m),
          child: AppText(context.l10n.categoriesReorderHint, style: (t) => t.footnote, color: c.textSecondary),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.tabBarClearance),
            buildDefaultDragHandles: false,
            itemCount: state.active.length,
            onReorderItem: cubit.reorder,
            proxyDecorator: (child, _, _) => child,
            itemBuilder: (context, i) {
              final category = state.active[i];
              return Padding(
                key: ValueKey(category.id),
                padding: const EdgeInsets.only(bottom: Spacing.s),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: AppListRow(
                    leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
                    title: category.name,
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xs),
                        child: Icon(CupertinoIcons.line_horizontal_3, color: c.textTertiary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    // Was drin ist, in den Worten des Nutzers – nicht wie viele Felder.
    final summary = category.trackers.isEmpty ? l10n.categoryTrackers(0) : category.trackers.map((t) => t.name).join(', ');
    return AppListRow(
      leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
      title: category.name,
      subtitleWidget: Wrap(
        spacing: Spacing.s,
        runSpacing: Spacing.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppText(summary, style: (t) => t.footnote, color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (category.isShared)
            AppChip(
              icon: CupertinoIcons.person_2_fill,
              label: l10n.homeSharedWith(context.memberNames(category.sharedWith)),
              background: c.accentSoft,
              foreground: c.accent,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxxl, 0, Spacing.xxxl, Spacing.tabBarClearance),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: Spacing.m,
        children: [
          AppIconTile(icon: CupertinoIcons.square_grid_2x2_fill, color: c.accent, size: 64),
          AppText(l10n.homeEmptyTitle, style: (t) => t.title3, align: TextAlign.center),
          AppText(l10n.homeEmptyBody, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
          const SizedBox(height: Spacing.s),
          AppButton(label: l10n.categoriesChooseTemplate, icon: CupertinoIcons.plus, expand: false, onPressed: onStart),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.xxxl, 0, Spacing.xxxl, Spacing.tabBarClearance),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.l,
          children: [
            Icon(CupertinoIcons.wifi_exclamationmark, size: 44, color: c.textTertiary),
            AppText(context.l10n.errorLoad, style: (t) => t.body, color: c.textSecondary, align: TextAlign.center),
            AppButton(label: context.l10n.actionRetry, variant: AppButtonVariant.tinted, expand: false, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
