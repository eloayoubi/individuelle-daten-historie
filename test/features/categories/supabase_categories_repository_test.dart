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
}
