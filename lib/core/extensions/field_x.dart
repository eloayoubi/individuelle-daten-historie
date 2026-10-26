import 'package:flutter/cupertino.dart';

import '../../l10n/generated/app_localizations.dart';
import '../models/tracking.dart';
import '../utils/formula.dart';

/// Beschriftung und Symbol der Feldtypen.
extension FieldKindX on FieldKind {
  String label(AppLocalizations l10n) => switch (this) {
    FieldKind.text => l10n.kindText,
    FieldKind.number => l10n.kindNumber,
    FieldKind.currency => l10n.kindCurrency,
    FieldKind.percent => l10n.kindPercent,
    FieldKind.date => l10n.kindDate,
    FieldKind.toggle => l10n.kindToggle,
    FieldKind.choice => l10n.kindChoice,
    FieldKind.formula => l10n.kindFormula,
  };

  IconData get icon => switch (this) {
    FieldKind.text => CupertinoIcons.textformat,
    FieldKind.number => CupertinoIcons.number,
    FieldKind.currency => CupertinoIcons.money_euro,
    FieldKind.percent => CupertinoIcons.percent,
    FieldKind.date => CupertinoIcons.calendar,
    FieldKind.toggle => CupertinoIcons.checkmark_square,
    FieldKind.choice => CupertinoIcons.list_bullet,
    FieldKind.formula => CupertinoIcons.function,
  };
}

/// Beschriftung und Erklärung des Zeitverhaltens.
extension FieldRoleX on FieldRole {
  String label(AppLocalizations l10n) => switch (this) {
    FieldRole.info => l10n.roleInfo,
    FieldRole.snapshot => l10n.roleSnapshot,
    FieldRole.meterReading => l10n.roleMeterReading,
    FieldRole.unitPrice => l10n.roleUnitPrice,
    FieldRole.recurringCost => l10n.roleRecurringCost,
    FieldRole.oneOffCost => l10n.roleOneOffCost,
    FieldRole.deadline => l10n.roleDeadline,
    FieldRole.instalment => l10n.roleInstalment,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    FieldRole.info => l10n.roleInfoHint,
    FieldRole.snapshot => l10n.roleSnapshotHint,
    FieldRole.meterReading => l10n.roleMeterReadingHint,
    FieldRole.unitPrice => l10n.roleUnitPriceHint,
    FieldRole.recurringCost => l10n.roleRecurringCostHint,
    FieldRole.oneOffCost => l10n.roleOneOffCostHint,
    FieldRole.deadline => l10n.roleDeadlineHint,
    FieldRole.instalment => l10n.roleInstalmentHint,
  };
}

/// Beschriftung und Erklärung der Zusammenfassungen für Kennzahlen.
extension FieldSummaryX on FieldSummary {
  String label(AppLocalizations l10n) => switch (this) {
    FieldSummary.sum => l10n.summarySum,
    FieldSummary.difference => l10n.summaryDifference,
    FieldSummary.average => l10n.summaryAverage,
    FieldSummary.latest => l10n.summaryLatest,
    FieldSummary.min => l10n.summaryMin,
    FieldSummary.max => l10n.summaryMax,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    FieldSummary.sum => l10n.summarySumHint,
    FieldSummary.difference => l10n.summaryDifferenceHint,
    FieldSummary.average => l10n.summaryAverageHint,
    FieldSummary.latest => l10n.summaryLatestHint,
    FieldSummary.min => l10n.summaryMinHint,
    FieldSummary.max => l10n.summaryMaxHint,
  };
}

/// Fälligkeit wiederkehrender Beträge: monatlich, vierteljährlich, jährlich.
abstract final class FieldIntervals {
  static const values = [1, 3, 12];

  static String label(AppLocalizations l10n, int months) => switch (months) {
    1 => l10n.intervalMonthly,
    3 => l10n.intervalQuarterly,
    12 => l10n.intervalYearly,
    _ => l10n.intervalMonths(months),
  };
}

/// Fehlermeldung eines Formel-Ausdrucks (Stellen ab 1 gezählt).
extension FormulaExceptionX on FormulaException {
  String message(AppLocalizations l10n) => switch (kind) {
    FormulaErrorKind.empty => l10n.formulaErrorEmpty,
    FormulaErrorKind.unexpectedCharacter => l10n.formulaErrorCharacter(detail ?? '', position + 1),
    FormulaErrorKind.unexpectedEnd => l10n.formulaErrorEnd,
    FormulaErrorKind.unexpectedToken => l10n.formulaErrorToken(detail ?? '', position + 1),
    FormulaErrorKind.missingParenthesis => l10n.formulaErrorParenthesis(position + 1),
    FormulaErrorKind.unknownFunction => l10n.formulaErrorFunction(detail ?? ''),
    FormulaErrorKind.argumentCount => l10n.formulaErrorArguments(detail ?? ''),
    FormulaErrorKind.unknownVariable => l10n.formulaErrorVariable(detail ?? ''),
    FormulaErrorKind.tooDeep => l10n.formulaErrorDeep,
  };
}
