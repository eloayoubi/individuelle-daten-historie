import 'package:equatable/equatable.dart';

import '../../../core/utils/formulas.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'categories_repository.dart';

/// Antrieb eines Fahrzeugs: entscheidet, ob beim Tanken Liter, beim Laden kWh oder beides erfasst
/// werden. Gespeichert wird er nicht eigens – er steckt in den Mengenfeldern ([VehicleDrives.of]).
enum VehicleDrive {
  fuel,
  electric,
  hybrid;

  bool get litres => this != VehicleDrive.electric;

  bool get kwh => this != VehicleDrive.fuel;
}

/// Namen der Felder fürs Tanken und Laden in der App-Sprache.
class VehicleDriveNames extends Equatable {
  const VehicleDriveNames({
    required this.refuel,
    required this.charge,
    required this.refuelOrCharge,
    required this.litres,
    required this.kwh,
    required this.legacyAmount,
  });

  factory VehicleDriveNames.of(AppLocalizations l) => VehicleDriveNames(
    refuel: l.tplFieldRefuel,
    charge: l.tplFieldCharge,
    refuelOrCharge: l.tplFieldFuel,
    litres: l.tplFieldLitres,
    kwh: l.tplFieldKwh,
    legacyAmount: l.tplFieldFuelAmount,
  );

  /// Betrag: „Tanken“, „Laden“, beim Hybrid „Tanken / Laden“.
  final String refuel;
  final String charge;
  final String refuelOrCharge;

  /// Mengen: „Getankt“ in l, „Geladen“ in kWh.
  final String litres;
  final String kwh;

  /// Menge ohne Einheit aus früheren Vorlagen („Menge (l oder kWh)“).
  final String legacyAmount;

  String cost(VehicleDrive drive) => switch (drive) {
    VehicleDrive.fuel => refuel,
    VehicleDrive.electric => charge,
    VehicleDrive.hybrid => refuelOrCharge,
  };

  @override
  List<Object?> get props => [refuel, charge, refuelOrCharge, litres, kwh, legacyAmount];
}

/// Eine Änderung an den Feldern eines Trackers.
sealed class FieldChange extends Equatable {
  const FieldChange();
}

class FieldCreated extends FieldChange {
  const FieldCreated(this.draft);

  final FieldDraft draft;

  @override
  List<Object?> get props => [draft];
}

class FieldUpdated extends FieldChange {
  const FieldUpdated(this.id, this.draft);

  final String id;
  final FieldDraft draft;

  @override
  List<Object?> get props => [id, draft];
}

class FieldArchived extends FieldChange {
  const FieldArchived(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

abstract final class VehicleDrives {
  static const litreUnit = 'l';
  static const kwhUnit = 'kWh';

  /// Felder fürs Tanken und Laden in einer neuen Kategorie: der Betrag, dann die Mengen.
  static List<FieldDraft> fields(VehicleDrive drive, VehicleDriveNames names) => [
    FieldDraft(name: names.cost(drive), kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€'),
    if (drive.litres) _amount(names.litres, litreUnit),
    if (drive.kwh) _amount(names.kwh, kwhUnit),
  ];

  static FieldDraft _amount(String name, String unit) => FieldDraft(name: name, kind: FieldKind.number, role: FieldRole.snapshot, unit: unit);

  static bool _isAmount(FieldDefinition f) => f.kind == FieldKind.number && f.role == FieldRole.snapshot;

  static FieldDefinition? _withUnit(Tracker tracker, String unit) => tracker.fields.where((f) => _isAmount(f) && f.unit == unit).firstOrNull;

  /// Antrieb, abgelesen an den Mengenfeldern (l, kWh); `null`, solange keins eine dieser Einheiten hat.
  static VehicleDrive? of(Tracker tracker) => switch ((_withUnit(tracker, litreUnit) != null, _withUnit(tracker, kwhUnit) != null)) {
    (true, true) => VehicleDrive.hybrid,
    (true, false) => VehicleDrive.fuel,
    (false, true) => VehicleDrive.electric,
    (false, false) => null,
  };

  /// Was sich an [tracker] ändern muss, damit er zum Antrieb [drive] passt: Fehlende Mengen kommen
  /// dazu – bevorzugt aus der Menge ohne Einheit oder einer leeren, nicht mehr gebrauchten Menge –,
  /// nicht mehr gebrauchte fallen weg (ihre Werte bleiben gespeichert), der Betrag heißt passend.
  /// Felder, die eine Formel benutzt, behalten ihren Namen.
  static List<FieldChange> changes(Tracker tracker, VehicleDrive drive, VehicleDriveNames names) {
    final keys = Formulas.keys(tracker);
    final formulas = [for (final f in tracker.fields) ?f.formula];
    bool used(FieldDefinition f) => formulas.any((formula) => RegExp('\\b${keys[f.id]}\\b').hasMatch(formula));
    String rename(FieldDefinition f, String name) => used(f) ? f.name : name;

    final changes = <FieldChange>[];
    final costNames = {names.refuel, names.charge, names.refuelOrCharge};
    final cost = tracker.fields.where((f) => f.role == FieldRole.oneOffCost && costNames.contains(f.name)).firstOrNull;
    if (cost != null && rename(cost, names.cost(drive)) != cost.name) {
      changes.add(FieldUpdated(cost.id, FieldDraft.of(cost).copyWith(name: names.cost(drive))));
    }

    final litres = _withUnit(tracker, litreUnit);
    final kwh = _withUnit(tracker, kwhUnit);
    final legacy = tracker.fields.where((f) => _isAmount(f) && (f.unit ?? '').isEmpty && f.name == names.legacyAmount).firstOrNull;
    final unused = [if (!drive.litres) ?litres, if (!drive.kwh) ?kwh];
    // Wiederverwendbar: die Menge ohne Einheit (gemeint war l oder kWh) und leere, nicht mehr gebrauchte.
    final reusable = [?legacy, for (final f in unused) if (!tracker.hasValues(f.id)) f];
    for (final (needed, existing, name, unit) in [(drive.litres, litres, names.litres, litreUnit), (drive.kwh, kwh, names.kwh, kwhUnit)]) {
      if (!needed || existing != null) continue;
      if (reusable.isEmpty) {
        changes.add(FieldCreated(_amount(name, unit)));
      } else {
        final field = reusable.removeAt(0);
        unused.remove(field);
        changes.add(FieldUpdated(field.id, FieldDraft.of(field).copyWith(name: rename(field, name), unit: unit)));
      }
    }
    for (final f in unused) {
      changes.add(FieldArchived(f.id));
    }
    return changes;
  }
}
