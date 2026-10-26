import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../entries/data/tracker_history.dart';
import '../../entries/view/entry_form_page.dart';
import '../../entries/view/tracker_page.dart';
import '../../entries/view/widgets/contract_group.dart';
import '../../entries/view/widgets/tracker_details.dart';
import '../../sharing/view/share_page.dart';
import '../../storage/view/cloud_flow.dart';
import '../cubit/category_detail_cubit.dart';
import '../data/category_templates.dart';
import '../data/tracker_groups.dart';
import 'tracker_setup_page.dart';
import 'widgets/category_dashboard.dart';
import 'widgets/category_sheets.dart';
import 'widgets/item_sheets.dart';
import 'widgets/meter_sheet.dart';

/// Eine Kategorie mit ihren Trackern – oben die Übersicht (Kennzahlen im gewählten Zeitraum), je
/// Tracker der Verlauf mit der Kennzahl des Jahres und die Einstellungen (Vertrag bzw. Details). Die
/// Hauptaktion „Wert eintragen“ steht fest unten, bei mehreren Trackern fragt sie, wofür (nach Art
/// gruppiert); darunter „Tracker hinzufügen“, bis es weggeklickt wird. Kategorien aus gleichartigen
/// Trackern (Abos, Versicherungen: [ItemTemplate]) zeigen sie als kompakte Liste je Art und bieten
/// statt „Tracker hinzufügen“ dauerhaft „Abo hinzufügen“ an. Der Stift oben bündelt das Bearbeiten: Darstellung,
/// Felder und Einstellungen je Tracker (auch über „Bearbeiten“ am Tracker), Tracker hinzufügen,
/// Archivieren und Löschen. owner und editor bearbeiten, viewer lesen nur.
class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({super.key, required this.categoryId});

  final String categoryId;

  static Future<void> open(BuildContext context, String categoryId) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => CategoryDetailPage(categoryId: categoryId)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<CategoryDetailCubit>(param1: categoryId)..load(), child: const _DetailView());
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  void _onEvent(BuildContext context, CategoryDetailState state) {
    final l10n = context.l10n;
    switch (state.event!.kind) {
      case CategoryDetailEventKind.trackerAdded:
        AppToast.show(context, l10n.detailTrackerAdded);
      case CategoryDetailEventKind.itemAdded:
        AppToast.show(context, l10n.itemAdded(state.event!.name ?? ''));
      case CategoryDetailEventKind.meterAdded:
        AppToast.show(context, l10n.detailMeterAdded);
      case CategoryDetailEventKind.trackerArchived:
        AppToast.show(context, l10n.detailTrackerArchived, icon: CupertinoIcons.archivebox_fill);
      case CategoryDetailEventKind.archived:
        AppToast.show(context, l10n.detailArchived(state.category?.name ?? ''), icon: CupertinoIcons.archivebox_fill);
        Navigator.of(context).pop();
      case CategoryDetailEventKind.restored:
        AppToast.show(context, l10n.categoriesRestored(state.category?.name ?? ''), icon: CupertinoIcons.arrow_counterclockwise);
      case CategoryDetailEventKind.deleted:
        AppToast.show(context, l10n.detailDeleted(state.category?.name ?? ''), icon: CupertinoIcons.trash_fill);
        Navigator.of(context).pop();
      case CategoryDetailEventKind.addTrackerHidden:
        AppToast.show(context, l10n.detailAddTrackerHidden, icon: CupertinoIcons.pencil);
      case CategoryDetailEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<CategoryDetailCubit, CategoryDetailState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, state) => switch ((state.status, state.category)) {
            (CategoryDetailStatus.ready, final Category category) => _Content(category: category, state: state),
            (CategoryDetailStatus.loading, _) => const Center(child: CupertinoActivityIndicator()),
            _ => _Missing(message: state.status == CategoryDetailStatus.failure ? context.l10n.errorLoad : context.l10n.detailMissing),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.category, required this.state});

  final Category category;
  final CategoryDetailState state;

  List<Category> get others => state.others;

  Map<String, YearToDate> get yearToDate => state.yearToDate;

  /// Bauplan für weitere Tracker (Abos, Versicherungen), `null` bei anderen Kategorien.
  ItemTemplate? _item(BuildContext context) => CategoryTemplates.item(context.l10n, category.templateKey);

  /// Stift oben: Menü „Kategorie bearbeiten“, die Auswahl führt diese Seite aus.
  Future<void> _edit(BuildContext context) async {
    final choice = await CategoryMenuSheet.show(context, category, addLabel: _item(context)?.add);
    if (!context.mounted) return;
    switch (choice) {
      case CategoryMenuAppearance():
        await _editAppearance(context);
      case CategoryMenuTrackerSetup(:final trackerId):
        await TrackerSetupPage.open(context, categoryId: category.id, trackerId: trackerId);
      case CategoryMenuAddTracker():
        await _addTracker(context);
      case CategoryMenuArchive():
        await _archive(context);
      case CategoryMenuDelete():
        await _delete(context);
      case null:
        break;
    }
  }

  Future<void> _editAppearance(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    if (await CategoryEditSheet.show(context, category) case CategoryEdited(:final name, :final icon, :final swatch)) {
      await cubit.updateAppearance(name: name, icon: icon, swatch: swatch);
    }
  }

  /// Mit Bauplan ein fertiges Abo (eine Versicherung) anlegen, sonst einen leeren Tracker mit Namen.
  Future<void> _addTracker(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    if (_item(context) case final ItemTemplate item) {
      if (await ItemSheet.show(context, item: item, category: category) case final ItemDraft draft) await cubit.addItem(item, draft);
      return;
    }
    if (await TrackerSheet.show(context) case TrackerRenamed(:final name)) await cubit.addTracker(name);
  }

  Future<void> _archive(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.detailArchiveTitle(category.name),
      message: l10n.detailArchiveBody,
      confirmLabel: l10n.actionArchive,
      destructive: true,
    );
    if (confirmed) await cubit.archive();
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.detailDeleteTitle(category.name),
      message: category.isShared ? l10n.detailDeleteBodyShared : l10n.detailDeleteBody,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (confirmed) await cubit.delete();
  }

  /// Wert eintragen: direkt beim einzigen Tracker, sonst erst den Tracker wählen (nach Art gruppiert).
  Future<void> _addEntry(BuildContext context, List<Tracker> trackers) async {
    final tracker = trackers.length == 1
        ? trackers.single
        : await TrackerPickerSheet.show(context, trackers: trackers, order: _item(context)?.groupNames ?? const []);
    if (tracker != null && context.mounted) await EntryFormPage.open(context, category: category, tracker: tracker);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final editable = category.canEdit;
    // Ein Zähler aus der Vorlage wird erst angelegt, dann eingetragen. Gilt das für alle Tracker,
    // ist „Zähler hinzufügen“ die einzige Aktion – Übersicht, Verlauf und Preise kommen danach.
    final setup = editable ? [for (final t in category.trackers) if (MeterSheet.needsSetup(context, t)) t] : const <Tracker>[];
    final setupOnly = setup.isNotEmpty && setup.length == category.trackers.length;
    final addable = [for (final t in category.trackers) if (t.entryFields.isNotEmpty && !setup.contains(t)) t];
    final today = DateTime.now();
    final item = _item(context);
    final canAddEntry = editable && addable.isNotEmpty;
    // Ohne Tracker ist „Tracker hinzufügen“ die Hauptaktion und lässt sich nicht wegklicken, ebenso
    // „Abo hinzufügen“ in Kategorien aus gleichartigen Trackern.
    final noTrackers = category.trackers.isEmpty;
    final keepAddTracker = noTrackers || item != null;
    final showAddTracker = editable && !setupOnly && (keepAddTracker || category.dashboard.showAddTracker);
    final hasAction = canAddEntry || showAddTracker || setupOnly;
    return AppActionBar(
      action: hasAction
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spacing.s,
              children: [
                if (setupOnly) AppButton(label: l10n.meterAdd, icon: CupertinoIcons.plus, onPressed: () => _setUpMeter(context, category, setup.first)),
                if (canAddEntry) AppButton(label: l10n.trackerAddEntry, icon: CupertinoIcons.plus, onPressed: () => _addEntry(context, addable)),
                if (showAddTracker)
                  Row(
                    spacing: Spacing.s,
                    children: [
                      Expanded(
                        child: AppButton(
                          label: item?.add ?? l10n.detailAddTracker,
                          icon: CupertinoIcons.plus,
                          variant: canAddEntry ? AppButtonVariant.tinted : AppButtonVariant.filled,
                          onPressed: () => _addTracker(context),
                        ),
                      ),
                      if (!keepAddTracker)
                        AppIconButton(
                          icon: CupertinoIcons.xmark,
                          semanticLabel: l10n.detailAddTrackerHide,
                          onPressed: () => context.read<CategoryDetailCubit>().hideAddTracker(),
                        ),
                    ],
                  ),
              ],
            )
          : null,
      content: ListView(
        padding: EdgeInsets.only(bottom: hasAction ? AppActionBar.inset(context) : MediaQuery.paddingOf(context).bottom + Spacing.xxl),
        children: [
          AppHeader(
            title: category.name,
            overline: category.isShared ? l10n.homeSharedWith(context.memberNames(category.sharedWith)) : null,
            onBack: () => Navigator.of(context).pop(),
            actions: [
              AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch), size: Sizes.iconTileLarge),
              AppIconButton(
                icon: CupertinoIcons.person_2_fill,
                semanticLabel: l10n.shareTitle,
                onPressed: () async {
                  if (await CloudFlow.require(context, l10n.cloudRequiredShare) && context.mounted) await SharePage.open(context, category.id);
                },
              ),
              if (editable) AppIconButton(icon: CupertinoIcons.pencil, semanticLabel: l10n.detailEditCategory, onPressed: () => _edit(context)),
            ],
          ),
          if (category.isArchived)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.s),
              child: AppText(l10n.detailArchivedNote, style: (t) => t.footnote, color: c.textSecondary),
            ),
          if (!editable)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.s),
              child: AppText(
                category.sharedBy == null ? l10n.detailReadOnlyUnknown : l10n.detailReadOnly(category.sharedBy!.name),
                style: (t) => t.footnote,
                color: c.textSecondary,
              ),
            ),
          if (category.trackers.isNotEmpty && !setupOnly) ...[CategoryDashboardSection(category: category, state: state), const SizedBox(height: Spacing.s)],
          if (category.trackers.isEmpty || setupOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.xxl, Spacing.xxxl, Spacing.xxl, Spacing.l),
              child: Column(
                spacing: Spacing.s,
                children: [
                  AppText(setupOnly ? l10n.meterSetupTitle : item?.emptyTitle ?? l10n.detailNoTrackersTitle, style: (t) => t.title3, align: TextAlign.center),
                  AppText(
                    setupOnly ? l10n.meterSetupBody : item?.emptyBody ?? l10n.detailNoTrackersBody,
                    style: (t) => t.subheadline,
                    color: c.textSecondary,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          if (item != null) _ItemList(category: category, item: item, today: today),
          for (final tracker in setupOnly || item != null ? const <Tracker>[] : category.trackers) ...[
            SectionHeader(
              title: tracker.name,
              action: editable && !setup.contains(tracker) ? l10n.actionEdit : null,
              onAction: () => TrackerSetupPage.open(context, categoryId: category.id, trackerId: tracker.id),
            ),
            _TrackerGroup(
              category: category,
              tracker: tracker,
              yearToDate: yearToDate[tracker.id],
              includedIn: others.where((o) => o.id == tracker.includedIn).firstOrNull,
            ),
            if (setup.contains(tracker))
              const SizedBox.shrink()
            else if (tracker.isUtilityMeter) ...[
              const SizedBox(height: Spacing.m),
              ContractGroup(
                category: category,
                tracker: tracker,
                contract: TrackerHistory.contractOf(tracker, today),
                onSaveDetail: (field, value) => context.read<CategoryDetailCubit>().saveDetail(tracker, field, value),
              ),
            ] else if (tracker.detailFields.isNotEmpty) ...[
              const SizedBox(height: Spacing.m),
              TrackerDetailsGroup(
                tracker: tracker,
                onSave: editable ? (field, value) => context.read<CategoryDetailCubit>().saveDetail(tracker, field, value) : null,
              ),
            ],
          ],
          // Archivieren und Löschen stehen im Menü hinter dem Stift, Wiederherstellen hier sichtbar.
          if (category.isOwner && category.isArchived)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
              child: AppButton(
                label: l10n.categoriesRestore,
                icon: CupertinoIcons.arrow_counterclockwise,
                variant: AppButtonVariant.tinted,
                onPressed: context.read<CategoryDetailCubit>().restore,
              ),
            ),
        ],
      ),
    );
  }
}

