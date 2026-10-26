import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Einträge als Tabelle: links das Datum (bei einer Rechnung der Zeitraum, darunter wer ihn erfasst
/// hat und Hinweise wie „Rechnung“), rechts je Feld mit Werten eine Spalte, am Ende die Notiz,
/// falls eine da ist. Zahlen stehen rechtsbündig mit gleich breiten Ziffern. Passt die Tabelle nicht in die
/// Breite, lässt sie sich seitlich schieben. Antippen einer Zeile öffnet den Eintrag.
class EntryTable extends StatelessWidget {
  const EntryTable({super.key, required this.category, required this.tracker, required this.entries, this.onTap});

  /// Breiter wird keine Spalte, längere Werte werden gekürzt.
  static const _maxColumn = 180.0;

  final Category category;
  final Tracker tracker;
  final List<Entry> entries;
  final void Function(Entry entry)? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.textStyles;
    final l10n = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final headStyle = t.footnoteEmphasized.withColor(c.textSecondary);
    final dateStyle = t.subheadline;
    final hintStyle = t.caption.withColor(c.textSecondary);
    final valueStyle = t.subheadline.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)..layout();
      final width = painter.width;
      painter.dispose();
      return width.ceilToDouble();
    }

    // Felder ohne einen Wert in diesen Einträgen bekommen keine Spalte voller Striche.
    final fields = [
      for (final f in tracker.fields)
        if (!f.isDetail && entries.any((e) => e.values[f.id] != null)) f,
    ];
    final showNote = entries.any((e) => e.note?.trim().isNotEmpty ?? false);
    final rows = [
      for (final e in entries)
        (
          entry: e,
          date: tracker.isBill(e) ? l10n.entryPeriodRange(context.shortDate(e.periodStart!), context.shortDate(e.periodEnd!)) : context.shortWeekdayDate(e.date),
          hint: context.joinParts([
            if (category.sharedWith.where((m) => m.userId == e.createdBy).firstOrNull case final CategoryMember by) l10n.entryBy(by.name.isEmpty ? l10n.shareNoName : by.name),
            if (tracker.isBill(e)) l10n.entryKindBill,
            if (e.meterChange) l10n.trackerMeterChanged,
          ]),
          values: [
            for (final f in fields)
              switch (e.values[f.id]) {
                // Eine Rechnung trägt statt des Zählerstands den Verbrauch des Zeitraums.
                final num v when tracker.isBill(e) && f.role == FieldRole.meterReading => context.amount(v.toDouble(), f.usageUnit),
                final Object v => context.fieldValue(f, v),
                null => null,
              },
            if (showNote) e.note?.trim(),
          ],
        ),
    ];
    final headers = [for (final f in fields) f.name, if (showNote) l10n.entryNote];
    final numeric = [for (final f in fields) f.kind.storage == FieldStorage.number || f.kind == FieldKind.formula, if (showNote) false];
    final widths = [
      for (var i = 0; i < headers.length; i++)
        math.min(_maxColumn, [measure(headers[i], headStyle), for (final r in rows) measure(r.values[i] ?? '–', valueStyle)].reduce(math.max)),
    ];
    final dateWidth = math.min(_maxColumn, [
      measure(l10n.entryDate, headStyle),
      for (final r in rows) ...[measure(r.date, dateStyle), if (r.hint.isNotEmpty) measure(r.hint, hintStyle)],
    ].reduce(math.max));
    final natural = Spacing.l * 2 + dateWidth + widths.fold(0.0, (sum, w) => sum + Spacing.l + w);

    Widget line({required double width, required Widget date, required List<Widget> cells, double vertical = Spacing.s + 2}) => Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.l, vertical: vertical),
      child: Row(
        spacing: Spacing.l,
        children: [
          // Was über die natürliche Breite hinaus da ist, geht ans Datum – die Werte rücken nach rechts.
          SizedBox(width: dateWidth + width - natural, child: date),
          for (var i = 0; i < cells.length; i++)
            SizedBox(width: widths[i], child: Align(alignment: numeric[i] ? Alignment.centerRight : Alignment.centerLeft, child: cells[i])),
        ],
      ),
    );

    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Radii.card))),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.max(natural, constraints.maxWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      line(
                        width: width,
                        vertical: Spacing.s,
                        date: Text(l10n.entryDate, style: headStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        cells: [for (final h in headers) Text(h, style: headStyle, maxLines: 1, overflow: TextOverflow.ellipsis)],
                      ),
                      for (final r in rows) ...[
                        Divider(height: 0.5, thickness: 0.5, indent: Spacing.l, color: c.separator),
                        AppPressable(
                          onTap: onTap == null ? null : () => onTap!(r.entry),
                          scale: 1,
                          child: line(
                            width: width,
                            date: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                Text(r.date, style: dateStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (r.hint.isNotEmpty) Text(r.hint, style: hintStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            cells: [
                              for (final (i, v) in r.values.indexed)
                                Text(
                                  v ?? '–',
                                  style: v == null ? valueStyle.withColor(c.textTertiary) : valueStyle,
                                  maxLines: numeric[i] ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: numeric[i] ? TextAlign.end : TextAlign.start,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
