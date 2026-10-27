import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/dashboard_figures.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../entries/data/tracker_history.dart';
import '../../../entries/view/tracker_page.dart';
import '../../cubit/category_detail_cubit.dart';

/// Übersicht einer Kategorie: Zeitraum wählen, darunter die Kennzahlen als Kacheln – Kosten,
/// Verbrauch und jedes Feld nach seiner Auswertung (Summe, Differenz …). owner und editor wählen
/// unter „Anpassen“, welche Kennzahlen erscheinen. Eine Kachel antippen öffnet den Verlauf ihres
/// Trackers, bei Kosten und Verbrauch gleich im passenden Reiter; gedrückt halten und ziehen
/// ändert die Reihenfolge.
class CategoryDashboardSection extends StatelessWidget {
  const CategoryDashboardSection({super.key, required this.category, required this.state});

  final Category category;
  final CategoryDetailState state;

  static const _periods = [
    DashboardPeriod.thisMonth,
    DashboardPeriod.lastMonth,
    DashboardPeriod.thisYear,
    DashboardPeriod.lastYear,
    DashboardPeriod.last12Months,
    DashboardPeriod.all,
    DashboardPeriod.custom,
  ];

  Future<void> _pickPeriod(BuildContext context, DashboardPeriod period) async {
    final cubit = context.read<CategoryDetailCubit>();
    if (period != DashboardPeriod.custom) return cubit.setPeriod(period);
    final l10n = context.l10n;
    final today = DateTime.now();
    final current = state.custom ?? state.span;
    final from = await AppDateSheet.show(context, title: l10n.periodPickFrom, initial: current?.from ?? DateTime(today.year), maximum: today);
    if (from == null || !context.mounted) return;
    final to = await AppDateSheet.show(context, title: l10n.periodPickTo, initial: today, minimum: from, maximum: today);
    if (to == null) return;
    cubit.setPeriod(DashboardPeriod.custom, from: DateTime.utc(from.year, from.month, from.day), to: DateTime.utc(to.year, to.month, to.day));
  }

  /// Kosten der ganzen Kategorie (und Summen über Zähler mehrerer Tracker) gehören zu mehreren
  /// Trackern – dann erst den Tracker wählen.
  Future<void> _open(BuildContext context, DashboardFigure figure) async {
    final metric = figure.metric.isCost
        ? HistoryMetric.cost
        : figure.isConsumption
        ? HistoryMetric.consumption
        : null;
    final candidates = switch (figure.tracker) {
      final Tracker t => [t],
      null when figure.metric.isCost => [for (final t in category.trackers) if (TrackerHistory.metricsFor(t).contains(HistoryMetric.cost)) t],
      null when figure.metric.isMeters => {for (final (t, _) in DashboardFigures.metersOf(category, figure.metric)) t.id: t}.values.toList(),
      null => const <Tracker>[],
    };
    final tracker = candidates.length <= 1
        ? candidates.firstOrNull
        : await AppSheet.show<Tracker>(
            context,
            title: figure.metric.isCost ? context.l10n.dashboardCost : context.l10n.dashboardConsumption,
            child: AppListGroup(
              children: [
                for (final t in candidates) AppListRow(title: t.name, onTap: () => Navigator.of(context).pop(t)),
              ],
            ),
          );
    if (tracker != null && context.mounted) await TrackerPage.open(context, categoryId: category.id, trackerId: tracker.id, metric: metric);
  }

  Future<void> _customize(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final result = await MetricsSheet.show(context, category);
    if (result != null) await cubit.setMetrics(result.metrics);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final span = state.span;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.dashboardTitle, action: category.canEdit ? l10n.dashboardCustomize : null, onAction: () => _customize(context)),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: Spacing.screen,
            itemCount: _periods.length,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.s),
            itemBuilder: (context, i) {
              final period = _periods[i];
              final selected = period == state.period;
              return AppPressable(
                onTap: () => _pickPeriod(context, period),
                child: Center(
                  child: AppChip(label: period.label(l10n), background: selected ? c.accentSoft : null, foreground: selected ? c.accent : null),
                ),
              );
            },
          ),
        ),
        if (span != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.s),
            child: AppText(l10n.dashboardRange(context.shortDate(span.from), context.shortDate(span.last)), style: (t) => t.footnote, color: c.textSecondary),
          ),
        if (state.figures.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: AppText(l10n.dashboardEmpty, style: (t) => t.subheadline, color: c.textSecondary),
          )
        else
          Padding(
            padding: Spacing.screen,
            child: _FigureGrid(category: category, figures: state.figures, period: state.period, onOpen: (figure) => _open(context, figure)),
          ),
      ],
    );
  }
}

