import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/tracker_history.dart';

/// Zwölf Monate als Balken, der gewählte kräftig, die übrigen blasser. Ein feiner Strich zeigt
/// denselben Monat im Vorjahr. Antippen wählt einen Monat; oben steht sein Wert.
class HistoryChart extends StatefulWidget {
  const HistoryChart({super.key, required this.history, required this.color, required this.format});

  final TrackerHistory history;
  final Color color;

  /// Wert als Text, z. B. `context.euros` oder Menge mit Einheit.
  final String Function(double) format;

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  static const _height = 140.0;

  late var _selected = widget.history.months.length - 1;

  @override
  void didUpdateWidget(HistoryChart old) {
    super.didUpdateWidget(old);
    // Andere Kennzahl oder andere Monate (Eintrag gelöscht/ergänzt): wieder der laufende Monat.
    if (old.history.metric != widget.history.metric || old.history.months.length != widget.history.months.length) {
      _selected = widget.history.months.length - 1;
    }
  }

  /// Plätze für Balken: wenige Monate stehen links und werden nicht breit gezogen.
  static int _slots(int count) => math.max(count, 6);

  void _select(Offset position, double width) {
    final count = widget.history.months.length;
    setState(() => _selected = (position.dx / width * _slots(count)).floor().clamp(0, count - 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final months = widget.history.months;
    final selected = months[_selected.clamp(0, months.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.s,
      children: [
        AppText(
          context.l10n.trackerChartValue(context.monthYear(selected.month), widget.format(selected.value)),
          style: (t) => t.headline,
        ),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition, constraints.maxWidth),
            onHorizontalDragUpdate: (d) => _select(d.localPosition, constraints.maxWidth),
            child: Semantics(
              label: context.l10n.trackerLast12,
              child: SizedBox(
                height: _height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BarsPainter(months: months, slots: _slots(months.length), selected: _selected, color: widget.color, ghost: c.textTertiary, grid: c.separator),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final (i, m) in months.indexed)
              Expanded(
                child: AppText(
                  context.monthShort(m.month),
                  style: (t) => i == _selected ? t.caption2Emphasized : t.caption2,
                  color: i == _selected ? c.textPrimary : c.textSecondary,
                  align: TextAlign.center,
                ),
              ),
            if (_slots(months.length) > months.length) Spacer(flex: _slots(months.length) - months.length),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.months, required this.slots, required this.selected, required this.color, required this.ghost, required this.grid});

  final List<HistoryMonth> months;
  final int slots;
  final int selected;
  final Color color;
  final Color ghost;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final top = [for (final m in months) math.max(m.value, m.previousYear ?? 0)].fold(0.0, math.max);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = grid..strokeWidth = 1);
    if (top <= 0) return;
    final slot = size.width / slots;
    final barWidth = slot * 0.56;
    double y(double v) => size.height - (v.clamp(0, double.infinity) / (top * 1.08)) * size.height;
    for (final (i, m) in months.indexed) {
      final left = i * slot + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, y(m.value), left + barWidth, size.height),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = i == selected ? color : color.withValues(alpha: 0.4));
      if (m.previousYear case final double previous) {
        final py = y(previous);
        canvas.drawLine(
          Offset(left - 2, py),
          Offset(left + barWidth + 2, py),
          Paint()
            ..color = ghost
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.months != months || old.slots != slots || old.selected != selected || old.color != color || old.ghost != ghost || old.grid != grid;
}
