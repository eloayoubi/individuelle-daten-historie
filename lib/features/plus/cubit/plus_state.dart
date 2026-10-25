part of 'plus_cubit.dart';

/// Einmaliges Ereignis vom Store. Bewusst nicht `const`.
class PlusEvent {
  PlusEvent(this.kind);

  final PlusStoreUpdateKind kind;
}

class PlusState extends Equatable {
  const PlusState({
    this.loaded = false,
    this.checked = false,
    this.supported = true,
    this.status = const PlusStatus(),
    this.prices = const {},
    this.busy = false,
    this.event,
  });

  final bool loaded;

  /// Der Server hat den Stand bestätigt. Nur dann darf die App „Cloud pausiert“ zeigen – ohne Netz
  /// bleibt alles, wie es ist.
  final bool checked;

  /// Kauf auf diesem Gerät möglich (App Store).
  final bool supported;
  final PlusStatus status;
  final Map<String, StorePrice> prices;
  final bool busy;
  final PlusEvent? event;

  bool get active => status.active;

  /// Monatspreis aus dem Store, `null` ohne Store (Android, Simulator ohne StoreKit-Datei).
  StorePrice? get monthly => prices[PlusStore.monthly];

  PlusState copyWith({bool? loaded, bool? checked, PlusStatus? status, Map<String, StorePrice>? prices, bool? busy, PlusEvent? event}) => PlusState(
    loaded: loaded ?? this.loaded,
    checked: checked ?? this.checked,
    supported: supported,
    status: status ?? this.status,
    prices: prices ?? this.prices,
    busy: busy ?? this.busy,
    event: event,
  );

  @override
  List<Object?> get props => [loaded, checked, supported, status, prices, busy, event];
}
