import 'package:equatable/equatable.dart';

/// Stand des Cloud-Abos („Kostenkurve Cloud“, technisch weiter `plus`) beim Server (Tabelle `entitlements`).
class PlusStatus extends Equatable {
  const PlusStatus({this.active = false, this.validUntil});

  final bool active;
  final DateTime? validUntil;

  @override
  List<Object?> get props => [active, validUntil];
}

/// Preis eines Abos aus dem Store.
class StorePrice extends Equatable {
  const StorePrice(this.label, this.raw, {this.currency});

  /// Fertig formatiert vom Store, z. B. `2,99 €`.
  final String label;
  final double raw;
  final String? currency;

  @override
  List<Object?> get props => [label, raw, currency];
}

/// Der Server hat die Transaktion endgültig abgelehnt (4xx) – erneutes Senden hilft nicht.
/// [otherAccount]: Der Kauf gehört zu einem anderen Kostenkurve-Konto (`wrong_user`).
class PlusRejected implements Exception {
  const PlusRejected(this.code);

  final String code;

  bool get otherAccount => code == 'wrong_user';

  @override
  String toString() => 'PlusRejected: $code';
}

abstract interface class PlusRepository {
  Future<PlusStatus> status();

  /// Signierte StoreKit-2-Transaktion vom Server prüfen lassen (Edge Function `verify-purchase`);
  /// nur der Server schreibt das Abo in `entitlements`. [PlusRejected] bei endgültiger Ablehnung.
  Future<PlusStatus> redeem(String jws);
}

/// Ohne Backend: Kaufen schaltet sofort für 30 Tage frei.
class MockPlusRepository implements PlusRepository {
  var _status = const PlusStatus();

  @override
  Future<PlusStatus> status() async => _status;

  @override
  Future<PlusStatus> redeem(String jws) async => _status = PlusStatus(active: true, validUntil: DateTime.now().add(const Duration(days: 30)));
}
