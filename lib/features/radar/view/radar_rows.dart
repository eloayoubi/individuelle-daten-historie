import 'package:flutter/cupertino.dart';

import '../../../core/core.dart';
import '../data/radar.dart';

/// Texte zu einem Fund des Radars: Zeile in der Übersicht und Erklärung im Sheet.
extension FindingTextX on BuildContext {
  String findingTitle(Finding f) {
    final name = f.tracker.name;
    return switch (f.kind) {
      FindingKind.deadline => l10n.radarDeadlineTitle(name, f.field?.name ?? '', f.days ?? 0),
      FindingKind.priceIncrease => f.upcoming ? l10n.radarPriceTitleUpcoming(name) : l10n.radarPriceTitle(name),
      FindingKind.usageUp => l10n.radarUsageTitle(name, change(f.ratio) ?? ''),
      FindingKind.backPayment => l10n.radarBackPaymentTitle(name),
      FindingKind.refund => l10n.radarRefundTitle(name),
    };
  }

  String findingSubtitle(Finding f) => switch (f.kind) {
    FindingKind.deadline => l10n.radarDeadlineSub(euros(f.amount)),
    FindingKind.priceIncrease => l10n.radarPriceSub(euros(f.amount), _findingWhen(f)),
    FindingKind.usageUp => l10n.radarUsageSub(euros(f.amount)),
    FindingKind.backPayment || FindingKind.refund => l10n.radarInstalmentSub(euros(f.amount), euros(f.suggested ?? 0)),
  };

  /// Ein Satz dazu, wie der Fund gerechnet ist.
  String findingExplanation(Finding f) {
    final field = f.field;
    return switch (f.kind) {
      FindingKind.deadline => l10n.radarDeadlineExplain(field?.name ?? '', shortDate(f.date!), euros(f.amount)),
      FindingKind.priceIncrease when field!.role == FieldRole.unitPrice => l10n.radarPriceExplainUnit(
        field.name,
        fieldValue(field, f.before!),
        fieldValue(field, f.after!),
        _findingWhen(f),
        euros(f.amount),
      ),
      FindingKind.priceIncrease => l10n.radarPriceExplainRecurring(field!.name, fieldValue(field, f.before!), fieldValue(field, f.after!), _findingWhen(f), euros(f.amount)),
      FindingKind.usageUp => l10n.radarUsageExplain(shortDate(f.date!), amount(f.after!, field!.usageUnit), amount(f.before!, field.usageUnit), euros(f.amount)),
      FindingKind.backPayment || FindingKind.refund => l10n.radarInstalmentExplain(
        '${f.date!.year}',
        euros(f.paid ?? 0),
        euros(f.cost ?? 0),
        euros(f.monthly ?? 0),
        euros(f.suggested ?? 0),
      ),
    };
  }

  String _findingWhen(Finding f) => f.upcoming ? l10n.radarFrom(shortDate(f.date!)) : l10n.radarSince(shortDate(f.date!));
}

/// „Radar“: Funde mit Betrag – Fristen, gestiegene Preise, Nachzahlungen, mehr Verbrauch.
class RadarRows extends StatelessWidget {
  const RadarRows({super.key, required this.findings, required this.onTap});

  final List<Finding> findings;
  final ValueChanged<Finding> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppListGroup(
      footer: context.l10n.radarFooter,
      children: [
        for (final f in findings)
          AppListRow(
            leading: AppIconTile(
              icon: switch (f.kind) {
                FindingKind.deadline => CupertinoIcons.timer,
                FindingKind.priceIncrease => CupertinoIcons.arrow_up_right,
                FindingKind.usageUp => CupertinoIcons.chart_bar_fill,
                FindingKind.backPayment => CupertinoIcons.exclamationmark_triangle_fill,
                FindingKind.refund => CupertinoIcons.checkmark_seal_fill,
              },
              color: switch (f.kind) {
                FindingKind.deadline || FindingKind.usageUp => c.warning,
                FindingKind.priceIncrease || FindingKind.backPayment => c.danger,
                FindingKind.refund => c.success,
              },
            ),
            title: context.findingTitle(f),
            subtitle: context.findingSubtitle(f),
            onTap: () => onTap(f),
          ),
      ],
    );
  }
}
