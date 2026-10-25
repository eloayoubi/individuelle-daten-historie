part of 'storage_cubit.dart';

/// Was gerade umzieht – für die Anzeige während des Wartens.
enum StorageTransferKind { upload, download }

enum StorageEventKind {
  /// Lokal gewählt.
  local,

  /// In der Cloud, ohne Daten vom Gerät.
  cloud,

  /// In der Cloud, Gerätedaten hochgeladen.
  uploaded,

  /// Cloud-Daten aufs Gerät geholt, jetzt lokal.
  downloaded,

  /// Im Konto liegen schon Daten: Gerätedaten dazunehmen?
  askUpload,

  /// Umzug unterbrochen (meist kein Netz); nichts ist verloren, der Speicherort bleibt.
  failed,
}

/// Einmaliges Ereignis für Toasts und Folgeschritte. Bewusst nicht `const`.
class StorageEvent {
  StorageEvent(this.kind);

  final StorageEventKind kind;
}

class StorageState extends Equatable {
  const StorageState({this.mode, this.transfer, this.event});

  /// `null`, bis der Nutzer auf dem Start-Bildschirm wählt.
  final StorageMode? mode;
  final StorageTransferKind? transfer;
  final StorageEvent? event;

  bool get isCloud => mode == StorageMode.cloud;

  bool get busy => transfer != null;

  StorageState copyWith({StorageMode? Function()? mode, StorageTransferKind? Function()? transfer, StorageEvent? event}) => StorageState(
    mode: mode == null ? this.mode : mode(),
    transfer: transfer == null ? this.transfer : transfer(),
    event: event,
  );

  @override
  List<Object?> get props => [mode, transfer, event];
}
