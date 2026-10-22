import 'package:equatable/equatable.dart';

/// Wie ein Feld eingegeben und angezeigt wird.
enum FieldKind { text, number, currency, percent, date, toggle, choice, formula }

/// Wie sich ein Feld über die Zeit verhält – entscheidet, wie Verlauf, Kosten und Prognose rechnen.
enum FieldRole {
  /// Stammdaten ohne Verlauf (Zählernummer, Anbieter, Vertragsnummer).
  info,

  /// Momentwert, gilt genau am Datum des Eintrags (Füllstand, Kontostand).
  snapshot,

  /// Zählerstand, kumulativ: Verbrauch ist die Differenz zweier Stände.
  meterReading,

  /// Preis je Verbrauchseinheit, gilt ab dem Datum bis zur nächsten Änderung (Arbeitspreis).
  unitPrice,

  /// Wiederkehrender Betrag, gilt ab dem Datum (Grundpreis, Miete, Abo, Versicherung).
  recurringCost,

  /// Einmaliger Betrag am Datum des Eintrags (Tanken, Nachzahlung). Negativ ist ein Guthaben.
  oneOffCost,

  /// Stichtag mit Erinnerung (Vertragsende, Kündigungsfrist, TÜV).
  deadline,
}

/// Symbol einer Kategorie; die Zuordnung zu Icons steht in `category_x.dart`.
enum CategoryIcon { bolt, flame, drop, house, car, wifi, shield, play, cart, heart, star, doc }

/// Farbe einer Kategorie aus Apples Systemfarben; die Werte stehen in `color_config.dart`.
enum CategorySwatch { orange, red, blue, cyan, brown, green, purple, teal, pink, indigo, yellow, gray }

/// Rechte in einer geteilten Kategorie.
enum MemberRole { owner, editor, viewer }

/// Ein frei definiertes Feld eines [Tracker]s.
class FieldDefinition extends Equatable {
  const FieldDefinition({
    required this.id,
    required this.name,
    required this.kind,
    this.role = FieldRole.info,
    this.unit,
    this.consumptionUnit,
    this.factor = 1,
    this.intervalMonths = 1,
    this.choices = const [],
    this.formula,
  });

  final String id;
  final String name;
  final FieldKind kind;
  final FieldRole role;

  /// Einheit der Eingabe, z. B. `m³` beim Gaszähler oder `€/kWh` beim Arbeitspreis.
  final String? unit;

  /// Einheit des Verbrauchs, falls sie von [unit] abweicht (Gas: Stand in m³, Verbrauch in kWh).
  final String? consumptionUnit;

  /// Umrechnung von Zählerstand zu Verbrauch (Gas: Brennwert × Zustandszahl, sonst 1).
  final double factor;

  /// Bei [FieldRole.recurringCost]: alle wie viele Monate der Betrag fällig ist (1, 3, 12).
  final int intervalMonths;

  /// Auswahlwerte bei [FieldKind.choice].
  final List<String> choices;

  /// Ausdruck bei [FieldKind.formula], z. B. `verbrauch * arbeitspreis`.
  final String? formula;

  String get usageUnit => consumptionUnit ?? unit ?? '';

  @override
  List<Object?> get props => [id, name, kind, role, unit, consumptionUnit, factor, intervalMonths, choices, formula];
}

/// Ein Eintrag zu einem Datum; trägt Werte für einige oder alle Felder des [Tracker]s.
class Entry extends Equatable {
  const Entry({required this.id, required this.date, this.values = const {}, this.note, this.meterChange = false});

  final String id;

  /// Stichtag, ohne Uhrzeit (UTC-Mitternacht).
  final DateTime date;

  /// Werte je Feld-Id: `num` für Zahlen, Beträge und Prozente, `String` für Text und Auswahl,
  /// `DateTime` für Datumsfelder, `bool` für Ja/Nein.
  final Map<String, Object> values;
  final String? note;

  /// Neuer Zähler ab diesem Eintrag: Der Verbrauch seit dem letzten Stand ist unbekannt.
  final bool meterChange;

  num? number(String fieldId) => switch (values[fieldId]) {
    final num n => n,
    _ => null,
  };

  DateTime? dateValue(String fieldId) => switch (values[fieldId]) {
    final DateTime d => d,
    _ => null,
  };

  @override
  List<Object?> get props => [id, date, values, note, meterChange];
}

/// Etwas, das verfolgt wird – ein Zähler, ein Vertrag, ein Auto – mit eigenen Feldern und Einträgen.
class Tracker extends Equatable {
  const Tracker({required this.id, required this.name, this.fields = const [], this.entries = const []});

  final String id;
  final String name;
  final List<FieldDefinition> fields;
  final List<Entry> entries;

  Iterable<FieldDefinition> withRole(FieldRole role) => fields.where((f) => f.role == role);

  FieldDefinition? firstWithRole(FieldRole role) => withRole(role).firstOrNull;

  @override
  List<Object?> get props => [id, name, fields, entries];
}

/// Eine andere Person, mit der eine Kategorie geteilt ist.
class CategoryMember extends Equatable {
  const CategoryMember({required this.userId, required this.name, required this.role});

  final String userId;
  final String name;
  final MemberRole role;

  @override
  List<Object?> get props => [userId, name, role];
}

/// Oberste Ebene: Strom, Miete, Auto … – Einheit des Teilens.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.swatch,
    this.trackers = const [],
    this.sharedWith = const [],
    this.myRole = MemberRole.owner,
  });

  final String id;
  final String name;
  final CategoryIcon icon;
  final CategorySwatch swatch;
  final List<Tracker> trackers;

  /// Alle Mitglieder außer mir.
  final List<CategoryMember> sharedWith;
  final MemberRole myRole;

  bool get isShared => sharedWith.isNotEmpty;

  @override
  List<Object?> get props => [id, name, icon, swatch, trackers, sharedWith, myRole];
}
