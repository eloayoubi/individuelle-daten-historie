import '../../../core/network/supabase_api.dart';
import '../../auth/data/auth_repository.dart';
import 'categories_repository.dart';

/// Liest Kategorien samt Trackern, Feldern, Einträgen und Werten in einer Abfrage.
/// Was sichtbar ist, entscheidet RLS: eigene Kategorien und solche, in denen ich Mitglied bin.
class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(this._api, this._auth);

  final SupabaseApi _api;
  final AuthRepository _auth;

  static const _select =
      'id, name, icon, swatch, '
      'category_members(user_id, role, profiles(display_name)), '
      'trackers(id, name, sort, '
      'fields(id, name, kind, role, unit, consumption_unit, factor, interval_months, choices, formula, sort), '
      'entries(id, occurred_on, note, meter_change, entry_values(field_id, num, txt, dat, flag)))';

  @override
  Future<List<Category>> loadCategories() async {
    await _auth.ensureSignedIn();
    final me = _auth.userId;
    final rows = await _api
        .table('categories')
        .select(_select)
        .isFilter('archived_at', null)
        .isFilter('trackers.archived_at', null)
        .isFilter('trackers.fields.archived_at', null)
        .order('sort');
    return [for (final row in rows) _category(row, me)];
  }

  static Category _category(Map<String, dynamic> row, String? me) {
    final members = [for (final m in (row['category_members'] as List).cast<Map<String, dynamic>>()) m];
    final mine = members.where((m) => m['user_id'] == me).firstOrNull;
    final trackers = [for (final t in (row['trackers'] as List).cast<Map<String, dynamic>>()) t]..sort(_bySort);
    return Category(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: _enum(CategoryIcon.values, row['icon'] as String, CategoryIcon.star),
      swatch: _enum(CategorySwatch.values, row['swatch'] as String, CategorySwatch.indigo),
      myRole: mine == null ? MemberRole.viewer : _enum(MemberRole.values, mine['role'] as String, MemberRole.viewer),
      sharedWith: [
        for (final m in members)
          if (m['user_id'] != me)
            CategoryMember(
              userId: m['user_id'] as String,
              name: ((m['profiles'] as Map?)?['display_name'] as String?) ?? '',
              role: _enum(MemberRole.values, m['role'] as String, MemberRole.viewer),
            ),
      ],
      trackers: [for (final t in trackers) _tracker(t)],
    );
  }

  static Tracker _tracker(Map<String, dynamic> row) {
    final fields = [for (final f in (row['fields'] as List).cast<Map<String, dynamic>>()) f]..sort(_bySort);
    return Tracker(
      id: row['id'] as String,
      name: row['name'] as String,
      fields: [for (final f in fields) _field(f)],
      entries: [for (final e in (row['entries'] as List).cast<Map<String, dynamic>>()) _entry(e)],
    );
  }

  static FieldDefinition _field(Map<String, dynamic> row) => FieldDefinition(
    id: row['id'] as String,
    name: row['name'] as String,
    kind: _enum(FieldKind.values, row['kind'] as String, FieldKind.text),
    role: _enum(FieldRole.values, row['role'] as String, FieldRole.info),
    unit: row['unit'] as String?,
    consumptionUnit: row['consumption_unit'] as String?,
    factor: (row['factor'] as num?)?.toDouble() ?? 1,
    intervalMonths: (row['interval_months'] as num?)?.toInt() ?? 1,
    choices: [for (final c in (row['choices'] as List?) ?? const []) c as String],
    formula: row['formula'] as String?,
  );

  static Entry _entry(Map<String, dynamic> row) => Entry(
    id: row['id'] as String,
    date: _date(row['occurred_on'] as String),
    note: row['note'] as String?,
    meterChange: row['meter_change'] as bool? ?? false,
    values: {
      for (final v in (row['entry_values'] as List).cast<Map<String, dynamic>>())
        if (_value(v) case final Object value) v['field_id'] as String: value,
    },
  );

  /// Genau eine der typisierten Spalten ist gesetzt.
  static Object? _value(Map<String, dynamic> v) => switch (v) {
    {'num': final num n} => n,
    {'txt': final String s} => s,
    {'dat': final String d} => _date(d),
    {'flag': final bool b} => b,
    _ => null,
  };

  static DateTime _date(String iso) {
    final d = DateTime.parse(iso);
    return DateTime.utc(d.year, d.month, d.day);
  }

  static int _bySort(Map<String, dynamic> a, Map<String, dynamic> b) => ((a['sort'] as num?) ?? 0).compareTo((b['sort'] as num?) ?? 0);

  /// Postgres-Enums sind snake_case (`meter_reading`), Dart-Enums camelCase (`meterReading`).
  static T _enum<T extends Enum>(List<T> values, String raw, T fallback) {
    final key = raw.replaceAll('_', '').toLowerCase();
    return values.where((v) => v.name.toLowerCase() == key).firstOrNull ?? fallback;
  }
}
