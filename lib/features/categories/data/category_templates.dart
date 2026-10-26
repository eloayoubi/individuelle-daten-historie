import 'package:equatable/equatable.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'categories_repository.dart';

/// Eine Startvorlage: Kategorie mit Trackern und Feldern, in der App-Sprache benannt.
/// Herleitung der Auswahl: docs/IMPLEMENTIERUNGSPLAN.md, Abschnitte 3 und 4.
class CategoryTemplate extends Equatable {
  const CategoryTemplate({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.swatch,
    required this.trackers,
    this.item,
  });

  /// Landet als `template_key` in der Datenbank.
  final String key;
  final String name;
  final String description;
  final CategoryIcon icon;
  final CategorySwatch swatch;
  final List<TrackerDraft> trackers;

  /// Kategorien aus vielen gleich gebauten Trackern (je Abo, je Versicherung): wie ein weiterer aussieht.
  final ItemTemplate? item;

  @override
  List<Object?> get props => [key, name, description, icon, swatch, trackers, item];
}

/// Vorschläge einer Art („Streaming“: Netflix, Disney+ …). [name] `null` = ohne Art.
class ItemGroup extends Equatable {
  const ItemGroup({this.name, required this.suggestions});

  final String? name;
  final List<String> suggestions;

  @override
  List<Object?> get props => [name, suggestions];
}

/// Bauplan für Kategorien, die aus vielen gleichartigen Trackern bestehen – ein Tracker je Abo, je
/// Versicherung. Statt „Tracker hinzufügen“ mit leeren Feldern legt „Abo hinzufügen“ den Tracker
/// fertig an: Betrag mit Intervall, weitere Felder und – bei [groups] mit Namen – die Art als
/// Auswahl-Detail, nach der die Kategorie ihre Tracker gruppiert ([Tracker.group]).
class ItemTemplate extends Equatable {
  const ItemTemplate({
    required this.add,
    required this.nameHint,
    required this.listTitle,
    required this.emptyTitle,
    required this.emptyBody,
    required this.amountName,
    required this.amountUnits,
    this.defaultInterval = 1,
    this.groupName,
    this.groups = const [],
    this.fields = const [],
  });

  /// „Abo hinzufügen“ – Hauptaktion, Titel des Sheets und Menüeintrag.
  final String add;
  final String nameHint;

  /// Überschrift der Liste, wenn es keine Arten gibt („Deine Versicherungen“).
  final String listTitle;
  final String emptyTitle;
  final String emptyBody;

  /// Wiederkehrender Betrag („Preis“, „Beitrag“) und seine Einheit je Intervall (1 → „€/Monat“).
  final String amountName;
  final Map<int, String> amountUnits;
  final int defaultInterval;

  /// Name des Auswahl-Felds für die Art („Art“), `null` ohne Arten.
  final String? groupName;
  final List<ItemGroup> groups;

  /// Weitere Felder nach dem Betrag (Kündbar bis, Versicherungsnummer).
  final List<FieldDraft> fields;

  List<String> get groupNames => [for (final g in groups) ?g.name];

  /// Felder eines neuen Trackers: zuerst der Betrag im gewählten [interval], dann [fields], zuletzt
  /// die Art.
  List<FieldDraft> draftFields({required int interval}) => [
    FieldDraft(name: amountName, kind: FieldKind.currency, role: FieldRole.recurringCost, unit: amountUnits[interval], intervalMonths: interval),
    ...fields,
    if (groupName != null && groupNames.isNotEmpty) FieldDraft(name: groupName!, kind: FieldKind.choice, choices: groupNames),
  ];

  @override
  List<Object?> get props => [add, nameHint, listTitle, emptyTitle, emptyBody, amountName, amountUnits, defaultInterval, groupName, groups, fields];
}

/// Neuer Tracker nach einem [ItemTemplate], wie im Sheet eingegeben.
class ItemDraft extends Equatable {
  const ItemDraft({required this.name, this.group, this.amount, required this.interval, required this.since});

  final String name;

  /// Art (eine aus [ItemTemplate.groupNames]), `null` ohne.
  final String? group;

  /// Betrag je [interval] Monate, gilt ab [since]; `null` = noch unbekannt.
  final double? amount;
  final int interval;
  final DateTime since;

  @override
  List<Object?> get props => [name, group, amount, interval, since];
}

abstract final class CategoryTemplates {
  /// Bauplan für weitere Tracker der Vorlage [key] (Abos, Versicherungen), `null` bei anderen.
  static ItemTemplate? item(AppLocalizations l, String? key) => key == null ? null : all(l).where((t) => t.key == key).firstOrNull?.item;

  /// Vorschläge aus einer Liste mit `|` (in der ARB-Datei je Sprache).
  static List<String> _split(String list) => [for (final s in list.split('|')) if (s.trim().isNotEmpty) s.trim()];

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
    final amountUnits = {1: l.unitPerMonth, 12: l.unitPerYear};

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
        item: ItemTemplate(
          add: l.itemInsuranceAdd,
          nameHint: l.itemInsuranceNameHint,
          listTitle: l.itemInsuranceList,
          emptyTitle: l.itemInsuranceEmptyTitle,
          emptyBody: l.itemInsuranceEmptyBody,
          amountName: l.tplFieldPremium,
          amountUnits: amountUnits,
          defaultInterval: 12,
          groups: [ItemGroup(suggestions: _split(l.itemInsuranceSuggestions))],
          fields: [text(l.tplFieldPolicyNumber), deadline(l.tplFieldDueDate)],
        ),
      ),
      CategoryTemplate(
        key: 'abos',
        name: l.tplAbos,
        description: l.tplAbosHint,
        icon: CategoryIcon.play,
        swatch: CategorySwatch.pink,
        // Ohne Tracker: Jedes Abo ist ein eigener, angelegt über „Abo hinzufügen“.
        trackers: const [],
        item: ItemTemplate(
          add: l.itemAboAdd,
          nameHint: l.itemAboNameHint,
          listTitle: l.itemAboList,
          emptyTitle: l.itemAboEmptyTitle,
          emptyBody: l.itemAboEmptyBody,
          amountName: l.tplFieldPrice,
          amountUnits: amountUnits,
          groupName: l.itemGroup,
          groups: [
            ItemGroup(name: l.itemAboGroupVideo, suggestions: _split(l.itemAboSuggestVideo)),
            ItemGroup(name: l.itemAboGroupMusic, suggestions: _split(l.itemAboSuggestMusic)),
            ItemGroup(name: l.itemAboGroupFitness, suggestions: _split(l.itemAboSuggestFitness)),
            ItemGroup(name: l.itemAboGroupSoftware, suggestions: _split(l.itemAboSuggestSoftware)),
            ItemGroup(name: l.itemAboGroupNews, suggestions: _split(l.itemAboSuggestNews)),
            ItemGroup(name: l.itemAboGroupGaming, suggestions: _split(l.itemAboSuggestGaming)),
            ItemGroup(name: l.itemAboGroupOther, suggestions: _split(l.itemAboSuggestOther)),
          ],
          fields: [deadline(l.tplFieldCancelBy)],
        ),
      ),
    ];
  }
}
