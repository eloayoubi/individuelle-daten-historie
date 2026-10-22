import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../core/utils/cost_engine.dart';
import '../cubit/insights_cubit.dart';
import '../data/insights.dart';
import 'what_if_sheet.dart';
import 'widgets/stacked_months_chart.dart';

/// Auswertung: Kosten des Jahres je Monat und Kategorie, Jahresvergleich, Verbrauch der Zähler,
/// Prognose fürs nächste Jahr mit Spanne und Erklärung, Abschlags-Check.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => lookup<InsightsCubit>()..load(),
      child: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) => switch ((state.status, state.insights)) {
          (_, final Insights insights) => _Content(state: state, insights: insights),
          (InsightsStatus.failure, null) => Center(
            child: AppButton(label: context.l10n.actionRetry, variant: AppButtonVariant.tinted, expand: false, onPressed: context.read<InsightsCubit>().load),
          ),
          _ => const Center(child: CupertinoActivityIndicator()),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.insights});

  final InsightsState state;
  final Insights insights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<InsightsCubit>();
    final i = insights;
    final change = context.change(i.change);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: cubit.load),
        SliverToBoxAdapter(child: AppHeader(title: l10n.tabInsights)),
        if (state.years.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.m),
              child: AppSegmented<int>(value: i.year, segments: {for (final y in state.years) y: '$y'}, onChanged: cubit.selectYear),
            ),
          ),
        if (i.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xxxl, 0, Spacing.xxxl, Spacing.tabBarClearance),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: Spacing.m,
                children: [
                  AppIconTile(icon: CupertinoIcons.chart_bar_alt_fill, color: c.accent, size: 64),
                  AppText(l10n.homeEmptyTitle, style: (t) => t.title3, align: TextAlign.center),
                  AppText(l10n.homeEmptyBody, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
                ],
              ),
            ),
          )
        else
          SliverList.list(
            children: [
              Padding(
                padding: Spacing.screen,
                child: AppCard(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.xs,
                    children: [
                      AppText(l10n.insightsCosts('${i.year}').toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.textSecondary),
                      AppText(context.euros(i.total), style: (t) => t.numberL),
                      AppText(
                        context.joinParts([
                          if (i.isCurrentYear) l10n.insightsProjected,
                          if (change != null) l10n.homeForecastDelta(change, '${i.year - 1}'),
                        ]),
                        style: (t) => t.footnote,
                        color: c.textSecondary,
                      ),
                      const SizedBox(height: Spacing.m),
                      StackedMonthsChart(insights: i),
                    ],
                  ),
                ),
              ),
              if (i.forecast case final double forecast) _Forecast(insights: i, forecast: forecast),
              SectionHeader(title: l10n.insightsComparison('${i.year}', '${i.year - 1}')),
              AppListGroup(children: [for (final row in i.comparisons) _ComparisonRow(row: row, year: i.year)]),
              if (i.consumption.isNotEmpty) ...[
                SectionHeader(title: l10n.metricConsumption),
                AppListGroup(
                  footer: i.isCurrentYear ? l10n.insightsConsumptionHint : null,
                  children: [for (final row in i.consumption) _ConsumptionRow(row: row, year: i.year)],
                ),
              ],
              if (i.instalments.isNotEmpty) ...[
                SectionHeader(title: l10n.insightsInstalments),
                AppListGroup(
                  footer: l10n.insightsInstalmentFooter,
                  children: [for (final check in i.instalments) _InstalmentRow(check: check, year: i.year)],
                ),
              ],
              if (i.included.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.l, Spacing.xl, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.xs,
                    children: [
                      for (final note in i.included)
                        AppText(l10n.insightsIncluded(note.tracker.name, context.euros(note.cost), note.into.name), style: (t) => t.footnote, color: c.textSecondary),
                    ],
                  ),
                ),
              const SizedBox(height: Spacing.tabBarClearance),
            ],
          ),
      ],
    );
  }
}

/// Prognose fürs nächste Jahr: Betrag mit Spanne, woraus sie besteht, eingerechnete Trends.
class _Forecast extends StatelessWidget {
  const _Forecast({required this.insights, required this.forecast});

