import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/tracker_cubit.dart';
import '../data/tracker_history.dart';
import 'entry_form_page.dart';
import 'widgets/history_chart.dart';

/// Verlauf eines Trackers: Graph der letzten zwölf Monate (Kosten oder Verbrauch), Jahresvergleich
/// und Prognose, aktuelle Werte und alle Einträge zum Bearbeiten.
class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key, required this.args});

  final TrackerArgs args;

  static Future<void> open(BuildContext context, {required String categoryId, required String trackerId}) => Navigator.of(context).push(
    CupertinoPageRoute<void>(builder: (_) => TrackerPage(args: TrackerArgs(categoryId: categoryId, trackerId: trackerId))),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => lookup<TrackerCubit>(param1: args)..load(),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<TrackerCubit, TrackerState>(
            builder: (context, state) => switch ((state.status, state.category, state.tracker)) {
              (TrackerStatus.ready, final Category category, final Tracker tracker) => _Content(state: state, category: category, tracker: tracker),
              (TrackerStatus.loading, _, _) => const Center(child: CupertinoActivityIndicator()),
              _ => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(title: '', onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Center(
                      child: AppText(
                        state.status == TrackerStatus.failure ? context.l10n.errorLoad : context.l10n.detailMissing,
                        style: (t) => t.body,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.category, required this.tracker});

  /// Platz für Werte rechts in „Aktuelle Werte“ (längere werden gekürzt).
  static const _valueWidth = 190.0;

  final TrackerState state;
  final Category category;
  final Tracker tracker;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<TrackerCubit>();
    final history = state.history;
    final entries = state.entries;
    String format(double v) => history?.metric == HistoryMetric.consumption ? context.amount(v, history!.unit) : context.euros(v);
    void add() => EntryFormPage.open(context, category: category, tracker: tracker);
    final years = <int, List<Entry>>{};
    for (final e in entries) {
      years.putIfAbsent(e.date.year, () => []).add(e);
    }
    final now = DateTime.now().year;
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
      children: [
        AppHeader(
          title: tracker.name,
          overline: category.name,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            if (category.canEdit && tracker.fields.isNotEmpty)
              AppIconButton(icon: CupertinoIcons.plus, semanticLabel: l10n.trackerAddEntry, filled: true, onPressed: add),
          ],
        ),
        if (state.includedInName case final String into)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.m),
            child: Row(
              spacing: Spacing.s,
              children: [
                Icon(CupertinoIcons.arrow_turn_down_right, size: 16, color: c.textSecondary),
                Expanded(child: AppText(l10n.trackerIncludedNote(into), style: (t) => t.footnote, color: c.textSecondary)),
              ],
            ),
          ),
        if (history != null) ...[
          if (state.metrics.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.m),
              child: AppSegmented<HistoryMetric>(
                value: history.metric,
                segments: {for (final m in state.metrics) m: m == HistoryMetric.cost ? l10n.metricCost : l10n.metricConsumption},
                onChanged: cubit.selectMetric,
              ),
            ),
          Padding(
            padding: Spacing.screen,
            child: AppCard(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.m,
                children: [
                  AppText(l10n.trackerLast12.toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.textSecondary),
                  if (history.hasData)
                    HistoryChart(history: history, color: c.swatch(category.swatch), format: format)
                  else
                    AppText(l10n.trackerChartEmpty, style: (t) => t.subheadline, color: c.textSecondary),
                  Divider(height: Spacing.s, color: c.separator),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stat(label: l10n.trackerThisYear('$now'), value: format(history.thisYear)),
                      _Stat(label: l10n.trackerLastYear, value: history.lastYearToDate == null ? '–' : format(history.lastYearToDate!)),
                      _Stat(label: l10n.homeForecastTitle('${now + 1}'), value: format(history.forecastNextYear)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (state.currentValues.isNotEmpty) ...[
          SectionHeader(title: l10n.trackerCurrentValues),
          AppListGroup(
            dividerIndent: Spacing.l,
            children: [
              for (final v in state.currentValues)
                AppListRow(
                  title: v.field.name,
                  subtitle: context.joinParts([
                    l10n.trackerSince(context.shortDate(v.since)),
                    if (v.upcoming case final Object next) l10n.trackerUpcoming(context.shortDate(v.upcomingFrom!), context.fieldValue(v.field, next)),
                  ]),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _valueWidth),
                    child: AppText(context.fieldValue(v.field, v.value), style: (t) => t.numberM, maxLines: 1, align: TextAlign.end),
                  ),
                ),
            ],
          ),
        ],
        SectionHeader(title: l10n.trackerEntries),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.l, Spacing.xxl, 0),
            child: Column(
              spacing: Spacing.s,
              children: [
                AppText(l10n.trackerNoEntriesTitle, style: (t) => t.title3, align: TextAlign.center),
                AppText(l10n.trackerNoEntriesBody, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
                if (category.canEdit && tracker.fields.isNotEmpty) ...[
                  const SizedBox(height: Spacing.s),
                  AppButton(label: l10n.trackerAddEntry, icon: CupertinoIcons.plus, expand: false, onPressed: add),
                ],
              ],
            ),
          )
        else
          for (final MapEntry(key: year, value: list) in years.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.xs),
              child: AppText('$year', style: (t) => t.footnoteEmphasized, color: c.textSecondary),
            ),
            AppListGroup(
              dividerIndent: Spacing.l,
              children: [
                for (final e in list)
                  AppListRow(
                    title: context.shortWeekdayDate(e.date),
                    subtitle: context.joinParts([
                      if (e.meterChange) l10n.trackerMeterChanged,
                      for (final f in tracker.fields)
                        if (e.values[f.id] case final Object v) l10n.entryFieldValue(f.name, context.fieldValue(f, v)),
                      e.note,
                    ]),
                    onTap: category.canEdit ? () => EntryFormPage.open(context, category: category, tracker: tracker, entry: e) : null,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.s),
          ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          AppText(label, style: (t) => t.caption, color: context.colors.textSecondary, maxLines: 1),
          AppText(value, style: (t) => t.numberM, maxLines: 1),
        ],
      ),
    );
  }
}