/// Ersten Zähler anlegen: Der Zähler aus der Vorlage bekommt Ort, Gruppe und Namen.
Future<void> _setUpMeter(BuildContext context, Category category, Tracker tracker) async {
  final cubit = context.read<CategoryDetailCubit>();
  final meter = tracker.meter!;
  final result = await MeterSheet.show(context, category: category, tracker: tracker, meter: meter, setup: true);
  if (result != null) await cubit.setUpMeter(meter, name: result.meter.name, group: result.meter.group);
}

/// Daten eines Trackers: Verlauf (mit Kosten oder Verbrauch des Jahres), ohne Felder dazu „Felder
/// festlegen“. Ein Versorgungszähler listet seine Zähler mit dem letzten Stand und bietet „Weiteren
/// Zähler hinzufügen“ an – ist der erste noch nicht angelegt, nur „Zähler hinzufügen“. Eingetragen
/// wird über die Hauptaktion unten.
class _TrackerGroup extends StatelessWidget {
  const _TrackerGroup({required this.category, required this.tracker, this.yearToDate, this.includedIn});

  /// Darunter zeigt die Zeile keine Kennzahl (noch nichts angefallen).
  static const _minValue = 0.5;

  final Category category;
  final Tracker tracker;
  final YearToDate? yearToDate;
  final Category? includedIn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final swatch = c.swatch(category.swatch);
    if (category.canEdit && MeterSheet.needsSetup(context, tracker)) {
      return AppListGroup(
        children: [
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.add, color: c.accent),
            title: l10n.meterAdd,
            subtitle: l10n.meterSetupHint,
            onTap: () => _setUpMeter(context, category, tracker),
          ),
        ],
      );
    }
    final figure = switch (yearToDate) {
      final YearToDate y when y.value.abs() >= _minValue => y.metric == HistoryMetric.cost ? context.euros(y.value) : context.amount(y.value, y.unit),
      _ => null,
    };
    return AppListGroup(
      children: [
        AppListRow(
          leading: AppIconTile(icon: CupertinoIcons.chart_bar_fill, color: swatch),
          title: l10n.trackerHistory,
          subtitle: context.joinParts([l10n.categoryEntries(tracker.records.where((e) => !tracker.isPriceChange(e)).length), if (includedIn != null) l10n.trackerIncludedNote(includedIn!.name)]),
          trailing: figure == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 2,
                  children: [
                    AppText(figure, style: (t) => t.numberM),
                    AppText(l10n.trackerThisYear('${DateTime.now().year}'), style: (t) => t.caption, color: c.textSecondary),
                  ],
                ),
          onTap: () => TrackerPage.open(context, categoryId: category.id, trackerId: tracker.id),
        ),
        if (category.canEdit && tracker.fields.isEmpty)
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.slider_horizontal_3, color: c.accent),
            title: l10n.trackerSetUpFields,
            onTap: () => TrackerSetupPage.open(context, categoryId: category.id, trackerId: tracker.id),
          ),
        if (tracker.isUtilityMeter) ...[
          for (final meter in tracker.meters)
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.gauge, color: swatch),
              title: meter.name,
              subtitle: context.joinParts([?meter.meterGroup, ?_lastReading(context, meter)]),
              chevron: category.canEdit,
              onTap: category.canEdit ? () => _editMeter(context, meter) : null,
            ),
          if (category.canEdit)
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.add, color: c.accent),
              title: l10n.meterAddAnother,
              subtitle: tracker.meters.length == 1 ? l10n.meterAddHint : null,
              onTap: () => _addMeter(context),
            ),
        ],
      ],
    );
  }

  /// Letzter Stand des Zählers mit Datum, `null` ohne Stand.
  String? _lastReading(BuildContext context, FieldDefinition meter) {
    Entry? latest;
    for (final e in tracker.entries) {
      if (tracker.isBill(e) || e.number(meter.id) == null) continue;
      if (latest == null || e.date.isAfter(latest.date)) latest = e;
    }
    if (latest == null) return null;
    return '${context.fieldValue(meter, latest.number(meter.id)!)} · ${context.shortDate(latest.date)}';
  }

  Future<void> _addMeter(BuildContext context) async {
    final cubit = context.read<CategoryDetailCubit>();
    final result = await MeterSheet.show(context, category: category, tracker: tracker);
    if (result == null) return;
    await cubit.addMeter(
      tracker,
      name: result.meter.name,
      group: result.meter.group,
      first: result.first == null ? null : (name: result.first!.name, group: result.first!.group),
    );
  }

  Future<void> _editMeter(BuildContext context, FieldDefinition meter) async {
    final cubit = context.read<CategoryDetailCubit>();
    final result = await MeterSheet.show(context, category: category, tracker: tracker, meter: meter);
    if (result != null) await cubit.updateMeter(meter, name: result.meter.name, group: result.meter.group);
  }
}

