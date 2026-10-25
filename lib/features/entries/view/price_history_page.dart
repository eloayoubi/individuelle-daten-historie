import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../core/utils/cost_engine.dart';
import '../cubit/tracker_cubit.dart';
import 'entry_form_page.dart';

/// Verlauf eines Preises im Vertrag (Arbeitspreis, Grundpreis, Abschlag): alle Werte mit „ab …“,
/// neueste zuerst, künftige als geplant. Antippen ändert die Preisänderung, Plus trägt eine neue ein.
/// Liest den Tracker aus dem [TrackerCubit] der Zählerseite und aktualisiert sich mit ihm.
class PriceHistoryPage extends StatelessWidget {
  const PriceHistoryPage({super.key, required this.fieldId});

  final String fieldId;

  static Future<void> open(BuildContext context, {required TrackerCubit cubit, required String fieldId}) => Navigator.of(context).push(
    CupertinoPageRoute<void>(builder: (_) => BlocProvider.value(value: cubit, child: PriceHistoryPage(fieldId: fieldId))),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TrackerCubit, TrackerState>(
          builder: (context, state) {
            final category = state.category;
            final tracker = state.tracker;
            final field = tracker?.fields.where((f) => f.id == fieldId).firstOrNull;
            if (category == null || tracker == null || field == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(title: '', onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Center(child: AppText(l10n.detailMissing, style: (t) => t.body, color: c.textSecondary)),
                  ),
                ],
              );
            }
            final today = CostEngine.day(DateTime.now());
            final history = state.priceHistory(field);
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
              children: [
                AppHeader(
                  title: field.name,
                  overline: tracker.name,
                  onBack: () => Navigator.of(context).pop(),
                  actions: [
                    if (category.canEdit)
                      AppIconButton(
                        icon: CupertinoIcons.plus,
                        semanticLabel: l10n.contractChange,
                        filled: true,
                        onPressed: () => EntryFormPage.open(context, category: category, tracker: tracker, contract: true),
                      ),
                  ],
                ),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.l, Spacing.xxl, 0),
                    child: AppText(l10n.priceHistoryEmpty, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
                  )
                else
                  AppListGroup(
                    dividerIndent: Spacing.l,
                    children: [
                      for (final e in history)
                        AppListRow(
                          title: l10n.priceHistoryFrom(context.shortDate(e.date)),
                          subtitle: e.date.isAfter(today) ? l10n.priceHistoryPlanned : null,
                          trailing: AppText(context.fieldValue(field, e.values[field.id]!), style: (t) => t.body, color: c.textSecondary),
                          onTap: category.canEdit ? () => EntryFormPage.open(context, category: category, tracker: tracker, entry: e) : null,
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
