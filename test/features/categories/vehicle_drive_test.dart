import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/vehicle_drive.dart';
import 'package:kostenkurve/l10n/generated/app_localizations.dart';

void main() {
  final names = VehicleDriveNames.of(lookupAppLocalizations(const Locale('de')));
  const km = FieldDefinition(id: 'km', name: 'Zählerstand', kind: FieldKind.number, role: FieldRole.meterReading, unit: 'km');
  const cost = FieldDefinition(id: 'cost', name: 'Tanken / Laden', kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€');
  const legacy = FieldDefinition(id: 'menge', name: 'Menge (l oder kWh)', kind: FieldKind.number, role: FieldRole.snapshot);
  const litres = FieldDefinition(id: 'l', name: 'Getankt', kind: FieldKind.number, role: FieldRole.snapshot, unit: 'l');
  const kwh = FieldDefinition(id: 'kwh', name: 'Geladen', kind: FieldKind.number, role: FieldRole.snapshot, unit: 'kWh');
  Tracker car(List<FieldDefinition> fields, {Map<String, Object> values = const {}}) => Tracker(
    id: 't',
    name: 'Mein Auto',
    fields: fields,
    entries: [if (values.isNotEmpty) Entry(id: 'e', date: DateTime.utc(2026), values: values)],
  );

  test('neue Felder je Antrieb: Liter, kWh oder beides', () {
    String units(VehicleDrive d) => [for (final f in VehicleDrives.fields(d, names)) '${f.name} ${f.unit}'].join(', ');
    expect(units(VehicleDrive.fuel), 'Tanken €, Getankt l');
    expect(units(VehicleDrive.electric), 'Laden €, Geladen kWh');
    expect(units(VehicleDrive.hybrid), 'Tanken / Laden €, Getankt l, Geladen kWh');
  });

  test('liest den Antrieb an den Einheiten der Mengen ab', () {
    expect(VehicleDrives.of(car([km, cost, legacy])), isNull);
    expect(VehicleDrives.of(car([km, litres])), VehicleDrive.fuel);
    expect(VehicleDrives.of(car([km, kwh])), VehicleDrive.electric);
    expect(VehicleDrives.of(car([km, litres, kwh])), VehicleDrive.hybrid);
  });

  test('alte Menge ohne Einheit wird zu kWh, der Betrag heißt „Laden“', () {
    expect(VehicleDrives.changes(car([km, cost, legacy]), VehicleDrive.electric, names), [
      FieldUpdated('cost', FieldDraft.of(cost).copyWith(name: 'Laden')),
      FieldUpdated('menge', FieldDraft.of(legacy).copyWith(name: 'Geladen', unit: 'kWh')),
    ]);
  });

  test('Hybrid ergänzt die fehlende Menge', () {
    expect(VehicleDrives.changes(car([km, cost, litres]), VehicleDrive.hybrid, names), [
      const FieldCreated(FieldDraft(name: 'Geladen', kind: FieldKind.number, role: FieldRole.snapshot, unit: 'kWh')),
    ]);
  });

  test('leere Menge wird umgestellt, eine mit Werten fällt weg und eine neue kommt', () {
    expect(VehicleDrives.changes(car([km, litres]), VehicleDrive.electric, names), [
      FieldUpdated('l', FieldDraft.of(litres).copyWith(name: 'Geladen', unit: 'kWh')),
    ]);
    expect(VehicleDrives.changes(car([km, litres], values: {'l': 40}), VehicleDrive.electric, names), [
      const FieldCreated(FieldDraft(name: 'Geladen', kind: FieldKind.number, role: FieldRole.snapshot, unit: 'kWh')),
      const FieldArchived('l'),
    ]);
  });

  test('gleicher Antrieb ändert nichts, Namen in Formeln bleiben', () {
    expect(VehicleDrives.changes(car([km, cost, litres, kwh]), VehicleDrive.hybrid, names), isEmpty);
    const formula = FieldDefinition(id: 'f', name: 'Verbrauch', kind: FieldKind.formula, formula: 'menge_l_oder_kwh / verbrauch * 100');
    expect(VehicleDrives.changes(car([km, legacy, formula]), VehicleDrive.fuel, names), [
      FieldUpdated('menge', FieldDraft.of(legacy).copyWith(unit: 'l')),
    ]);
  });
}