/// Kacheln zu zweit nebeneinander. owner und editor halten eine Kachel gedrückt und ziehen sie an
/// eine andere Stelle; die übrigen rücken schon beim Ziehen nach, gespeichert wird beim Loslassen.
class _FigureGrid extends StatefulWidget {
  const _FigureGrid({required this.category, required this.figures, required this.period, required this.onOpen});

  final Category category;
  final List<DashboardFigure> figures;
  final DashboardPeriod period;
  final ValueChanged<DashboardFigure> onOpen;

  @override
  State<_FigureGrid> createState() => _FigureGridState();
}

class _FigureGridState extends State<_FigureGrid> {
  /// Reihenfolge während des Ziehens als Positionen in [_FigureGrid.figures]; `null` ohne Ziehen.
  List<int>? _order;

  /// Position der gezogenen Kachel in [_FigureGrid.figures].
  int? _dragged;

  @override
  void didUpdateWidget(_FigureGrid old) {
    super.didUpdateWidget(old);
    // Neu geladen (z. B. Änderung eines Mitglieds): Positionen passen nicht mehr zusammen.
    if (_order != null && widget.figures.length != _order!.length) {
      _order = null;
      _dragged = null;
    }
  }

  void _start(int i) => setState(() {
    _dragged = i;
    _order = [for (var j = 0; j < widget.figures.length; j++) j];
  });

  /// Die gezogene Kachel ist über Kachel [target]: dort einreihen, die übrigen rücken nach.
  void _hover(int target) {
    final order = _order, dragged = _dragged;
    if (order == null || dragged == null || target == dragged) return;
    final to = order.indexOf(target);
    setState(() => order.insert(to, order.removeAt(order.indexOf(dragged))));
  }

  void _end() {
    final order = _order, dragged = _dragged;
    if (order == null || dragged == null) return;
    // Erst die neue Reihenfolge in den Cubit (ändert die Kacheln sofort), dann das Ziehen beenden.
    final to = order.indexOf(dragged);
    if (to != dragged) context.read<CategoryDetailCubit>().moveMetric(dragged, to);
    setState(() {
      _order = null;
      _dragged = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final figures = widget.figures;
    final order = _order ?? [for (var i = 0; i < figures.length; i++) i];
    final movable = widget.category.canEdit && figures.length > 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = figures.length == 1 ? constraints.maxWidth : (constraints.maxWidth - Spacing.m) / 2;
        return Wrap(
          spacing: Spacing.m,
          runSpacing: Spacing.m,
          children: [
            for (final i in order)
              SizedBox(
                key: ValueKey(i),
                width: width,
                child: movable ? _movable(context, i, width) : _tile(i),
              ),
          ],
        );
      },
    );
  }

  Widget _tile(int i, {bool tappable = true}) {
    final figure = widget.figures[i];
    return _FigureTile(category: widget.category, figure: figure, period: widget.period, onTap: tappable ? () => widget.onOpen(figure) : null);
  }

  /// Kachel zum Ziehen und zugleich Ziel für andere Kacheln; dazu Bedienhilfen-Aktionen zum Verschieben.
  Widget _movable(BuildContext context, int i, double width) {
    final l10n = context.l10n;
    final cubit = context.read<CategoryDetailCubit>();
    final last = widget.figures.length - 1;
    return Semantics(
      customSemanticsActions: {
        if (i > 0) CustomSemanticsAction(label: l10n.dashboardMoveEarlier): () => cubit.moveMetric(i, i - 1),
        if (i < last) CustomSemanticsAction(label: l10n.dashboardMoveLater): () => cubit.moveMetric(i, i + 1),
      },
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          _hover(i);
          return true;
        },
        builder: (context, _, _) => LongPressDraggable<int>(
          data: i,
          onDragStarted: () => _start(i),
          onDragEnd: (_) => _end(),
          feedback: SizedBox(
            width: width,
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Radii.card)),
                  shadows: [BoxShadow(color: context.colors.shadow, blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Transform.scale(scale: 1.04, child: _tile(i, tappable: false)),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: _tile(i, tappable: false)),
          child: _tile(i),
        ),
      ),
    );
  }
}

class _FigureTile extends StatelessWidget {
  const _FigureTile({required this.category, required this.figure, required this.period, this.onTap});

