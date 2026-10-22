import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/models/tracking.dart';
import 'package:kostenkurve/core/models/tracking_codec.dart';
import 'package:kostenkurve/core/utils/ids.dart';
import 'package:kostenkurve/core/utils/json_store.dart';
import 'package:kostenkurve/core/utils/numbers.dart';
import 'package:kostenkurve/features/categories/data/mock_categories_repository.dart';

void main() {
  group('newId', () {
    test('liefert gültige, eindeutige UUIDs (Version 4)', () {
      final ids = {for (var i = 0; i < 500; i++) newId()};
      expect(ids, hasLength(500));
      for (final id in ids.take(20)) {
        expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      }
    });
  });

  group('parseNumber', () {
    double? de(String t) => parseNumber(t, decimalSeparator: ',');
    double? en(String t) => parseNumber(t, decimalSeparator: '.');

    test('Komma ist in Deutsch die Dezimalstelle, Punkte sind Tausender', () {
      expect(de('10,35'), 10.35);
      expect(de('47.100'), 47100);
      expect(de('47.100,5'), 47100.5);
      expect(de('1.250'), 1250);
      expect(de(' 1 250 '), 1250);
    });

    test('ein Punkt ohne Tausender-Form ist eine Dezimalstelle (Android-Tastatur)', () {
      expect(de('0.329'), 0.329);
      expect(de('10.5'), 10.5);
      expect(de('-62'), -62);
    });

    test('Englisch umgekehrt', () {
      expect(en('47,100'), 47100);
      expect(en('0.329'), 0.329);
      expect(en('0,329'), 0.329);
    });

    test('leer oder Unsinn ergibt null', () {
      expect(de(''), isNull);
      expect(de('abc'), isNull);
    });

    test('formatiert Eingaben ohne Tausenderpunkte', () {
      expect(formatNumberInput(47100, decimalSeparator: ','), '47100');
      expect(formatNumberInput(0.329, decimalSeparator: ','), '0,329');
      expect(formatNumberInput(10.5, decimalSeparator: '.'), '10.5');
    });
  });

  group('TrackingCodec', () {
    test('Kategorien überstehen den Weg durch JSON verlustfrei', () async {
      final store = MemoryJsonStore();
      await store.write([for (final c in MockCategoriesRepository.categories) TrackingCodec.category(c)]);
      final back = [for (final j in (await store.read())! as List) TrackingCodec.categoryFrom((j as Map).cast<String, Object?>())];
      expect(back, MockCategoriesRepository.categories);
    });

    test('Werte behalten ihren Typ', () {
      final entry = Entry(id: 'e', date: DateTime.utc(2026, 10, 1), values: {'n': 1.5, 'i': 3, 't': 'Text', 'd': DateTime.utc(2027, 3, 31), 'b': true}, note: 'Notiz', meterChange: true);
      expect(TrackingCodec.entryFrom(TrackingCodec.entry(entry)), entry);
    });
  });
}
