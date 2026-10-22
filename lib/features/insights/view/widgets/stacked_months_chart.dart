import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/insights.dart';

/// Kosten je Monat als gestapelte Balken in den Kategoriefarben. Hochgerechnete Monate sind blasser.
/// Antippen wählt einen Monat; oben stehen sein Betrag und ob er hochgerechnet ist.
class StackedMonthsChart extends StatefulWidget {
  const StackedMonthsChart({super.key, required this.insights});

  final Insights insights;

  @override
  State<StackedMonthsChart> createState() => _StackedMonthsChartState();
}

class _StackedMonthsChartState extends State<StackedMonthsChart> {
  static const _height = 150.0;

  late var _selected = _defaultMonth;

  /// Plätze für Balken: wenige Monate stehen links und werden nicht breit gezogen.
  static int _slots(int count) => count < 6 ? 6 : count;

  int get _defaultMonth => widget.insights.isCurrentYear ? widget.insights.today.month - 1 : 11;

  @override
  void didUpdateWidget(StackedMonthsChart old) {
    super.didUpdateWidget(old);
    if (old.insights.year != widget.insights.year) _selected = _defaultMonth;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final i = widget.insights;
    // Reihenfolge der Stapel wie die Kategorien im Jahresvergleich (teuerste unten).
    final order = [for (final comparison in i.comparisons) comparison.category];
    // Erst ab dem ersten Monat mit Daten; davor gab es nichts zu erfassen.
    final first = i.firstMonth.clamp(0, 11);
    final shown = [for (var m = first; m < 12; m++) m];
    final slots = _slots(shown.length);
    final month = DateTime.utc(i.year, _selected + 1);
    final label = l10n.trackerChartValue(context.monthYear(month), context.euros(i.monthTotal(_selected)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.s,
      children: [
        AppText(i.isProjected(_selected) ? l10n.insightsProjectedValue(label) : label, style: (t) => t.headline),
        LayoutBuilder(
          builder: (context, constraints) {
            void select(Offset p) => setState(() => _selected = (first + (p.dx / constraints.maxWidth * slots).floor()).clamp(first, 11));
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => select(d.localPosition),
              onHorizontalDragUpdate: (d) => select(d.localPosition),
              child: Semantics(
                label: l10n.insightsMonthly,
                child: SizedBox(
                  height: _height,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _StackPainter(
                      months: [
                        for (final m in shown) [for (final category in order) (c.swatch(category.swatch), i.months[m][category.id] ?? 0)],
                      ],
                      projected: [for (final m in shown) i.isProjected(m)],
                      slots: slots,
                      selected: _selected - first,
                      grid: c.separator,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            for (final m in shown)
              Expanded(
                child: AppText(
                  context.monthInitial(DateTime.utc(i.year, m + 1)),
                  style: (t) => m == _selected ? t.caption2Emphasized : t.caption2,
                  color: m == _selected ? c.textPrimary : c.textSecondary,
                  align: TextAlign.center,
                ),
              ),
            if (slots > shown.length) Spacer(flex: slots - shown.length),
          ],
        ),
      ],
    );
  }
}

class _StackPainter extends CustomPainter {
  _StackPainter({required this.months, required this.projected, required this.slots, required this.selected, required this.grid});

  /// Je Monat die Stapel (Farbe, Betrag) von unten nach oben.
  final List<List<(Color, double)>> months;
  final List<bool> projected;
  final int slots;
  final int selected;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = grid..strokeWidth = 1);
    final totals = [for (final m in months) m.fold(0.0, (sum, s) => sum + (s.$2 > 0 ? s.$2 : 0))];
    final top = totals.fold(0.0, (a, b) => a > b ? a : b);
    if (top <= 0) return;
    final slot = size.width / slots;
    final barWidth = slot * 0.6;
    for (final (i, stack) in months.indexed) {
      final left = i * slot + (slot - barWidth) / 2;
      final alpha = i == selected ? 1.0 : (projected[i] ? 0.3 : 0.6);
      var y = size.height;
      final bar = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, size.height - totals[i] / (top * 1.06) * size.height, left + barWidth, size.height),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas
        ..save()
        ..clipRRect(bar);
      for (final (color, value) in stack) {
        if (value <= 0) continue;
        final h = value / (top * 1.06) * size.height;
        canvas.drawRect(Rect.fromLTRB(left, y - h, left + barWidth, y), Paint()..color = color.withValues(alpha: alpha));
        y -= h;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StackPainter old) => old.months != months || old.slots != slots || old.selected != selected || old.projected != projected || old.grid != grid;
}
