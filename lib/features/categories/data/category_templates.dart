import 'package:equatable/equatable.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'categories_repository.dart';

/// Eine Startvorlage: Kategorie mit Trackern und Feldern, in der App-Sprache benannt.
/// Herleitung der Auswahl: docs/IMPLEMENTIERUNGSPLAN.md, Abschnitte 3 und 4.
class CategoryTemplate extends Equatable {
  const CategoryTemplate({required this.key, required this.name, required this.description, required this.icon, required this.swatch, required this.trackers});

  /// Landet als `template_key` in der Datenbank.
  final String key;
  final String name;
  final String description;
  final CategoryIcon icon;
  final CategorySwatch swatch;
  final List<TrackerDraft> trackers;

  @override
  List<Object?> get props => [key, name, description, icon, swatch, trackers];
}

abstract final class CategoryTemplates {
  /// Gas: Brennwert × Zustandszahl, typisch um 10,5 kWh je m³ – genauer Wert steht auf der Abrechnung.
  static const gasFactor = 10.5;

  static List<CategoryTemplate> all(AppLocalizations l) {
    FieldDraft reading(String unit, {String? consumptionUnit, double factor = 1}) =>
        FieldDraft(name: l.tplFieldReading, kind: FieldKind.number, role: FieldRole.meterReading, unit: unit, consumptionUnit: consumptionUnit, factor: factor);
    FieldDraft unitPrice(String name, String unit) => FieldDraft(name: name, kind: FieldKind.currency, role: FieldRole.unitPrice, unit: unit);
    FieldDraft recurring(String name, {int interval = 1}) =>
        FieldDraft(name: name, kind: FieldKind.currency, role: FieldRole.recurringCost, unit: interval == 12 ? l.unitPerYear : l.unitPerMonth, intervalMonths: interval);
    FieldDraft oneOff(String name) => FieldDraft(name: name, kind: FieldKind.currency, role: FieldRole.oneOffCost, unit: '€');
    FieldDraft deadline(String name) => FieldDraft(name: name, kind: FieldKind.date, role: FieldRole.deadline);
    FieldDraft text(String name) => FieldDraft(name: name, kind: FieldKind.text);

    return [
      CategoryTemplate(
        key: 'strom',
        name: l.tplStrom,
        description: l.tplStromHint,
        icon: CategoryIcon.bolt,
        swatch: CategorySwatch.orange,
        trackers: [
          TrackerDraft(
            name: l.tplTrackerElectricityMeter,
            fields: [
              reading('kWh'),
              unitPrice(l.tplFieldUnitPrice, '€/kWh'),
              recurring(l.tplFieldBasePrice),
              FieldDraft(name: l.tplFieldInstalment, kind: FieldKind.currency, role: FieldRole.instalment, unit: l.unitPerMonth),
              text(l.tplFieldProvider),
              deadline(l.tplFieldContractEnd),
            ],
          ),
        ],
      ),
      CategoryTemplate(
        key: 'heizung',
        name: l.tplHeizung,
        description: l.tplHeizungHint,
        icon: CategoryIcon.flame,
        swatch: CategorySwatch.red,
        trackers: [
          TrackerDraft(
            name: l.tplTrackerGasMeter,
            fields: [
              reading('m³', consumptionUnit: 'kWh', factor: gasFactor),
              unitPrice(l.tplFieldUnitPrice, '€/kWh'),
              recurring(l.tplFieldBasePrice),
              FieldDraft(name: l.tplFieldInstalment, kind: FieldKind.currency, role: FieldRole.instalment, unit: l.unitPerMonth),
              text(l.tplFieldProvider),
              deadline(l.tplFieldContractEnd),
            ],
          ),
        ],
      ),
      CategoryTemplate(
        key: 'wasser',
        name: l.tplWasser,
        description: l.tplWasserHint,
        icon: CategoryIcon.drop,
        swatch: CategorySwatch.blue,
        trackers: [
          TrackerDraft(name: l.tplTrackerWaterMeter, fields: [reading('m³'), unitPrice(l.tplFieldWaterPrice, '€/m³')]),
        ],
      ),
      CategoryTemplate(
        key: 'miete',
        name: l.tplMiete,
        description: l.tplMieteHint,
        icon: CategoryIcon.house,
        swatch: CategorySwatch.brown,
        trackers: [
          TrackerDraft(
            name: l.tplTrackerFlat,
            fields: [recurring(l.tplFieldBaseRent), recurring(l.tplFieldAdvance), oneOff(l.tplFieldSettlement), text(l.tplFieldLandlord)],
          ),
        ],
      ),
      CategoryTemplate(
        key: 'auto',
        name: l.tplAuto,
        description: l.tplAutoHint,
        icon: CategoryIcon.car,
        swatch: CategorySwatch.green,
        trackers: [
          TrackerDraft(
            name: l.tplTrackerCar,
            fields: [
              reading('km'),
              oneOff(l.tplFieldFuel),
              FieldDraft(name: l.tplFieldFuelAmount, kind: FieldKind.number, role: FieldRole.snapshot),
              recurring(l.tplFieldCarInsurance, interval: 12),
              recurring(l.tplFieldCarTax, interval: 12),
              oneOff(l.tplFieldWorkshop),
              deadline(l.tplFieldInspection),
            ],
          ),
        ],
      ),
      CategoryTemplate(
        key: 'internet',
        name: l.tplInternet,
        description: l.tplInternetHint,
        icon: CategoryIcon.wifi,
        swatch: CategorySwatch.purple,
        trackers: [
          TrackerDraft(name: l.tplTrackerInternet, fields: [recurring(l.tplFieldMonthlyPrice), text(l.tplFieldProvider), deadline(l.tplFieldMinimumTerm)]),
          TrackerDraft(name: l.tplTrackerMobile, fields: [recurring(l.tplFieldMonthlyPrice), text(l.tplFieldProvider), deadline(l.tplFieldMinimumTerm)]),
        ],
      ),
      CategoryTemplate(
        key: 'versicherung',
        name: l.tplVersicherung,
        description: l.tplVersicherungHint,
        icon: CategoryIcon.shield,
        swatch: CategorySwatch.teal,
        trackers: [
          for (final name in [l.tplTrackerLiability, l.tplTrackerContents])
            TrackerDraft(name: name, fields: [recurring(l.tplFieldPremium, interval: 12), text(l.tplFieldPolicyNumber), deadline(l.tplFieldDueDate)]),
        ],
      ),
      CategoryTemplate(
        key: 'abos',
        name: l.tplAbos,
        description: l.tplAbosHint,
        icon: CategoryIcon.play,
        swatch: CategorySwatch.pink,
        trackers: [
          TrackerDraft(name: l.tplTrackerStreaming, fields: [recurring(l.tplFieldPrice), deadline(l.tplFieldCancelBy)]),
        ],
      ),
    ];
  }
}
