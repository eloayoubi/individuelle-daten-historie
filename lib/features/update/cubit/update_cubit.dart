import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/app_release.dart';
import '../data/installed_app.dart';

part 'update_state.dart';

/// Pflicht-Update: Gibt es auf dem Vertriebsweg des laufenden Builds einen neueren, sperrt
/// `ForceUpdateGate` die App, bis das Update installiert ist. Geprüft beim Start und bei jeder
/// Rückkehr in die App. Gesperrt wird nur, wenn der Server einen neueren Build bestätigt – ohne Netz
/// bleibt alles, wie es ist.
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit(this._repository, this._installed) : super(const UpdateState());

  final ReleaseRepository _repository;
  final Future<InstalledApp> Function() _installed;

  Future<void> check() async {
    try {
      final installed = state.installed ?? await _installed();
      final channel = installed.channel;
      final latest = channel == null ? null : await _repository.latest(channel);
      if (!isClosed) emit(UpdateState(installed: installed, release: latest != null && latest.build > installed.build ? latest : null));
    } catch (_) {
      // Ohne Netz oder Antwort: nichts ändern.
    }
  }
}
