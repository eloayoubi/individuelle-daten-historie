import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/plus_repository.dart';
import '../data/plus_store.dart';

part 'plus_state.dart';

/// Kostenkurve Plus: Stand, Preise, Kaufen, Wiederherstellen. Liegt über dem `MaterialApp`, weil
/// Belege, Paywall und Einstellungen denselben Stand brauchen.
class PlusCubit extends Cubit<PlusState> {
  PlusCubit(this._repository, this._store) : super(PlusState(supported: _store.supported)) {
    _subscription = _store.updates.listen(_onUpdate);
  }

  final PlusRepository _repository;
  final PlusStore _store;
  late final StreamSubscription<PlusStoreUpdateKind> _subscription;
  var _restoring = false;

  static const restoreTimeout = Duration(seconds: 10);

  Future<void> load() async {
    try {
      final status = await _repository.status();
      if (!isClosed) emit(state.copyWith(status: status, loaded: true));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loaded: true));
    }
    try {
      final prices = await _store.prices();
      if (!isClosed) emit(state.copyWith(prices: prices));
    } catch (_) {
      // Ohne Store (z. B. Simulator ohne StoreKit-Datei) bleibt die Paywall ohne Preise.
    }
  }

  Future<void> buy(String productId) async {
    emit(state.copyWith(busy: true));
    try {
      await _store.buy(productId);
    } catch (_) {
      if (!isClosed) emit(state.copyWith(busy: false, event: PlusEvent(PlusStoreUpdateKind.failed)));
    }
  }

  /// Wiederhergestellte Käufe kommen einzeln über den Store-Strom – ohne Käufe kommt nichts.
  /// Darum auf das erste Ergebnis warten (höchstens [restoreTimeout]) und dann den Stand lesen.
  Future<void> restore() async {
    emit(state.copyWith(busy: true));
    _restoring = true;
    try {
      final first = _store.updates
          .firstWhere((k) => k != PlusStoreUpdateKind.pending)
          .timeout(restoreTimeout, onTimeout: () => PlusStoreUpdateKind.expired);
      await _store.restore();
      var kind = await first;
      final status = await _repository.status();
      if (status.active) kind = PlusStoreUpdateKind.unlocked;
      if (!isClosed) emit(state.copyWith(busy: false, status: status, event: PlusEvent(kind)));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(busy: false, event: PlusEvent(PlusStoreUpdateKind.failed)));
    } finally {
      _restoring = false;
    }
  }

  Future<void> _onUpdate(PlusStoreUpdateKind kind) async {
    // Während des Wiederherstellens meldet restore() das Ergebnis.
    if (_restoring) return;
    var status = state.status;
    if (kind == PlusStoreUpdateKind.unlocked || kind == PlusStoreUpdateKind.expired) {
      status = await _repository.status().catchError((Object _) => state.status);
    }
    if (!isClosed) emit(state.copyWith(busy: false, status: status, event: PlusEvent(kind)));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