  final Insights insights;
  final double forecast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final i = insights;
    final CostParts parts = i.forecastParts;
    Widget part(String label, double value) => Row(
      children: [
        Expanded(child: AppText(label, style: (t) => t.subheadline, color: c.onSpotlightSecondary)),
        AppText(context.euros(value), style: (t) => t.numberM, color: c.onSpotlight),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeForecastTitle('${i.year + 1}')),
        Padding(
          padding: Spacing.screen,
          child: AppCard(
            color: c.spotlight,
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.s,
              children: [
                AppText(context.euros(forecast), style: (t) => t.numberXL, color: c.onSpotlight),
                if (i.forecastRange > 0.5)
                  AppText(
                    l10n.forecastRange(context.euros(forecast - i.forecastRange), context.euros(forecast + i.forecastRange)),
                    style: (t) => t.subheadlineEmphasized,
                    color: c.spotlightAccent,
                  ),
                Divider(color: c.spotlightLine, height: Spacing.l),
                if (parts.meter.abs() > 0.5) part(l10n.insightsPartMeter, parts.meter),
                if (parts.fixed.abs() > 0.5) part(l10n.insightsPartFixed, parts.fixed),
                if (parts.oneOff.abs() > 0.5) part(l10n.insightsPartOneOff, parts.oneOff),
                for (final trend in i.trends)
                  AppText(l10n.insightsTrend(trend.tracker.name, context.change(trend.trend - 1) ?? ''), style: (t) => t.footnote, color: c.onSpotlightSecondary),
                const SizedBox(height: Spacing.xs),
                AppText(l10n.insightsForecastExplain, style: (t) => t.footnote, color: c.onSpotlightSecondary),
              ],
            ),
          ),
        ),
        if (i.categoryForecasts.isNotEmpty) ...[
          const SizedBox(height: Spacing.m),
          AppListGroup(
            children: [
              for (final f in i.categoryForecasts)
                AppListRow(
                  leading: AppIconTile(icon: f.category.icon.data, color: c.swatch(f.category.swatch)),
                  title: f.category.name,
                  subtitle: f.range > 0.5 ? l10n.insightsRangeOnly(context.euros(f.range)) : null,
                  trailing: AppText(context.euros(f.total), style: (t) => t.numberM),
                ),
            ],
          ),
          const SizedBox(height: Spacing.m),
          AppListGroup(
            children: [
              AppListRow(
                leading: AppIconTile(icon: CupertinoIcons.wand_stars, color: c.accent),
                title: l10n.whatIfTitle,
                subtitle: l10n.whatIfRowHint,
                onTap: () => WhatIfSheet.show(context, categories: [for (final f in i.categoryForecasts) f.category], today: i.today),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.row, required this.year});

  final YearComparison row;
  final int year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppListRow(
      leading: AppIconTile(icon: row.category.icon.data, color: c.swatch(row.category.swatch)),
      title: row.category.name,
      subtitle: context.l10n.insightsPrevious('${year - 1}', context.euros(row.previous)),
      trailing: _ValueWithChange(value: context.euros(row.total), change: row.change, risingIsBad: true),
    );
  }
}

class _ConsumptionRow extends StatelessWidget {
  const _ConsumptionRow({required this.row, required this.year});

  final ConsumptionComparison row;
  final int year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppListRow(
      leading: AppIconTile(icon: CupertinoIcons.speedometer, color: c.swatch(row.category.swatch)),
      title: row.tracker.name,
      subtitle: context.joinParts([row.category.name, context.l10n.insightsPrevious('${year - 1}', context.amount(row.previous, row.unit))]),
      trailing: _ValueWithChange(value: context.amount(row.value, row.unit), change: row.change, risingIsBad: true),
    );
  }
}

class _InstalmentRow extends StatelessWidget {
  const _InstalmentRow({required this.check, required this.year});

  final InstalmentCheck check;
  final int year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final credit = check.balance >= 0;
    // Weicht der Abschlag um mehr als 5 % ab, lohnt ein Vorschlag.
    final suggest = check.cost > 0 && (check.balance.abs() / check.cost) > 0.05;
    // Zwei Zeilen: wer und wie viel, darunter die Rechnung und ein passender Abschlag.
    return AppListRow(
      leading: AppIconTile(icon: CupertinoIcons.money_euro_circle_fill, color: c.swatch(check.category.swatch)),
      title: check.tracker.name,
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          AppText(
            credit ? l10n.insightsCredit(context.euros(check.balance)) : l10n.insightsBackPayment(context.euros(-check.balance)),
            style: (t) => t.subheadlineEmphasized,
            color: credit ? c.success : c.danger,
          ),
          AppText(
            context.joinParts([check.category.name, l10n.insightsInstalmentDetail(context.euros(check.monthly), '$year', context.euros(check.cost))]),
            style: (t) => t.footnote,
            color: c.textSecondary,
          ),
          if (suggest) AppText(l10n.insightsSuggest(context.euros(check.suggestedMonthly)), style: (t) => t.footnote, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// Wert rechts mit Veränderung darunter; steigende Kosten rot, fallende grün.
class _ValueWithChange extends StatelessWidget {
  const _ValueWithChange({required this.value, required this.change, this.risingIsBad = true});

  final String value;
  final double? change;
  final bool risingIsBad;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.change(change);
    final trend = change.trend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 2,
      children: [
        AppText(value, style: (t) => t.numberM),
        if (text != null)
          AppText(
            text,
            style: (t) => t.captionEmphasized,
            color: switch (trend) {
              1 => risingIsBad ? c.danger : c.success,
              -1 => risingIsBad ? c.success : c.danger,
              _ => c.textSecondary,
            },
          ),
      ],
    );
  }
}
