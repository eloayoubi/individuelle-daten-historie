import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'plus_repository.dart';

enum PlusStoreUpdateKind {
  /// Gekauft, verlängert oder wiederhergestellt – Plus läuft.
  unlocked,

  /// Wiederhergestellt, aber abgelaufen.
  expired,

  /// Wartet auf Freigabe („Kaufen anfragen“ der Familienfreigabe).
  pending,

  /// Das Abo gehört zu einem anderen Kostenkurve-Konto (z. B. nach Neuinstallation ohne Anmeldung).
  otherAccount,
  canceled,
  failed,
}

/// „Kostenkurve Cloud“ im App Store (Produkt-Ids aus der Zeit als „Plus“): 2 € im Monat. Das
/// Jahresabo verkauft die App nicht mehr; laufende Jahresabos erkennt der Server weiter.
abstract interface class PlusStore {
  static const monthly = 'de.eloayoubi.kostenkurve.plus.monthly';
  static const yearly = 'de.eloayoubi.kostenkurve.plus.yearly';
  static const products = [monthly];
  static const prefix = 'de.eloayoubi.kostenkurve.plus.';

  /// Hört auf Käufe, Verlängerungen und offene Transaktionen. Einmal beim App-Start.
  void start();

  bool get supported;

  /// Preise der Abos; leer, wo es keinen Kauf gibt (oder die Produkte in App Store Connect fehlen).
  Future<Map<String, StorePrice>> prices();

  Future<void> buy(String productId);

  /// „Käufe wiederherstellen“ – Pflicht auf jeder Abo-Seite.
  Future<void> restore();

  Stream<PlusStoreUpdateKind> get updates;
}

/// StoreKit 2 über `in_app_purchase` (wie MyBoo): Die signierte Transaktion geht an den Server,
/// abgeschlossen wird erst nach dessen Antwort. `applicationUserName` = Nutzer-Id wird zum
/// `appAccountToken`, so prüft der Server, wem der Kauf gehört.
class AppStorePlusStore implements PlusStore {
  AppStorePlusStore(this._repository, this._userId);

  final PlusRepository _repository;
  final String? Function() _userId;
  final _iap = InAppPurchase.instance;
  final _products = <String, ProductDetails>{};
  final _updates = StreamController<PlusStoreUpdateKind>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  Stream<PlusStoreUpdateKind> get updates => _updates.stream;

  @override
  bool get supported => true;

  @override
  void start() => _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (_) => _updates.add(PlusStoreUpdateKind.failed));

  @override
  Future<Map<String, StorePrice>> prices() async {
    start();
    if (!await _iap.isAvailable()) return const {};
    final res = await _iap.queryProductDetails(PlusStore.products.toSet());
    for (final p in res.productDetails) {
      _products[p.id] = p;
    }
    return {for (final p in res.productDetails) p.id: StorePrice(p.price, p.rawPrice, currency: p.currencyCode)};
  }

  @override
  Future<void> buy(String productId) async {
    final product = _products[productId];
    final user = _userId();
    if (product == null) throw StateError('unknown_product $productId');
    if (user == null) throw StateError('not_signed_in');
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product, applicationUserName: user));
  }

  @override
  Future<void> restore() async {
    start();
    await _iap.restorePurchases(applicationUserName: _userId());
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!p.productID.startsWith(PlusStore.prefix)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _updates.add(PlusStoreUpdateKind.pending);
        case PurchaseStatus.canceled:
          _updates.add(PlusStoreUpdateKind.canceled);
        case PurchaseStatus.error:
          _updates.add(PlusStoreUpdateKind.failed);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          if (_userId() == null) continue;
          try {
            final status = await _repository.redeem(p.verificationData.serverVerificationData);
            await _finish(p);
            _updates.add(status.active ? PlusStoreUpdateKind.unlocked : PlusStoreUpdateKind.expired);
          } on PlusRejected catch (e) {
            // Endgültig abgelehnt: abschließen, sonst kommt die Transaktion bei jedem Start wieder.
            // „Käufe wiederherstellen“ liefert sie bei Bedarf erneut.
            await _finish(p);
            _updates.add(e.otherAccount ? PlusStoreUpdateKind.otherAccount : PlusStoreUpdateKind.failed);
          } catch (_) {
            // Netz oder Server: offen lassen, StoreKit liefert sie beim nächsten Start erneut.
            _updates.add(PlusStoreUpdateKind.failed);
          }
      }
    }
  }

  Future<void> _finish(PurchaseDetails p) async {
    if (p.pendingCompletePurchase || p.purchaseID != null) await _iap.completePurchase(p);
  }
}

/// Android vorerst ohne Kauf: Die Cloud gibt es im App Store (Google Play folgt); ein dort gekauftes
/// Abo gilt nach dem Anmelden auch hier.
class UnavailablePlusStore implements PlusStore {
  const UnavailablePlusStore();

  @override
  bool get supported => false;

  @override
  void start() {}

  @override
  Future<Map<String, StorePrice>> prices() async => const {};

  @override
  Future<void> buy(String productId) async => throw StateError('store_unavailable');

  @override
  Future<void> restore() async {}

  @override
  Stream<PlusStoreUpdateKind> get updates => const Stream.empty();
}

/// Ohne Backend: Kaufen schaltet sofort frei.
class MockPlusStore implements PlusStore {
  MockPlusStore(this._repository);

  final PlusRepository _repository;
  final _updates = StreamController<PlusStoreUpdateKind>.broadcast();

  @override
  bool get supported => true;

  @override
  void start() {}

  @override
  Future<Map<String, StorePrice>> prices() async => const {PlusStore.monthly: StorePrice('2,00 €', 2, currency: 'EUR')};

  @override
  Future<void> buy(String productId) async {
    final status = await _repository.redeem(productId);
    _updates.add(status.active ? PlusStoreUpdateKind.unlocked : PlusStoreUpdateKind.failed);
  }

  @override
  Future<void> restore() async => _updates.add(PlusStoreUpdateKind.expired);

  @override
  Stream<PlusStoreUpdateKind> get updates => _updates.stream;
}
