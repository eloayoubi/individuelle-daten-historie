import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../entries/data/tracker_history.dart';
import '../../entries/view/entry_form_page.dart';
import '../../entries/view/tracker_page.dart';
import '../../entries/view/widgets/tracker_details.dart';
import '../../sharing/view/share_page.dart';
import '../cubit/category_detail_cubit.dart';
import 'tracker_setup_page.dart';
import 'widgets/category_sheets.dart';

/// Eine Kategorie mit ihren Trackern – je Tracker seine Daten: Verlauf mit der Kennzahl des Jahres,
/// Wert eintragen und Details (Anbieter, Vertragsende). Der Aufbau (Felder) liegt eine Ebene tiefer
/// unter „Bearbeiten“. owner und editor bearbeiten, viewer lesen nur.
class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({super.key, required this.categoryId});

  final String categoryId;

  static Future<void> open(BuildContext context, String categoryId) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => CategoryDetailPage(categoryId: categoryId)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<CategoryDetailCubit>(param1: categoryId)..load(), child: const _DetailView());
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  void _onEvent(BuildContext context, CategoryDetailState state) {
    final l10n = context.l10n;
    switch (state.event!.kind) {
      case CategoryDetailEventKind.trackerAdded:
        AppToast.show(context, l10n.detailTrackerAdded);
      case CategoryDetailEventKind.trackerArchived:
        AppToast.show(context, l10n.detailTrackerArchived, icon: CupertinoIcons.archivebox_fill);
      case CategoryDetailEventKind.archived:
        AppToast.show(context, l10n.detailArchived(state.category?.name ?? ''), icon: CupertinoIcons.archivebox_fill);
        Navigator.of(context).pop();
      case CategoryDetailEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<CategoryDetailCubit, CategoryDetailState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, state) => switch ((state.status, state.category)) {
            (CategoryDetailStatus.ready, final Category category) => _Content(category: category, others: state.others, yearToDate: state.yearToDate),
            (CategoryDetailStatus.loading, _) => const Center(child: CupertinoActivityIndicator()),
            _ => _Missing(message: state.status == CategoryDetailStatus.failure ? context.l10n.errorLoad : context.l10n.detailMissing),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.category, this.others = const [], this.yearToDate = const {}});

  final Category category;
  final List<Category> others;
  final Map<String, YearToDate> yearToDate;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final result = await CategoryEditSheet.show(context, category);
    if (result != null) await cubit.updateAppearance(name: result.name, icon: result.icon, swatch: result.swatch);
  }

  Future<void> _addTracker(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    if (await TrackerSheet.show(context) case TrackerRenamed(:final name)) await cubit.addTracker(name);
  }

  Future<void> _archive(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.detailArchiveTitle(category.name),
      message: l10n.detailArchiveBody,
      confirmLabel: l10n.actionArchive,
      destructive: true,
    );
    if (confirmed) await cubit.archive();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final editable = category.canEdit;
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
      children: [
        AppHeader(
          title: category.name,
          overline: category.isShared ? l10n.homeSharedWith(category.sharedWith.map((m) => m.name).join(', ')) : null,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch), size: Sizes.iconTileLarge),
            AppIconButton(icon: CupertinoIcons.person_2_fill, semanticLabel: l10n.shareTitle, onPressed: () => SharePage.open(context, category.id)),
            if (editable) AppIconButton(icon: CupertinoIcons.pencil, semanticLabel: l10n.detailEditCategory, onPressed: () => _edit(context)),
          ],
        ),
        if (!editable)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.s),
            child: AppText(
              category.sharedBy == null ? l10n.detailReadOnlyUnknown : l10n.detailReadOnly(category.sharedBy!.name),
              style: (t) => t.footnote,
              color: c.textSecondary,
            ),
          ),
        if (category.trackers.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.xxxl, Spacing.xxl, Spacing.l),
            child: Column(
              spacing: Spacing.s,
              children: [
                AppText(l10n.detailNoTrackersTitle, style: (t) => t.title3, align: TextAlign.center),
                AppText(l10n.detailNoTrackersBody, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
              ],
            ),
          ),
        for (final tracker in category.trackers) ...[
          SectionHeader(
            title: tracker.name,
            action: editable ? l10n.actionEdit : null,
            onAction: () => TrackerSetupPage.open(context, categoryId: category.id, trackerId: tracker.id),
          ),
          _TrackerGroup(
            category: category,
            tracker: tracker,
            yearToDate: yearToDate[tracker.id],
            includedIn: others.where((o) => o.id == tracker.includedIn).firstOrNull,
          ),
          if (tracker.detailFields.isNotEmpty) ...[
            const SizedBox(height: Spacing.m),
            TrackerDetailsGroup(
              tracker: tracker,
              onSave: editable ? (field, value) => context.read<CategoryDetailCubit>().saveDetail(tracker, field, value) : null,
            ),
          ],
        ],
        if (editable)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
            child: AppButton(label: l10n.detailAddTracker, icon: CupertinoIcons.plus, variant: AppButtonVariant.tinted, onPressed: () => _addTracker(context)),
          ),
        if (category.isOwner && !category.isArchived)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, 0),
            child: AppButton(label: l10n.detailArchive, variant: AppButtonVariant.destructive, onPressed: () => _archive(context)),
          ),
      ],
    );
  }
}

/// Daten eines Trackers: Verlauf (mit Kosten oder Verbrauch des Jahres) und – je nach Rechten und
/// Feldern – Wert eintragen oder Felder festlegen.
class _TrackerGroup extends StatelessWidget {
  const _TrackerGroup({required this.category, required this.tracker, this.yearToDate, this.includedIn});

  /// Darunter zeigt die Zeile keine Kennzahl (noch nichts angefallen).
  static const _minValue = 0.5;

  final Category category;
  final Tracker tracker;
  final YearToDate? yearToDate;
  final Category? includedIn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final swatch = c.swatch(category.swatch);
    final figure = switch (yearToDate) {
      final YearToDate y when y.value.abs() >= _minValue => y.metric == HistoryMetric.cost ? context.euros(y.value) : context.amount(y.value, y.unit),
      _ => null,
    };
    return AppListGroup(
      children: [
        AppListRow(
          leading: AppIconTile(icon: CupertinoIcons.chart_bar_fill, color: swatch),
          title: l10n.trackerHistory,
          subtitle: context.joinParts([l10n.categoryEntries(tracker.records.length), if (includedIn != null) l10n.trackerIncludedNote(includedIn!.name)]),
          trailing: figure == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    AppText(figure, style: (t) => t.numberM),
                    AppText(l10n.trackerThisYear('${DateTime.now().year}'), style: (t) => t.caption, color: c.textSecondary),
                  ],
                ),
          onTap: () => TrackerPage.open(context, categoryId: category.id, trackerId: tracker.id),
        ),
        if (category.canEdit && tracker.entryFields.isNotEmpty)
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.plus, color: c.accent),
            title: l10n.trackerAddEntry,
            chevron: false,
            onTap: () => EntryFormPage.open(context, category: category, tracker: tracker),
          )
        else if (category.canEdit && tracker.fields.isEmpty)
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.slider_horizontal_3, color: c.accent),
            title: l10n.trackerSetUpFields,
            onTap: () => TrackerSetupPage.open(context, categoryId: category.id, trackerId: tracker.id),
          ),
      ],
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(title: '', onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Padding(
              padding: Spacing.screen,
              child: AppText(message, style: (t) => t.body, color: context.colors.textSecondary, align: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}
