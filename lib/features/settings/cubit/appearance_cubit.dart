import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/appearance_store.dart';

/// Darstellung der App: wie das Gerät ([ThemeMode.system]), immer hell oder immer dunkel.
/// Liegt über dem `MaterialApp`, damit jede Seite und jedes Sheet mitwechselt.
class AppearanceCubit extends Cubit<ThemeMode> {
  AppearanceCubit(this._store) : super(ThemeMode.system);

  final AppearanceStore _store;
  var _chosen = false;

  Future<void> load() async {
    final mode = await _store.read();
    // Hat jemand schon gewählt, während gelesen wurde, gilt die neue Wahl.
    if (mode != null && !_chosen && !isClosed) emit(mode);
  }

  Future<void> select(ThemeMode mode) async {
    _chosen = true;
    if (mode == state) return;
    emit(mode);
    await _store.write(mode);
  }
}
