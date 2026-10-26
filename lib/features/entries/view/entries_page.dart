import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/tracker_cubit.dart';
import 'entry_form_page.dart';
import 'tracker_page.dart';
import 'widgets/entry_table.dart';

/// Alle Einträge eines Trackers, nach Jahren gruppiert, neueste zuerst; unten „Wert eintragen“.
/// Lädt den Tracker selbst und aktualisiert sich bei jeder Änderung.
class EntriesPage extends StatelessWidget {
  const EntriesPage({super.key, required this.args});

  final TrackerArgs args;

  static Future<void> open(BuildContext context, {required String categoryId, required String trackerId}) => Navigator.of(context).push(
    CupertinoPageRoute<void>(settings: const RouteSettings(name: TrackerPage.routeName), builder: (_) => EntriesPage(args: TrackerArgs(categoryId: categoryId, trackerId: trackerId))),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<TrackerCubit>(param1: args)..load(), child: const _EntriesView());
  }
}

class _EntriesView extends StatelessWidget {
  const _EntriesView();

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
            if (state.status == TrackerStatus.loading) return const Center(child: CupertinoActivityIndicator());
            if (category == null || tracker == null) {
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
            final years = <int, List<Entry>>{};
            for (final e in state.entries) {
              years.putIfAbsent(e.date.year, () => []).add(e);
            }
            final canAdd = category.canEdit && tracker.entryFields.isNotEmpty;
            return AppActionBar(
              action: canAdd
                  ? AppButton(label: l10n.trackerAddEntry, icon: CupertinoIcons.plus, onPressed: () => EntryFormPage.open(context, category: category, tracker: tracker))
                  : null,
              content: ListView(
                padding: EdgeInsets.only(bottom: canAdd ? AppActionBar.inset(context) : MediaQuery.paddingOf(context).bottom + Spacing.xxl),
                children: [
                  AppHeader(title: l10n.trackerEntries, overline: tracker.name, onBack: () => Navigator.of(context).pop()),
                  for (final MapEntry(key: year, value: list) in years.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.xs),
                      child: AppText('$year', style: (t) => t.footnoteEmphasized, color: c.textSecondary),
                    ),
                    EntryTable(
                      category: category,
                      tracker: tracker,
                      entries: list,
                      onTap: category.canEdit ? (e) => EntryFormPage.open(context, category: category, tracker: tracker, entry: e) : null,
                    ),
                    const SizedBox(height: Spacing.s),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
