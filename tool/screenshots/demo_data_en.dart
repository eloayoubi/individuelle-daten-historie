import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';

/// Die Beispieldaten der App mit englischen Namen – für die englischen Store-Screenshots, damit
/// dort nicht „Strom“ und „Zählerstand“ neben englischer Oberfläche stehen.
///
/// Werte und Ids bleiben gleich. Tracker mit Formel-Feldern behalten ihre Feldnamen, weil Formeln
/// Felder über den Kurznamen aus dem Namen ansprechen. Unbekannte Namen bleiben, wie sie sind.
List<Category> englishDemoCategories() => [for (final c in MockCategoriesRepository.categories) _category(c)];

Category _category(Category c) => c.copyWith(name: _names[c.name], trackers: [for (final t in c.trackers) _tracker(t)]);

Tracker _tracker(Tracker t) => t.copyWith(
  name: _names[t.name],
  fields: t.fields.any((f) => f.formula != null) ? null : [for (final f in t.fields) _field(f)],
);

FieldDefinition _field(FieldDefinition f) => FieldDefinition(
  id: f.id,
  name: _names[f.name] ?? f.name,
  kind: f.kind,
  role: f.role,
  unit: _units[f.unit] ?? f.unit,
  consumptionUnit: f.consumptionUnit,
  factor: f.factor,
  intervalMonths: f.intervalMonths,
  choices: f.choices,
  formula: f.formula,
);

const _names = {
  // Kategorien
  'Strom': 'Electricity',
  'Heizung': 'Heating',
  'Wasser': 'Water',
  'Miete & Nebenkosten': 'Rent & utilities',
  'Auto': 'Car',
  'Internet & Mobilfunk': 'Internet & mobile',
  'Versicherungen': 'Insurance',
  'Abos & Mitgliedschaften': 'Subscriptions',
  'Ferienwohnung': 'Holiday flat',
  // Tracker
  'Hauptzähler': 'Main meter',
  'Gaszähler': 'Gas meter',
  'Kaltwasser': 'Cold water',
  'Wohnung': 'Flat',
  'Glasfaser 250': 'Fibre 250',
  'Handyvertrag': 'Mobile',
  'Privathaftpflicht': 'Liability',
  'Hausrat': 'Home contents',
  'Fitnessstudio': 'Gym',
  'Strom Ostsee': 'Electricity Baltic Sea',
  // Felder
  'Zählerstand': 'Meter reading',
  'Arbeitspreis': 'Unit price',
  'Grundpreis': 'Standing charge',
  'Abschlag': 'Monthly instalment',
  'Vertragsende': 'Contract end',
  'Anbieter': 'Provider',
  'Wasser & Abwasser': 'Water & sewage',
  'Kaltmiete': 'Base rent',
  'Nebenkosten-Vorauszahlung': 'Utility advance payment',
  'Nachzahlung / Guthaben': 'Balance due / credit',
  'Beitrag': 'Price',
};

const _units = {'€/Monat': '€/month', '€/Jahr': '€/year'};
