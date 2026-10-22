import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/legal/data/legal_document.dart';

void main() {
  test('jeder Rechtstext gibt es auf Deutsch und Englisch, mit Titel', () {
    for (final doc in LegalDocument.values) {
      for (final lang in ['de', 'en']) {
        final file = File(doc.asset(lang));
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(parseLegal(file.readAsStringSync()).first, isA<LegalTitle>(), reason: file.path);
      }
    }
    expect(LegalDocument.privacy.asset('fr'), 'assets/legal/privacy_en.md');
  });

  test('Markdown: Titel, Abschnitte, Punkte, Absätze mit Zeilen', () {
    final blocks = parseLegal('# Titel\n\n## Abschnitt\nZeile eins\nZeile zwei\n\n- Punkt eins\n  weiter\n- Punkt zwei\n\nSchluss');
    expect([for (final b in blocks) b.runtimeType], [LegalTitle, LegalHeading, LegalParagraph, LegalBullet, LegalBullet, LegalParagraph]);
    expect(blocks[2].text, 'Zeile eins\nZeile zwei');
    expect(blocks[3].text, 'Punkt eins weiter');
  });
}