  final Category category;
  final DashboardFigure figure;
  final DashboardPeriod period;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final (title, subtitle) = MetricLabel.of(context, category, figure.metric);
    final change = switch (context.change(figure.change)) {
      final String text => switch (period) {
        DashboardPeriod.thisMonth || DashboardPeriod.lastMonth => l10n.dashboardVsLastMonth(text),
        DashboardPeriod.custom => l10n.dashboardVsBefore(text),
        DashboardPeriod.all => null,
        _ => l10n.dashboardVsLastYear(text),
      },
      null => null,
    };
    return AppCard(
      padding: const EdgeInsets.all(Spacing.m),
      onTap: onTap,
      semanticLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          AppText(title, style: (t) => t.footnoteEmphasized, color: c.textSecondary, maxLines: 1),
          AppText(_format(context, figure), style: (t) => t.numberL, maxLines: 1),
          AppText(subtitle ?? ' ', style: (t) => t.caption, color: c.textSecondary, maxLines: 1),
          AppText(change ?? (figure.value == null ? l10n.dashboardNoValue : ' '), style: (t) => t.caption, color: c.textSecondary, maxLines: 1),
        ],
      ),
    );
  }

  /// Kosten in ganzen Euro, Verbrauch in der Verbrauchseinheit, Summen und Differenzen eines
  /// Betrags in Euro (ohne „/Monat“), alles andere wie der Wert des Felds.
  static String _format(BuildContext context, DashboardFigure f) {
    final v = f.value;
    if (v == null) return '–';
    if (f.metric.isCost) return context.euros(v);
    final field = f.field!;
    if (f.isConsumption) return context.amount(v, field.usageUnit);
    final decimals = v == v.roundToDouble() || v.abs() >= 100 ? 0 : 1;
    return switch (f.summary) {
      FieldSummary.sum || FieldSummary.difference => switch (field.kind) {
        FieldKind.currency => context.eurosExact(v),
        FieldKind.percent => context.amount(v, '%', decimals: decimals),
        _ => context.amount(v, field.role == FieldRole.meterReading ? field.usageUnit : field.unit ?? '', decimals: decimals),
      },
      // Ein Durchschnitt hat oft viele Stellen – auf das Übliche des Felds runden.
      FieldSummary.average => context.fieldValue(field, double.parse(v.toStringAsFixed(field.kind == FieldKind.currency ? 4 : 2))),
      _ => context.fieldValue(field, v),
    };
  }
}

/// Titel und Untertitel einer Kennzahl – auf der Kachel und in der Auswahl.
abstract final class MetricLabel {
  static (String, String?) of(BuildContext context, Category category, DashboardMetric metric) {
    final l10n = context.l10n;
    final several = category.trackers.length > 1;
    final tracker = category.trackers.where((t) => t.id == metric.trackerId).firstOrNull;
    if (metric.isCost) return (l10n.dashboardCost, tracker?.name ?? (several ? l10n.metricsCostAll : null));
    if (metric.isMeters) {
      final count = DashboardFigures.metersOf(category, metric).length;
      final name = metric.label ?? metric.group;
      return (name ?? l10n.dashboardConsumption, name == null ? l10n.metersAll(count) : l10n.metersCount(count));
    }
    final field = tracker?.fields.where((f) => f.id == metric.fieldId).firstOrNull;
    if (tracker == null || field == null) return ('', null);
    final summary = field.effectiveSummary;
    final consumption = field.role == FieldRole.meterReading && summary == FieldSummary.difference;
    return (
      consumption ? l10n.dashboardConsumption : field.name,
      context.joinParts([if (several) tracker.name, consumption ? l10n.dashboardFromField(field.name) : summary?.label(l10n)]),
    );
  }
}

/// Kennzahlen der Übersicht wählen. Liefert die Auswahl (`metrics: null` = automatisch) oder `null`.
class MetricsSheet extends StatefulWidget {
  const MetricsSheet({super.key, required this.category});

  final Category category;

  static Future<({List<DashboardMetric>? metrics})?> show(BuildContext context, Category category) => AppSheet.show(
    context,
    title: context.l10n.metricsTitle,
    child: MetricsSheet(category: category),
  );

  @override
  State<MetricsSheet> createState() => _MetricsSheetState();
}

class _MetricsSheetState extends State<MetricsSheet> {
  late final _selected = [...DashboardFigures.shown(widget.category)];

  /// Eigene Summen: gewählte und hier neu angelegte.
  late final _custom = [
    for (final m in _selected)
      if (m.isCustom) m,
  ];

  Future<void> _addCustom() async {
    final metric = await CustomSumSheet.show(context, widget.category);
    if (metric == null || !mounted) return;
    setState(() {
      _custom.add(metric);
      _selected.add(metric);
    });
  }

