import 'package:equatable/equatable.dart';

import '../../../core/models/tracking.dart';
import '../../../core/utils/cost_engine.dart';

/// Was wäre wenn: Prognose eines Trackers fürs nächste Jahr – mit den heutigen Preisen und mit
/// neuen Preisen ab dem 1. Januar (z. B. ein Angebot mit anderem Arbeits- oder Grundpreis).
class WhatIf extends Equatable {
  const WhatIf({required this.before, required this.after});

  final double before;
  final double after;

  double get delta => after - before;

  /// Felder, deren Wert sich durchspielen lässt: Arbeitspreis und wiederkehrende Kosten, ohne
  /// Formel-Felder (die rechnet `Formulas.apply` neu und überschriebe den durchgespielten Wert).
  static List<FieldDefinition> priceFields(Tracker tracker) => [
    for (final f in tracker.fields)
      if ((f.role == FieldRole.unitPrice || f.role == FieldRole.recurringCost) && f.kind != FieldKind.formula) f,
  ];

  /// Wert des Felds, der heute gilt (letzter Eintrag bis heute), `null` ohne Eintrag.
  static double? current(Tracker tracker, FieldDefinition field, DateTime today) {
    final day = CostEngine.day(today);
    (DateTime, double)? last;
    for (final e in tracker.entries) {
      final v = e.number(field.id);
      if (v == null || e.date.isAfter(day)) continue;
      if (last == null || !e.date.isBefore(last.$1)) last = (e.date, v.toDouble());
    }
    return last?.$2;
  }

  /// [prices]: Feld-Id → neuer Wert, gültig ab dem 1. Januar des nächsten Jahres.
  factory WhatIf.of(Tracker tracker, DateTime today, Map<String, double> prices) {
    final from = DateTime.utc(today.year + 1), to = DateTime.utc(today.year + 2);
    final before = CostEngine(tracker, today: today).parts(from, to).total;
    if (prices.isEmpty) return WhatIf(before: before, after: before);
    final changed = tracker.copyWith(entries: [...tracker.entries, Entry(id: 'what-if', date: from, values: prices)]);
    return WhatIf(before: before, after: CostEngine(changed, today: today).parts(from, to).total);
  }

  @override
  List<Object?> get props => [before, after];
}
