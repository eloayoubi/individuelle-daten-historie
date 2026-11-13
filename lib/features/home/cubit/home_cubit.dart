import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/json_store.dart';
import '../../categories/data/categories_repository.dart';
import '../../radar/data/radar.dart';
import '../../radar/data/radar_store.dart';
import '../data/home_categories_store.dart';
import '../data/home_overview.dart';

part 'home_state.dart';

/// Lädt alle Kategorien und rechnet daraus die Übersicht: Kosten bis heute, Prognose fürs
/// nächste Jahr, die Funde des Radars, die gewählten Kategorien und was als Nächstes ansteht – dazu
/// den Stand der Offline-Warteschlange.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._categories, {HomeCategoriesStore? pins, RadarStore? radar, DateTime Function()? now})
    : _pins = pins ?? HomeCategoriesStore(MemoryJsonStore()),
      _radar = radar ?? RadarStore(MemoryJsonStore()),
      _now = now ?? DateTime.now,
      super(const HomeState()) {
    // Neue oder geänderte Kategorien (z. B. aus dem Kategorien-Tab) sofort übernehmen.
    _subscription = _categories.changes.listen((_) => load());
  }

  final CategoriesRepository _categories;
  final HomeCategoriesStore _pins;
  final RadarStore _radar;
  final DateTime Function() _now;
  late final StreamSubscription<void> _subscription;
  bool _pinsLoaded = false;

  /// Ausgeblendete Funde und die zuletzt geladenen Kategorien – „Ausblenden“ rechnet daraus neu.
  Set<String>? _dismissed;
  List<Category> _loaded = const [];

  Future<void> load() async {
    // Vorhandene Übersicht bleibt beim Neuladen stehen; nur nach einem Fehler wieder „lädt“.
    if (state.overview == null && state.status != HomeStatus.loading) emit(state.copyWith(status: HomeStatus.loading));
    try {
      // Auswahl und Ausgeblendetes nur beim ersten Laden aus dem Speicher. Danach gilt der Stand im
      // Cubit zum Zeitpunkt des Emit: Wählt, verschiebt oder blendet der Nutzer aus, während der Abruf
      // läuft, überschriebe ihn sonst der Stand von davor.
      final stored = _pinsLoaded ? null : await _pins.load();
      _pinsLoaded = true;
      _dismissed ??= await _radar.load();
      final categories = [for (final c in await _categories.loadCategories()) if (!c.isArchived) c];
      if (isClosed) return;
      _loaded = categories;
      final now = _now();
      emit(
        state.copyWith(
          status: HomeStatus.ready,
          overview: HomeOverview.build(categories, now),
          radar: _buildRadar(categories, now, _dismissed ?? const {}),
          sync: _categories.syncState,
          pinned: stored,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(status: HomeStatus.failure, sync: _categories.syncState));
    }
  }

  /// Kategorien der Übersicht festlegen (Auswahl unter „Kategorie hinzufügen“ bzw. „Bearbeiten“).
  Future<void> setPinned(List<String> ids) async {
    emit(state.copyWith(pinned: [...ids], reordering: false));
    await _pins.save(ids);
  }

  /// Verschiebe-Modus an (langes Halten) bzw. aus („Fertig“).
  void setReordering(bool on) => emit(state.copyWith(reordering: on && state.shown.length > 1));

  /// Gezeigte Kategorie von [oldIndex] nach [newIndex] (Zielposition nach dem Herausnehmen, wie
  /// `onReorderItem`). Gewählte, gerade archivierte Kategorien bleiben hinten in der Auswahl.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final shown = [for (final s in state.shown) s.category.id];
    if (oldIndex < 0 || oldIndex >= shown.length) return;
    final moved = shown.removeAt(oldIndex);
    shown.insert(newIndex.clamp(0, shown.length), moved);
    final ids = [...shown, for (final id in state.pinned) if (!shown.contains(id)) id];
    emit(state.copyWith(pinned: ids));
    await _pins.save(ids);
  }

  /// Alle Funde des Radars zeigen („Alle“) bzw. wieder nur die ersten („Weniger“).
  void setRadarExpanded(bool expanded) => emit(state.copyWith(radarExpanded: expanded));

  /// Fund ausblenden, je Gerät gemerkt. Er kommt wieder, sobald sich die Lage ändert ([Finding.id]).
  Future<void> dismissFinding(String id) async {
    if (isClosed) return;
    final dismissed = _dismissed = {...?_dismissed, id};
    final radar = _buildRadar(_loaded, _now(), dismissed);
    emit(state.copyWith(radar: radar, radarExpanded: state.radarExpanded && radar.findings.length > HomeState.radarPreview));
    try {
      await _radar.dismiss(id);
    } catch (_) {
      // Speichern gescheitert (Speicher voll): Der Fund bleibt bis zum nächsten Start ausgeblendet.
    }
  }

  /// Das Radar ist eine Zugabe: Scheitert es an unerwarteten Daten, bleibt es leer – die Übersicht
  /// lädt trotzdem.
  static Radar _buildRadar(List<Category> categories, DateTime now, Set<String> dismissed) {
    try {
      return Radar.build(categories, now, dismissed: dismissed);
    } catch (_) {
      return Radar(today: now);
    }
  }

  /// Hinweis auf abgelehnte Einträge ausblenden.
  void acknowledgeRejected() => _categories.acknowledgeRejected();

  /// Zurückgehaltene Einträge aufgeben (nach Rückfrage in der Ansicht).
  Future<void> discardHeld() => _categories.discardHeld();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
