import 'tracking.dart';

/// JSON für den Offline-Cache und die Warteschlange (nicht das Datenbank-Format).
/// Werte behalten ihren Typ: `{"n": 1.5}`, `{"t": "…"}`, `{"d": "2026-10-01"}`, `{"b": true}`.
abstract final class TrackingCodec {
  static Map<String, Object?> category(Category c) => {
    'id': c.id,
    'name': c.name,
    'icon': c.icon.name,
    'swatch': c.swatch.name,
    'myRole': c.myRole.name,
    'templateKey': c.templateKey,
    'archivedAt': c.archivedAt?.toIso8601String(),
    'sharedWith': [
      for (final m in c.sharedWith) {'userId': m.userId, 'name': m.name, 'role': m.role.name},
    ],
    'trackers': [for (final t in c.trackers) tracker(t)],
  };

  static Category categoryFrom(Map<String, Object?> j) => Category(
    id: j['id']! as String,
    name: j['name']! as String,
    icon: CategoryIcon.values.byName(j['icon']! as String),
    swatch: CategorySwatch.values.byName(j['swatch']! as String),
    myRole: MemberRole.values.byName(j['myRole']! as String),
    templateKey: j['templateKey'] as String?,
    archivedAt: switch (j['archivedAt']) {
      final String iso => DateTime.parse(iso),
      _ => null,
    },
    sharedWith: [
      for (final m in (j['sharedWith']! as List).cast<Map<String, Object?>>())
        CategoryMember(userId: m['userId']! as String, name: m['name']! as String, role: MemberRole.values.byName(m['role']! as String)),
    ],
    trackers: [for (final t in (j['trackers']! as List).cast<Map<String, Object?>>()) trackerFrom(t)],
  );

  static Map<String, Object?> tracker(Tracker t) => {
    'id': t.id,
    'name': t.name,
    'fields': [for (final f in t.fields) field(f)],
    'entries': [for (final e in t.entries) entry(e)],
    'includedIn': t.includedIn,
  };

  static Tracker trackerFrom(Map<String, Object?> j) => Tracker(
    id: j['id']! as String,
    name: j['name']! as String,
    fields: [for (final f in (j['fields']! as List).cast<Map<String, Object?>>()) fieldFrom(f)],
    entries: [for (final e in (j['entries']! as List).cast<Map<String, Object?>>()) entryFrom(e)],
    includedIn: j['includedIn'] as String?,
  );

  static Map<String, Object?> field(FieldDefinition f) => {
    'id': f.id,
    'name': f.name,
    'kind': f.kind.name,
    'role': f.role.name,
    'unit': f.unit,
    'consumptionUnit': f.consumptionUnit,
    'factor': f.factor,
    'intervalMonths': f.intervalMonths,
    'choices': f.choices,
    'formula': f.formula,
  };

  static FieldDefinition fieldFrom(Map<String, Object?> j) => FieldDefinition(
    id: j['id']! as String,
    name: j['name']! as String,
    kind: FieldKind.values.byName(j['kind']! as String),
    role: FieldRole.values.byName(j['role']! as String),
    unit: j['unit'] as String?,
    consumptionUnit: j['consumptionUnit'] as String?,
    factor: (j['factor']! as num).toDouble(),
    intervalMonths: (j['intervalMonths']! as num).toInt(),
    choices: [for (final c in j['choices']! as List) c as String],
    formula: j['formula'] as String?,
  );

  static Map<String, Object?> entry(Entry e) => {
    'id': e.id,
    'date': _day(e.date),
    'note': e.note,
    'meterChange': e.meterChange,
    'values': {for (final MapEntry(:key, :value) in e.values.entries) key: _value(value)},
  };

  static Entry entryFrom(Map<String, Object?> j) => Entry(
    id: j['id']! as String,
    date: DateTime.parse(j['date']! as String).toUtc(),
    note: j['note'] as String?,
    meterChange: j['meterChange'] as bool? ?? false,
    values: {
      for (final MapEntry(:key, :value) in (j['values']! as Map).cast<String, Object?>().entries)
        if (_valueFrom(value) case final Object v) key: v,
    },
  );

  static String _day(DateTime d) => DateTime.utc(d.year, d.month, d.day).toIso8601String();

  static Map<String, Object?> _value(Object v) => switch (v) {
    final num n => {'n': n},
    final DateTime d => {'d': _day(d)},
    final bool b => {'b': b},
    _ => {'t': v.toString()},
  };

  static Object? _valueFrom(Object? j) => switch (j) {
    {'n': final num n} => n,
    {'d': final String d} => DateTime.parse(d).toUtc(),
    {'b': final bool b} => b,
    {'t': final String t} => t,
    _ => null,
  };
}
