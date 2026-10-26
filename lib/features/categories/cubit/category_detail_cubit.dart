import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/cost_engine.dart';
import '../../../core/utils/dashboard_figures.dart';
import '../../../core/utils/ids.dart';
import '../../entries/data/tracker_history.dart';
import '../data/categories_repository.dart';
import '../data/category_templates.dart';
import '../data/tracker_details.dart';

part 'category_detail_state.dart';

/// Eine Kategorie mit ihren Trackern: Kennzahlen der Übersicht im gewählten Zeitraum, Kennzahl des
/// Jahres je Tracker, Details setzen, Aussehen und Übersicht ändern, Tracker anlegen, umbenennen,
/// archivieren, Kategorie archivieren, wiederherstellen und löschen. Lädt bei jeder
/// Änderung im Repository neu. Auch die Felder-Seite eines Trackers nutzt diesen Cubit.
class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  CategoryDetailCubit(this._repository, this.categoryId, {DateTime Function()? now}) : _now = now ?? DateTime.now, super(const CategoryDetailState()) {
    _subscription = _repository.changes.listen((_) => load());
  }

  final CategoriesRepository _repository;
  final String categoryId;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;

  /// Während des Löschens nicht neu laden – die Seite zeigte sonst kurz „gibt es nicht mehr“.
  var _deleting = false;

  Future<void> load() async {
    if (_deleting) return;
    try {
      final category = await _repository.loadCategory(categoryId);
      final others = [for (final c in await _repository.loadCategories()) if (c.id != categoryId && !c.isArchived) c];
      if (isClosed) return;
      final now = _now();
      emit(
        _withFigures(
          state.copyWith(
            status: category == null ? CategoryDetailStatus.missing : CategoryDetailStatus.ready,
            category: category,
            others: others,
            yearToDate: {
              for (final t in category?.trackers ?? const <Tracker>[])
                if (TrackerHistory.yearToDate(t, now) case final YearToDate value) t.id: value,
            },
          ),
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(status: state.category == null ? CategoryDetailStatus.failure : state.status));
    }
  }

  /// Zeitraum der Kennzahlen; [custom] bei [DashboardPeriod.custom] (letzter Tag eingeschlossen).
  void setPeriod(DashboardPeriod period, {DateTime? from, DateTime? to}) {
    final custom = period == DashboardPeriod.custom && from != null && to != null
        ? DateSpan(from.isAfter(to) ? to : from, (from.isAfter(to) ? from : to).add(const Duration(days: 1)))
        : state.custom;
    emit(_withFigures(state.copyWith(period: period, custom: () => custom)));
  }

  /// Gezeigte Kennzahlen (`null` = automatisch).
  Future<void> setMetrics(List<DashboardMetric>? metrics) async {
    final category = state.category;
    if (category == null) return;
    await _run(() => _repository.updateDashboard(categoryId, category.dashboard.copyWith(metrics: () => metrics)));
  }

  /// „Tracker hinzufügen“ unter „Wert eintragen“ wegklicken; danach geht es über „Bearbeiten“.
  Future<void> hideAddTracker() async {
    final category = state.category;
    if (category == null) return;
    await _run(
      () => _repository.updateDashboard(categoryId, category.dashboard.copyWith(showAddTracker: false)),
      success: CategoryDetailEventKind.addTrackerHidden,
    );
  }

  /// Kennzahlen zum Zustand [s] neu rechnen (nach Laden oder neuem Zeitraum).
  CategoryDetailState _withFigures(CategoryDetailState s) {
    final category = s.category;
    if (category == null) return s;
    final today = _now();
    final span = DashboardFigures.span(s.period, today, custom: s.custom, firstDay: DashboardFigures.firstDay(category));
    final previous = DashboardFigures.previous(s.period, span);
    return s.copyWith(
      span: span,
      figures: DashboardFigures.build(category, span, previous: previous, today: today, elsewhere: {for (final o in s.others) o.id}),
    );
  }

  Future<void> updateAppearance({required String name, required CategoryIcon icon, required CategorySwatch swatch}) =>
      _run(() => _repository.updateCategory(categoryId, name: name.trim(), icon: icon, swatch: swatch));

  Future<void> addTracker(String name) =>
      _run(() => _repository.createTracker(categoryId, name.trim(), sort: state.category?.trackers.length ?? 0), success: CategoryDetailEventKind.trackerAdded);

  /// Neuer Tracker nach dem Bauplan [item] (ein Abo, eine Versicherung): Felder anlegen, den Betrag
  /// ab [ItemDraft.since] eintragen und die Art als Detail setzen.
  Future<void> addItem(ItemTemplate item, ItemDraft draft) => _run(() async {
    final name = draft.name.trim();
    final trackerId = await _repository.createTracker(categoryId, name, sort: state.category?.trackers.length ?? 0);
    final fields = item.draftFields(interval: draft.interval);
    final ids = [for (final (i, f) in fields.indexed) await _repository.createField(trackerId, f, sort: i)];
    if (draft.amount case final double amount) {
      await _repository.saveEntry(trackerId, Entry(id: newId(), date: CostEngine.day(draft.since), values: {ids.first: amount}));
    }
    if (draft.group case final String group when fields.last.kind == FieldKind.choice) {
      await _repository.saveEntry(trackerId, Entry(id: newId(), date: CostEngine.day(_now()), values: {ids.last: group}));
    }
  }, success: CategoryDetailEventKind.itemAdded, name: draft.name.trim());

  /// Weiterer Zähler im Tracker (Bad warm neben Bad kalt): Einheit, Umrechnung und Auswertung wie
  /// beim ersten Zähler, sein Verbrauch zählt mit dem der anderen zusammen. [first] benennt dabei den
  /// bisherigen ersten Zähler um und gibt ihm eine Gruppe.
  Future<void> addMeter(Tracker tracker, {required String name, String? group, ({String name, String? group})? first}) => _run(() async {
    final template = tracker.meter!;
    if (first != null) await _repository.updateField(template.id, FieldDraft.of(template).asMeter(name: first.name, group: first.group));
    final draft = FieldDraft.of(template).asMeter(name: name, group: group);
    await _repository.createField(tracker.id, draft, sort: tracker.fields.length);
  }, success: CategoryDetailEventKind.meterAdded);

  /// Name und Gruppe eines Zählers ändern.
  Future<void> updateMeter(FieldDefinition meter, {required String name, String? group}) =>
      _run(() => _repository.updateField(meter.id, FieldDraft.of(meter).asMeter(name: name, group: group)));

  Future<void> renameTracker(String trackerId, String name) => _run(() => _repository.renameTracker(trackerId, name.trim()));

  /// Name und „Kosten enthalten in“ – nur, was sich geändert hat.
  Future<void> updateTracker(Tracker tracker, {required String name, String? includedIn}) => _run(() async {
    if (name.trim() != tracker.name) await _repository.renameTracker(tracker.id, name.trim());
    if (includedIn != tracker.includedIn) await _repository.setTrackerIncludedIn(tracker.id, includedIn);
  });

  /// Detail setzen ([value] `null` entfernt es).
  Future<void> saveDetail(Tracker tracker, FieldDefinition field, Object? value) => _run(() => _repository.saveDetail(tracker, field, value, now: _now()));

  Future<void> archiveTracker(String trackerId) => _run(() => _repository.archiveTracker(trackerId), success: CategoryDetailEventKind.trackerArchived);

  Future<void> archive() => _run(() => _repository.setCategoryArchived(categoryId, archived: true), success: CategoryDetailEventKind.archived);

  Future<void> restore() => _run(() => _repository.setCategoryArchived(categoryId, archived: false), success: CategoryDetailEventKind.restored);

  Future<void> delete() async {
    _deleting = true;
    await _run(() => _repository.deleteCategory(categoryId), success: CategoryDetailEventKind.deleted);
    if (!isClosed && state.event?.kind != CategoryDetailEventKind.deleted) {
      _deleting = false;
      await load();
    }
  }

  Future<void> _run(Future<void> Function() write, {CategoryDetailEventKind? success, String? name}) async {
    try {
      await write();
      if (!isClosed && success != null) emit(state.copyWith(event: CategoryDetailEvent(success, name: name)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(event: CategoryDetailEvent(CategoryDetailEventKind.failed)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
