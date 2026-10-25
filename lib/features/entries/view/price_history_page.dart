import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../core/utils/cost_engine.dart';
import '../cubit/tracker_cubit.dart';
import 'entry_form_page.dart';
import 'tracker_page.dart';

/// Verlauf eines Preises im Vertrag (Arbeitspreis, Grundpreis, Abschlag): alle Werte mit „ab …“,
/// neueste zuerst, künftige als geplant. Antippen ändert die Preisänderung; unten „Preise ändern“.
/// Lädt den Tracker selbst und aktualisiert sich bei jeder Änderung.
class PriceHistoryPage extends StatelessWidget {
  const PriceHistoryPage({super.key, required this.args, required this.fieldId});

  final TrackerArgs args;
  final String fieldId;

  static Future<void> open(BuildContext context, {required String categoryId, required String trackerId, required String fieldId}) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          settings: const RouteSettings(name: TrackerPage.routeName),
          builder: (_) => PriceHistoryPage(args: TrackerArgs(categoryId: categoryId, trackerId: trackerId), fieldId: fieldId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<TrackerCubit>(param1: args)..load(), child: _PriceHistoryView(fieldId: fieldId));
  }
}

class _PriceHistoryView extends StatelessWidget {
  const _PriceHistoryView({required this.fieldId});

  final String fieldId;

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
            if (state.status == TrackerStatus.loading) return const Center(child: CupertinoActivityIndicator());
            if (category == null || tracker == null || field == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(title: '', onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Center(child: AppText(l10n.trackerMissing, style: (t) => t.body, color: c.textSecondary)),
                  ),
                ],
              );
            }
            final today = CostEngine.day(state.today ?? DateTime.now());
            final history = state.priceHistory(field);
            return AppActionBar(
              action: category.canEdit
                  ? AppButton(
                      label: l10n.contractChange,
                      icon: CupertinoIcons.tag,
                      onPressed: () => EntryFormPage.open(context, category: category, tracker: tracker, contract: true),
                    )
                  : null,
              content: ListView(
                padding: EdgeInsets.only(bottom: AppActionBar.inset(context)),
                children: [
                  AppHeader(title: field.name, overline: tracker.name, onBack: () => Navigator.of(context).pop()),
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
                            trailing: AppText(context.fieldValue(field, e.values[field.id]!), style: (t) => t.numberM),
                            onTap: category.canEdit ? () => EntryFormPage.open(context, category: category, tracker: tracker, entry: e, contract: true) : null,
                          ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
