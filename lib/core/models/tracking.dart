import 'package:equatable/equatable.dart';

/// Wie ein Feld eingegeben und angezeigt wird.
enum FieldKind { text, number, currency, percent, date, toggle, choice, formula }

/// In welcher Wertspalte ein Feldtyp speichert (`entry_values.num/txt/dat/flag`); Formeln speichern nichts.
enum FieldStorage { number, text, date, flag, none }

extension FieldKindRules on FieldKind {
  FieldStorage get storage => switch (this) {
    FieldKind.number || FieldKind.currency || FieldKind.percent => FieldStorage.number,
    FieldKind.text || FieldKind.choice => FieldStorage.text,
    FieldKind.date => FieldStorage.date,
    FieldKind.toggle => FieldStorage.flag,
    FieldKind.formula => FieldStorage.none,
  };

  /// Zeitverhalten, die zu diesem Typ passen – wie der Check `fields_role_fits_kind` in der Datenbank.
  List<FieldRole> get roles => switch (this) {
    FieldKind.number => const [FieldRole.meterReading, FieldRole.snapshot, FieldRole.info],
    FieldKind.currency => const [FieldRole.recurringCost, FieldRole.oneOffCost, FieldRole.unitPrice, FieldRole.snapshot, FieldRole.info],
    FieldKind.percent => const [FieldRole.snapshot, FieldRole.info],
    FieldKind.date => const [FieldRole.deadline, FieldRole.info],
    FieldKind.formula => const [FieldRole.recurringCost, FieldRole.oneOffCost, FieldRole.unitPrice, FieldRole.snapshot, FieldRole.info],
    FieldKind.text || FieldKind.choice || FieldKind.toggle => const [FieldRole.info],
  };

  /// Ein Feld mit gespeicherten Werten darf nur zu einem Typ mit derselben Wertspalte wechseln.
  bool canBecome(FieldKind other, {required bool hasValues}) => !hasValues || other.storage == storage;

  /// Einheit eintragen? Bei Prozent ist sie fest, bei Text, Datum, Ja/Nein und Auswahl gibt es keine.
  bool get hasUnit => this == FieldKind.number || this == FieldKind.currency || this == FieldKind.formula;
}

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

  /// Hat das Feld schon gespeicherte Werte? Dann darf sich sein Typ nur eingeschränkt ändern.
  bool hasValues(String fieldId) => entries.any((e) => e.values.containsKey(fieldId));

  Tracker copyWith({String? name, List<FieldDefinition>? fields, List<Entry>? entries}) =>
      Tracker(id: id, name: name ?? this.name, fields: fields ?? this.fields, entries: entries ?? this.entries);

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
    this.templateKey,
    this.archivedAt,
  });

  final String id;
  final String name;
  final CategoryIcon icon;
  final CategorySwatch swatch;
  final List<Tracker> trackers;

  /// Alle Mitglieder außer mir.
  final List<CategoryMember> sharedWith;
  final MemberRole myRole;

  /// Vorlage, aus der die Kategorie entstand (`strom`, `miete` …), `null` bei eigenen.
  final String? templateKey;

  /// Archivierte Kategorien fehlen in Übersicht und Auswertung, lassen sich aber wiederherstellen.
  final DateTime? archivedAt;

  bool get isShared => sharedWith.isNotEmpty;

  bool get isArchived => archivedAt != null;

  /// Tracker, Felder und Einträge bearbeiten (owner und editor).
  bool get canEdit => myRole != MemberRole.viewer;

  /// Teilen, archivieren, löschen (nur owner).
  bool get isOwner => myRole == MemberRole.owner;

  int get fieldCount => trackers.fold(0, (sum, t) => sum + t.fields.length);

  /// Wer geteilt hat (für viewer und editor), sonst `null`.
  CategoryMember? get sharedBy => isOwner ? null : sharedWith.where((m) => m.role == MemberRole.owner).firstOrNull;

  Category copyWith({
    String? name,
    CategoryIcon? icon,
    CategorySwatch? swatch,
    List<Tracker>? trackers,
    DateTime? Function()? archivedAt,
  }) => Category(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    swatch: swatch ?? this.swatch,
    trackers: trackers ?? this.trackers,
    sharedWith: sharedWith,
    myRole: myRole,
    templateKey: templateKey,
    archivedAt: archivedAt == null ? this.archivedAt : archivedAt(),
  );

  @override
  List<Object?> get props => [id, name, icon, swatch, trackers, sharedWith, myRole, templateKey, archivedAt];
}
