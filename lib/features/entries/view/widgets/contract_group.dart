import 'package:flutter/cupertino.dart';

import '../../../../core/core.dart';
import '../../data/tracker_history.dart';
import '../entry_form_page.dart';
import '../price_history_page.dart';
import 'tracker_details.dart';

/// Vertrag eines Versorgungszählers: je Preis der aktuelle Wert (antippen zeigt den Verlauf), darunter
/// die Details (Anbieter, Vertragsende) und „Preise ändern“. Ohne Bearbeitungsrecht nur lesen.
class ContractGroup extends StatelessWidget {
  const ContractGroup({super.key, required this.category, required this.tracker, required this.contract, this.missingPrice = false, this.onSaveDetail});

  final Category category;
  final Tracker tracker;

  /// Aktuelle Werte je Preis ([TrackerHistory.contractOf]); fehlende Preise zeigen „Eintragen“.
  final List<CurrentValue> contract;
  final bool missingPrice;
  final Future<void> Function(FieldDefinition field, Object? value)? onSaveDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListGroup(
          dividerIndent: Spacing.l,
          // Wer bearbeiten darf, sieht dazu oben eine Karte mit Aktion; hier nur für alle anderen.
          footer: missingPrice && !category.canEdit ? l10n.contractMissingPrice : null,
          children: [
            for (final field in tracker.contractFields)
              _PriceRow(
                canEdit: category.canEdit,
                field: field,
                value: contract.where((v) => v.field.id == field.id).firstOrNull,
                // Noch kein Wert: gleich eintragen statt in einen leeren Verlauf.
                onTap: category.canEdit && !contract.any((v) => v.field.id == field.id)
                    ? () => EntryFormPage.open(context, category: category, tracker: tracker, contract: true)
                    : () => PriceHistoryPage.open(context, categoryId: category.id, trackerId: tracker.id, fieldId: field.id),
              ),
          ],
        ),
        if (tracker.detailFields.isNotEmpty) ...[
          const SizedBox(height: Spacing.m),
          TrackerDetailsGroup(tracker: tracker, onSave: category.canEdit ? onSaveDetail : null),
        ],
        if (category.canEdit)
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.m, Spacing.l, 0),
            child: AppButton(
              label: contract.isEmpty ? l10n.contractEnterPrices : l10n.contractChange,
              icon: CupertinoIcons.tag,
              variant: AppButtonVariant.tinted,
              onPressed: () => EntryFormPage.open(context, category: category, tracker: tracker, contract: true),
            ),
          ),
      ],
    );
  }
}

/// Preis im Vertrag: aktueller Wert seit …, eine eingetragene Änderung; ohne Wert „Eintragen“.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.field, required this.value, required this.onTap, this.canEdit = true});

  /// Platz für den Wert rechts (längere werden gekürzt).
  static const _valueWidth = 180.0;

  final FieldDefinition field;
  final CurrentValue? value;
  final VoidCallback onTap;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final v = value;
    return AppListRow(
      title: field.name,
      subtitle: v == null
          ? null
          : context.joinParts([
              l10n.trackerSince(context.shortDate(v.since)),
              if (v.upcoming case final Object next) l10n.trackerUpcoming(context.shortDate(v.upcomingFrom!), context.fieldValue(field, next)),
            ]),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _valueWidth),
        child: v == null
            ? AppText(canEdit ? l10n.contractSet : '–', style: (t) => t.body, color: canEdit ? c.accent : c.textTertiary)
            : AppText(context.fieldValue(field, v.value), style: (t) => t.numberM, maxLines: 1, align: TextAlign.end),
      ),
      onTap: onTap,
    );
  }
}