  void _toggle(DashboardMetric metric, bool on) => setState(() {
    _selected.remove(metric);
    if (on) _selected.add(metric);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, Spacing.xl),
      children: [
        AppListGroup(
          color: c.surfaceRaised,
          dividerIndent: Spacing.l,
          children: [
            for (final metric in [...DashboardFigures.options(widget.category), ..._custom])
              if (MetricLabel.of(context, widget.category, metric) case (final title, final subtitle))
                AppListRow(
                  title: title,
                  subtitle: subtitle,
                  chevron: false,
                  trailing: AppSwitch(value: _selected.contains(metric), semanticLabel: title, onChanged: (on) => _toggle(metric, on)),
                  onTap: () => _toggle(metric, !_selected.contains(metric)),
                ),
            if (DashboardFigures.allMeters(widget.category).length > 1)
              AppListRow(
                leading: AppIconTile(icon: CupertinoIcons.add, color: c.accent),
                title: l10n.metricsCustomAdd,
                subtitle: l10n.metricsCustomAddHint,
                onTap: _addCustom,
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.l),
          child: AppText('${l10n.metricsFooter} ${l10n.metricsReorderHint}', style: (t) => t.footnote, color: c.textSecondary),
        ),
        Padding(
          padding: Spacing.screen,
          child: Column(
            spacing: Spacing.s,
            children: [
              AppButton(label: l10n.actionSave, onPressed: () => Navigator.of(context).pop((metrics: [..._selected]))),
              if (widget.category.dashboard.metrics != null)
                AppButton(label: l10n.metricsReset, variant: AppButtonVariant.plain, onPressed: () => Navigator.of(context).pop((metrics: null))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Eigene Summe: Zähler wählen, deren Verbrauch zusammen eine Karte bildet, und ihr einen Namen
/// geben (z. B. „Bad“ aus Bad kalt und Bad warm). Liefert die Kennzahl oder `null`.
class CustomSumSheet extends StatefulWidget {
  const CustomSumSheet({super.key, required this.category});

  final Category category;

  static Future<DashboardMetric?> show(BuildContext context, Category category) => AppSheet.show<DashboardMetric>(
    context,
    title: context.l10n.metricsCustomTitle,
    child: CustomSumSheet(category: category),
  );

  @override
  State<CustomSumSheet> createState() => _CustomSumSheetState();
}

class _CustomSumSheetState extends State<CustomSumSheet> {
  final _name = TextEditingController();
  final _chosen = <String>{};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty && _chosen.isNotEmpty;

  void _toggle(String id) => setState(() => _chosen.contains(id) ? _chosen.remove(id) : _chosen.add(id));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final meters = DashboardFigures.allMeters(widget.category);
    final several = widget.category.trackers.length > 1;
    // Nur Zähler mit derselben Verbrauchseinheit wie der erste gewählte lassen sich addieren.
    final unit = meters.where((m) => _chosen.contains(m.$2.id)).firstOrNull?.$2.usageUnit;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, Spacing.xl),
      children: [
        Padding(
          padding: Spacing.screen,
          child: AppTextField(controller: _name, hint: l10n.metricsCustomNameHint, maxLength: 40, color: c.surfaceRaised, onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: Spacing.m),
        AppListGroup(
          color: c.surfaceRaised,
          dividerIndent: Spacing.l,
          children: [
            for (final (tracker, meter) in meters)
              if (unit == null || meter.usageUnit == unit || _chosen.contains(meter.id))
                AppListRow(
                  title: meter.name,
                  subtitle: context.joinParts([if (several) tracker.name, meter.meterGroup]),
                  chevron: false,
                  trailing: AppSwitch(value: _chosen.contains(meter.id), semanticLabel: meter.name, onChanged: (_) => _toggle(meter.id)),
                  onTap: () => _toggle(meter.id),
                ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.l),
          child: AppText(l10n.metricsCustomFooter, style: (t) => t.footnote, color: c.textSecondary),
        ),
        Padding(
          padding: Spacing.screen,
          child: AppButton(
            label: l10n.actionSave,
            onPressed: _valid
                ? () => Navigator.of(context).pop(
                    DashboardMetric.meters(
                      fieldIds: [
                        for (final (_, m) in meters)
                          if (_chosen.contains(m.id)) m.id,
                      ],
                      label: _name.text.trim(),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

extension on DashboardPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    DashboardPeriod.thisMonth => l10n.periodThisMonth,
    DashboardPeriod.lastMonth => l10n.periodLastMonth,
    DashboardPeriod.thisYear => l10n.periodThisYear,
    DashboardPeriod.lastYear => l10n.periodLastYear,
    DashboardPeriod.last12Months => l10n.periodLast12Months,
    DashboardPeriod.all => l10n.periodAll,
    DashboardPeriod.custom => l10n.periodCustom,
  };
}
