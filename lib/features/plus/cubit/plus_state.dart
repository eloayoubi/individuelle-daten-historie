part of 'plus_cubit.dart';

/// Einmaliges Ereignis vom Store. Bewusst nicht `const`.
class PlusEvent {
  PlusEvent(this.kind);

  final PlusStoreUpdateKind kind;
}

class PlusState extends Equatable {
  const PlusState({this.loaded = false, this.supported = true, this.status = const PlusStatus(), this.prices = const {}, this.busy = false, this.event});

  final bool loaded;

  /// Kauf auf diesem Gerät möglich (App Store).
  final bool supported;
  final PlusStatus status;
  final Map<String, StorePrice> prices;
  final bool busy;
  final PlusEvent? event;

  bool get active => status.active;

  /// Ersparnis des Jahresabos gegenüber zwölf Monaten (0,44 = 44 %), `null` ohne beide Preise.
  double? get yearlySaving {
    final m = prices[PlusStore.monthly]?.raw, y = prices[PlusStore.yearly]?.raw;
    if (m == null || y == null || m <= 0) return null;
    return 1 - y / (m * 12);
  }

  PlusState copyWith({bool? loaded, PlusStatus? status, Map<String, StorePrice>? prices, bool? busy, PlusEvent? event}) => PlusState(
    loaded: loaded ?? this.loaded,
    supported: supported,
    status: status ?? this.status,
    prices: prices ?? this.prices,
    busy: busy ?? this.busy,
    event: event,
  );

  @override
  List<Object?> get props => [loaded, supported, status, prices, busy, event];
}
