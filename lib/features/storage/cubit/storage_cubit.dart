import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_repository.dart';
import '../data/storage_mode.dart';
import '../data/storage_transfer.dart';

part 'storage_state.dart';

/// Speicherort: lokal wählen, Cloud aktivieren (mit Umzug der Gerätedaten), aufs Gerät holen.
/// Liegt über dem `MaterialApp`, weil Start, Paywall, Einstellungen und Belege denselben Stand
/// brauchen. Die Methoden liefern ihr Ergebnis zusätzlich zum Ereignis, damit der Aufrufer
/// nachfragen kann ([StorageEventKind.askUpload]).
class StorageCubit extends Cubit<StorageState> {
  StorageCubit(this._mode, this._transfer, this._auth) : super(StorageState(mode: _mode.mode)) {
    _modes = _mode.changes.listen((mode) {
      if (!isClosed) emit(state.copyWith(mode: () => mode));
    });
    _accounts = _auth.accountChanges.listen((account) {
      // Abgemeldet oder Konto gelöscht: Ohne Konto keine Cloud – zurück zum Start-Bildschirm.
      if (account.userId == null && _mode.mode == StorageMode.cloud) unawaited(_mode.set(null));
    });
  }

  final StorageModeStore _mode;
  final StorageTransfer _transfer;
  final AuthRepository _auth;
  late final StreamSubscription<StorageMode?> _modes;
  late final StreamSubscription<AccountInfo> _accounts;

  /// Beim Start: Cloud ohne Konto (Sitzung abgelaufen oder entfernt) führt zum Start-Bildschirm.
  /// Ein anonymes Konto aus der Testphase, dessen Daten schon auf dem Gerät liegen, wird gelöscht
  /// (das hat beim Wechsel nach „Lokal“ ohne Netz nicht geklappt).
  Future<void> load() async {
    if (_mode.mode == StorageMode.cloud && _auth.userId == null) return _mode.set(null);
    if (_mode.mode == StorageMode.local && _auth.userId != null && _auth.account.isAnonymous) {
      await _auth.deleteAccount().catchError((Object _) {});
    }
  }

  /// „Kostenlos lokal nutzen“. Ist ein Konto angemeldet (Testphase oder gerade registriert), kommen
  /// seine Cloud-Daten mit aufs Gerät; ein anonymes Konto wäre danach unerreichbar und wird gelöscht.
  Future<StorageEventKind> chooseLocal() => _run(StorageTransferKind.download, () async {
    if (_auth.userId != null) {
      await _transfer.download();
      if (_auth.account.isAnonymous) await _auth.deleteAccount().catchError((Object _) {});
    }
    await _mode.set(StorageMode.local);
    return StorageEventKind.local;
  });

  /// In die Cloud wechseln, sobald das Abo läuft. Daten vom Gerät ziehen mit um; liegen im Konto
  /// schon Daten, fragt die App erst ([StorageEventKind.askUpload], dann erneut mit [upload]).
  /// `upload: false` lässt die Gerätedaten liegen.
  Future<StorageEventKind> activateCloud({bool? upload}) => _run(StorageTransferKind.upload, () async {
    if (await _transfer.localHasData()) {
      if (upload == null && await _transfer.cloudHasData()) return StorageEventKind.askUpload;
      if (upload != false) {
        await _transfer.upload();
        await _mode.set(StorageMode.cloud);
        return StorageEventKind.uploaded;
      }
    }
    await _mode.set(StorageMode.cloud);
    return StorageEventKind.cloud;
  });

  /// Cloud → Gerät, danach lokal und kostenlos. Das Konto bleibt angemeldet (Abo später wieder möglich).
  Future<StorageEventKind> moveToLocal() => _run(StorageTransferKind.download, () async {
    await _transfer.download();
    await _mode.set(StorageMode.local);
    return StorageEventKind.downloaded;
  });

  Future<StorageEventKind> _run(StorageTransferKind transfer, Future<StorageEventKind> Function() action) async {
    emit(state.copyWith(transfer: () => transfer));
    StorageEventKind result;
    try {
      result = await action();
    } catch (_) {
      result = StorageEventKind.failed;
    }
    if (!isClosed) emit(state.copyWith(transfer: () => null, event: StorageEvent(result)));
    return result;
  }

  @override
  Future<void> close() async {
    await _modes.cancel();
    await _accounts.cancel();
    return super.close();
  }
}
