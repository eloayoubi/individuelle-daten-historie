import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/categories/data/categories_repository.dart';
import 'package:kostenkurve/features/categories/data/supabase_categories_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  group('Fehler beim Schreiben von Einträgen', () {
    Object? classify(String? code) => SupabaseCategoriesRepository.entryWriteError(PostgrestException(message: 'x', code: code));

    test('Datenfehler und Integrität: endgültig abgelehnt', () {
      expect(classify('23514'), isA<WriteRejected>());
      expect(classify('22P02'), isA<WriteRejected>());
    });

    test('fehlende Rechte und fehlendes Abo: liegen lassen, Rest weiter senden', () {
      expect(classify('42501'), isA<WriteHeld>());
      expect(classify('P0064'), isA<WriteHeld>());
    });

    test('Server- und unbekannte Fehler: vorübergehend', () {
      expect(classify('57014'), isNull);
      expect(classify(null), isNull);
    });
  });

  group('Einladung annehmen', () {
    test('Eigentümer ohne Cloud-Abo (P0064): cloud_required', () {
      final error = SupabaseCategoriesRepository.inviteError(const PostgrestException(message: 'cloud_required', code: 'P0064'));
      expect(error.message, WriteRejected.cloudRequired);
    });

    test('alles andere: Code ungültig', () {
      final error = SupabaseCategoriesRepository.inviteError(const PostgrestException(message: 'Einladung ungültig oder abgelaufen', code: 'P0002'));
      expect(error.message, isNot(WriteRejected.cloudRequired));
    });
  });

  group('Löschen, das RLS still verhindert', () {
    test('nichts gelöscht, Zeile noch da: abgelehnt', () async {
      await expectLater(SupabaseCategoriesRepository.confirmDeleted(const [], () async => true), throwsA(isA<WriteRejected>()));
    });

    test('nichts gelöscht, Zeile schon weg: erledigt', () async {
      await expectLater(SupabaseCategoriesRepository.confirmDeleted(const [], () async => false), completes);
    });

    test('gelöscht: ohne weitere Abfrage erledigt', () async {
      var asked = false;
      await SupabaseCategoriesRepository.confirmDeleted(const [{'id': 'e1'}], () async => asked = true);
      expect(asked, isFalse);
    });
  });

  group('Eintrag löschen mit Belegen', () {
    test('Pfade vorher lesen, Dateien nach dem Löschen entfernen', () async {
      final steps = <String>[];
      await SupabaseCategoriesRepository.deleteWithFiles(
        files: () async => (steps..add('lesen')).isEmpty ? const [] : const ['c/e/a.jpg'],
        delete: () async => steps.add('löschen'),
        remove: (paths) async => steps.add('entfernen $paths'),
      );
      expect(steps, ['lesen', 'löschen', 'entfernen [c/e/a.jpg]']);
    });

    test('Löschen scheitert: Dateien bleiben', () async {
      var removed = false;
      await expectLater(
        SupabaseCategoriesRepository.deleteWithFiles(
          files: () async => const ['c/e/a.jpg'],
          delete: () async => throw const WriteRejected('delete_not_allowed'),
          remove: (_) async => removed = true,
        ),
        throwsA(isA<WriteRejected>()),
      );
      expect(removed, isFalse);
    });

    test('Dateien entfernen scheitert: der Eintrag gilt trotzdem als gelöscht', () async {
      await expectLater(
        SupabaseCategoriesRepository.deleteWithFiles(files: () async => const ['c/e/a.jpg'], delete: () async {}, remove: (_) async => throw Exception('offline')),
        completes,
      );
    });

    test('ohne Belege: nichts zu entfernen', () async {
      var removed = false;
      await SupabaseCategoriesRepository.deleteWithFiles(files: () async => const [], delete: () async {}, remove: (_) async => removed = true);
      expect(removed, isFalse);
    });
  });
}