/// Abos (Versicherungen …) kompakt: je Art eine Gruppe, je Abo eine Zeile mit Betrag und Stichtag;
/// Verlauf, Details und Einstellungen liegen hinter der Zeile auf der Tracker-Seite.
class _ItemList extends StatelessWidget {
  const _ItemList({required this.category, required this.item, required this.today});

  final Category category;
  final ItemTemplate item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final groups = groupTrackers(category.trackers, order: item.groupNames);
    final named = groups.any((g) => g.name != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          SectionHeader(title: group.name ?? (named ? l10n.itemOtherGroup : item.listTitle)),
          AppListGroup(
            children: [
              for (final tracker in group.trackers)
                AppListRow(
                  leading: AppIconTile(icon: category.icon.data, color: c.swatch(category.swatch)),
                  title: tracker.name,
                  subtitle: _deadline(context, tracker) ?? (tracker.currentAmount(today) == null ? l10n.itemNoAmount : null),
                  trailing: switch (tracker.currentAmount(today)) {
                    (final field, final value) => AppText(context.fieldValue(field, value), style: (t) => t.numberM, maxLines: 1),
                    null => null,
                  },
                  onTap: () => TrackerPage.open(context, categoryId: category.id, trackerId: tracker.id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Erster gesetzter Stichtag („Kündbar bis 1.3.2027“), `null` ohne.
  String? _deadline(BuildContext context, Tracker tracker) {
    for (final field in tracker.withRole(FieldRole.deadline)) {
      if (tracker.detailValue(field.id) case final DateTime date) return context.l10n.itemDeadline(field.name, context.shortDate(date));
    }
    return null;
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(title: '', onBack: () => Navigator.of(context).pop()),
        Expanded(
          child: Center(
            child: Padding(
              padding: Spacing.screen,
              child: AppText(message, style: (t) => t.body, color: context.colors.textSecondary, align: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}
