import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/category_detail_cubit.dart';
import '../cubit/field_editor_cubit.dart';
import 'field_editor_page.dart';
import 'widgets/category_sheets.dart';
import 'widgets/field_row.dart';

/// Aufbau eines Trackers, getrennt von seinen Daten: Name und Kostenzuordnung, Felder nach
/// „Werte mit Verlauf“ und „Details“, Feld hinzufügen, Tracker archivieren. Nur für owner und editor.
class TrackerSetupPage extends StatelessWidget {
  const TrackerSetupPage({super.key, required this.categoryId, required this.trackerId});

  final String categoryId;
  final String trackerId;

  static Future<void> open(BuildContext context, {required String categoryId, required String trackerId}) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => TrackerSetupPage(categoryId: categoryId, trackerId: trackerId),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => lookup<CategoryDetailCubit>(param1: categoryId)..load(),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<CategoryDetailCubit, CategoryDetailState>(
            listenWhen: (previous, current) => current.event != null && current.event != previous.event,
            listener: (context, state) {
              switch (state.event!.kind) {
                case CategoryDetailEventKind.trackerArchived:
                  AppToast.show(context, context.l10n.detailTrackerArchived, icon: CupertinoIcons.archivebox_fill);
                  Navigator.of(context).pop();
                case CategoryDetailEventKind.failed:
                  AppToast.show(context, context.l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
                case CategoryDetailEventKind.trackerAdded || CategoryDetailEventKind.archived:
                  break;
              }
            },
            builder: (context, state) {
              final category = state.category;
              final tracker = category?.trackers.where((t) => t.id == trackerId).firstOrNull;
              return switch ((state.status, category, tracker)) {
                (CategoryDetailStatus.ready, final Category category, final Tracker tracker) => _Content(
                  category: category,
                  tracker: tracker,
                  others: state.others,
                ),
                (CategoryDetailStatus.loading, _, _) => const Center(child: CupertinoActivityIndicator()),
                _ => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppHeader(title: '', onBack: () => Navigator.of(context).pop()),
                    Expanded(
                      child: Center(
                        child: AppText(
                          state.status == CategoryDetailStatus.failure ? context.l10n.errorLoad : context.l10n.detailMissing,
                          style: (t) => t.body,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.category, required this.tracker, required this.others});

  final Category category;
  final Tracker tracker;
  final List<Category> others;

  Future<void> _rename(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    if (await TrackerSheet.show(context, tracker: tracker, others: others) case TrackerRenamed(:final name, :final includedIn)) {
      await cubit.updateTracker(tracker, name: name, includedIn: includedIn);
    }
  }

  Future<void> _archive(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.trackerArchiveTitle(tracker.name),
      message: l10n.trackerArchiveBody,
      confirmLabel: l10n.actionArchive,
      destructive: true,
    );
    if (confirmed) await cubit.archiveTracker(tracker.id);
  }

  void _openField(BuildContext context, [FieldDefinition? field]) => FieldEditorPage.open(
    context,
    FieldEditorArgs(
      trackerId: tracker.id,
      tracker: tracker,
      field: field,
      hasValues: field != null && tracker.hasValues(field.id),
      sort: tracker.fields.length,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final withHistory = [
      for (final f in tracker.fields)
        if (!f.isDetail) f,
    ];
    final details = tracker.detailFields;
    final into = others.where((o) => o.id == tracker.includedIn).firstOrNull;
    Widget fields(List<FieldDefinition> list, String hint) => AppListGroup(
      footer: hint,
      children: [for (final field in list) FieldRow.of(field, swatch: category.swatch, onTap: () => _openField(context, field))],
    );
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
      children: [
        AppHeader(title: tracker.name, overline: l10n.trackerSetup, onBack: () => Navigator.of(context).pop()),
        AppListGroup(
          dividerIndent: Spacing.l,
          footer: into == null ? null : l10n.trackerIncludedNote(into.name),
          children: [
            AppListRow(
              title: l10n.trackerName,
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: AppText(tracker.name, style: (t) => t.body, color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onTap: () => _rename(context),
            ),
          ],
        ),
        if (tracker.fields.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.xxl, Spacing.xxl, 0),
            child: AppText(l10n.detailNoFields, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
          ),
        if (withHistory.isNotEmpty) ...[SectionHeader(title: l10n.trackerFieldsHistory), fields(withHistory, l10n.trackerFieldsHistoryHint)],
        if (details.isNotEmpty) ...[SectionHeader(title: l10n.detailsTitle), fields(details, l10n.trackerFieldsDetailsHint)],
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
          child: AppButton(label: l10n.detailAddField, icon: CupertinoIcons.plus, variant: AppButtonVariant.tinted, onPressed: () => _openField(context)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, 0),
          child: AppButton(label: l10n.trackerArchive, variant: AppButtonVariant.destructive, onPressed: () => _archive(context)),
        ),
      ],
    );
  }
}
