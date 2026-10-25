import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/supabase_api.dart';
import '../../auth/data/auth_repository.dart';
import 'categories_repository.dart';

/// Liest Kategorien samt Trackern, Feldern, Einträgen und Werten in einer Abfrage und schreibt
/// Änderungen direkt in die Tabellen (RLS prüft die Rechte) bzw. per RPC, wo mehrere Zeilen
/// zusammengehören (`create_category`, `reorder_categories`).
class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(this._api, this._auth);

  final SupabaseApi _api;
  final AuthRepository _auth;
  final _changes = StreamController<void>.broadcast();

  /// Realtime: Änderungen anderer Mitglieder (oder anderer Geräte) lösen ein Neuladen aus.
  void Function()? _unsubscribe;
  Timer? _debounce;

  static const _liveTables = ['categories', 'category_members', 'trackers', 'fields', 'entries', 'entry_values'];

  void _listenLive() {
    _unsubscribe ??= _api.onChanges(_liveTables, () {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () => _changes.add(null));
    });
  }

  static const _select =
      'id, name, icon, swatch, template_key, archived_at, '
      'category_members(user_id, role, sort, profiles(display_name)), '
      'trackers!trackers_category_id_fkey(id, name, sort, included_in, '
      'fields(id, name, kind, role, unit, consumption_unit, factor, interval_months, choices, formula, sort), '
      'entries(id, occurred_on, note, meter_change, period_start, period_end, created_by, entry_values(field_id, num, txt, dat, flag)))';

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Category>> loadCategories() async {
    await _auth.ensureSignedIn();
    _listenLive();
    final rows = await _api.table('categories').select(_select).isFilter('trackers.archived_at', null).isFilter('trackers.fields.archived_at', null);
    // Reihenfolge ist je Mitglied (category_members.sort), danach nach Name.
    final sorted = [for (final row in rows) (_mySort(row), _category(row))]
      ..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase()));
    return [for (final (_, category) in sorted) category];
  }

  @override
  Future<Category?> loadCategory(String id) async {
    await _auth.ensureSignedIn();
    final row = await _api
        .table('categories')
        .select(_select)
        .eq('id', id)
        .isFilter('trackers.archived_at', null)
        .isFilter('trackers.fields.archived_at', null)
        .maybeSingle();
    return row == null ? null : _category(row);
  }

  @override
  Future<String> createCategory(CategoryDraft draft) => _write(() async {
    final id = await _api.rpc<String>(
      'create_category',
      params: {
        'p_name': draft.name,
        'p_icon': draft.icon.name,
        'p_swatch': draft.swatch.name,
        'p_template_key': draft.templateKey,
        'p_trackers': [
          for (final t in draft.trackers) {'name': t.name, 'fields': [for (final f in t.fields) _fieldJson(f)]},
        ],
      },
    );
    return id;
  });

  @override
  Future<void> updateCategory(String id, {required String name, required CategoryIcon icon, required CategorySwatch swatch}) =>
      _write(() => _api.table('categories').update({'name': name, 'icon': icon.name, 'swatch': swatch.name}).eq('id', id));

  @override
  Future<void> setCategoryArchived(String id, {required bool archived}) => _write(
    () => _api.table('categories').update({'archived_at': archived ? DateTime.now().toUtc().toIso8601String() : null}).eq('id', id),
  );

  @override
  Future<void> reorderCategories(List<String> ids) => _write(() => _api.rpc<void>('reorder_categories', params: {'p_ids': ids}));

  @override
  Future<String> createTracker(String categoryId, String name, {required int sort}) => _write(() async {
    final row = await _api.table('trackers').insert({'category_id': categoryId, 'name': name, 'sort': sort}).select('id').single();
    return row['id'] as String;
  });

  @override
  Future<void> renameTracker(String id, String name) => _write(() => _api.table('trackers').update({'name': name}).eq('id', id));

  @override
  Future<void> setTrackerIncludedIn(String id, String? categoryId) => _write(() => _api.table('trackers').update({'included_in': categoryId}).eq('id', id));

  @override
  Future<void> archiveTracker(String id) =>
      _write(() => _api.table('trackers').update({'archived_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id));

  @override
  Future<String> createField(String trackerId, FieldDraft draft, {required int sort}) => _write(() async {
    final row = await _api.table('fields').insert({..._fieldJson(draft), 'tracker_id': trackerId, 'sort': sort}).select('id').single();
    return row['id'] as String;
  });

  @override
  Future<void> updateField(String id, FieldDraft draft) => _write(() => _api.table('fields').update(_fieldJson(draft)).eq('id', id));

  @override
  Future<void> archiveField(String id) =>
      _write(() => _api.table('fields').update({'archived_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id));

  @override
  Future<void> saveEntry(String trackerId, Entry entry) => _write(
    () => _rejectable(
      () => _api.rpc<void>(
        'save_entry',
        params: {
          'p_id': entry.id,
          'p_tracker': trackerId,
          'p_occurred_on': _isoDay(entry.date),
          'p_note': entry.note,
          'p_meter_change': entry.meterChange,
          'p_period_start': entry.hasPeriod ? _isoDay(entry.periodStart!) : null,
          'p_period_end': entry.hasPeriod ? _isoDay(entry.periodEnd!) : null,
          'p_values': [
            for (final MapEntry(:key, :value) in entry.values.entries)
              {
                'field_id': key,
                ...switch (value) {
                  final num n => {'num': n},
                  final DateTime d => {'dat': _isoDay(d)},
                  final bool b => {'flag': b},
                  _ => {'txt': value.toString()},
                },
              },
          ],
        },
      ),
    ),
  );

  @override
  Future<void> deleteEntry(String trackerId, String entryId) => _write(
    () => _rejectable(
      () async => confirmDeleted(
        await _api.table('entries').delete().eq('id', entryId).select('id'),
        () async => await _api.table('entries').select('id').eq('id', entryId).maybeSingle() != null,
      ),
    ),
  );

  @override
  Future<String> createInvite(String categoryId, MemberRole role) => _write(
    () async => _api.rpc<String>('create_category_invite', params: {'p_category': categoryId, 'p_role': role.name}),
  );

  @override
  Future<String> acceptInvite(String code) => _write(() async {
    try {
      return await _api.rpc<String>('accept_category_invite', params: {'p_code': code.trim()});
    } on PostgrestException catch (e) {
      throw inviteError(e);
    }
  });

  /// Eigentümer ohne Cloud-Abo (P0064): Der Code bleibt gültig, Beitreten geht erst wieder mit Abo.
  /// Alles andere heißt: Code unbekannt, abgelaufen oder schon benutzt.
  @visibleForTesting
  static WriteRejected inviteError(PostgrestException e) => WriteRejected(e.code == 'P0064' ? WriteRejected.cloudRequired : e.message);

  @override
  Future<void> setMemberRole(String categoryId, String userId, MemberRole role) =>
      _write(() => _api.table('category_members').update({'role': role.name}).eq('category_id', categoryId).eq('user_id', userId));

  @override
  Future<void> removeMember(String categoryId, String userId) => _write(
    () async => confirmDeleted(
      await _api.table('category_members').delete().eq('category_id', categoryId).eq('user_id', userId).select('user_id'),
      () async => await _api.table('category_members').select('user_id').eq('category_id', categoryId).eq('user_id', userId).maybeSingle() != null,
    ),
  );

  @override
  Future<void> leaveCategory(String categoryId) => removeMember(categoryId, _auth.userId ?? '');

  /// Die Offline-Schicht (`OfflineCategoriesRepository`) führt die Warteschlange; hier wird direkt gesendet.
  @override
  SyncState get syncState => const SyncState();

  @override
  Future<void> sync() async {}

  @override
  void acknowledgeRejected() {}

  /// Fehler, bei denen erneutes Senden nicht hilft: Datenfehler (22), Integrität (23), Rechte (42),
  /// eigene `raise exception` (P0). Netzwerk- und Serverfehler bleiben vorübergehend.
  static final _permanent = RegExp(r'^(22|23|42|P0)');

  /// Fehlende Schreibrechte (42501) und fehlendes Cloud-Abo (P0064) können vorübergehend sein: Das
  /// Abo ist abgelaufen oder noch nicht verbucht. Einträge in der Warteschlange sind dann oft die
  /// einzige Kopie – sie bleiben liegen ([WriteHeld]), bis das Abo wieder läuft oder alles aufs Gerät
  /// umzieht; die übrigen gehen weiter raus.
  static const _maybeTemporary = {'42501', 'P0064'};

  /// Was die Offline-Schicht aus einem Fehler beim Schreiben eines Eintrags macht: [WriteRejected]
  /// (verwerfen), [WriteHeld] (behalten, Rest senden) oder `null` (vorübergehend, später erneut).
  @visibleForTesting
  static Exception? entryWriteError(PostgrestException e) {
    final code = e.code ?? '';
    if (_maybeTemporary.contains(code)) return WriteHeld(e.message);
    if (_permanent.hasMatch(code)) return WriteRejected(e.message);
    return null;
  }

  static Future<void> _rejectable(Future<void> Function() write) async {
    try {
      await write();
    } on PostgrestException catch (e) {
      throw entryWriteError(e) ?? e;
    }
  }

  /// RLS lässt verbotenes Löschen nicht scheitern, es trifft nur keine Zeile. Ist nichts gelöscht
  /// und die Zeile noch da ([stillThere]), war es nicht erlaubt; ist sie schon weg, ist es erledigt.
  @visibleForTesting
  static Future<void> confirmDeleted(List<Object?> deleted, Future<bool> Function() stillThere) async {
    if (deleted.isEmpty && await stillThere()) throw const WriteRejected('delete_not_allowed');
  }

  static String _isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Angemeldet schreiben, danach alle Ansichten neu laden lassen.
  Future<T> _write<T>(Future<T> Function() write) async {
    await _auth.ensureSignedIn();
    final result = await write();
    _changes.add(null);
    return result;
  }

  static Map<String, dynamic> _fieldJson(FieldDraft f) => {
    'name': f.name,
    'kind': _snake(f.kind.name),
    'role': _snake(f.role.name),
    'unit': f.unit,
    'consumption_unit': f.consumptionUnit,
    'factor': f.factor,
    'interval_months': f.intervalMonths,
    'choices': f.choices,
    'formula': f.formula,
  };

  int _mySort(Map<String, dynamic> row) {
    final me = _auth.userId;
    final mine = (row['category_members'] as List).cast<Map<String, dynamic>>().where((m) => m['user_id'] == me).firstOrNull;
    return (mine?['sort'] as num?)?.toInt() ?? 0;
  }

  Category _category(Map<String, dynamic> row) {
    final me = _auth.userId;
    final members = (row['category_members'] as List).cast<Map<String, dynamic>>();
    final mine = members.where((m) => m['user_id'] == me).firstOrNull;
    final trackers = [...(row['trackers'] as List).cast<Map<String, dynamic>>()]..sort(_bySort);
    return Category(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: _enum(CategoryIcon.values, row['icon'] as String, CategoryIcon.star),
      swatch: _enum(CategorySwatch.values, row['swatch'] as String, CategorySwatch.indigo),
      templateKey: row['template_key'] as String?,
      archivedAt: switch (row['archived_at']) {
        final String iso => DateTime.parse(iso),
        _ => null,
      },
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
    final fields = [...(row['fields'] as List).cast<Map<String, dynamic>>()]..sort(_bySort);
    return Tracker(
      id: row['id'] as String,
      name: row['name'] as String,
      includedIn: row['included_in'] as String?,
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
    periodStart: switch (row['period_start']) {
      final String d => _date(d),
      _ => null,
    },
    periodEnd: switch (row['period_end']) {
      final String d => _date(d),
      _ => null,
    },
    createdBy: row['created_by'] as String?,
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

  static String _snake(String camel) => camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}
