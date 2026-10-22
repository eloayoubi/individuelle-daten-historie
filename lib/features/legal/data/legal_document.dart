/// Rechtstexte in der App, je Sprache als Markdown unter `assets/legal/`.
enum LegalDocument {
  privacy,
  terms,
  imprint;

  /// Deutsch für Deutsch, sonst Englisch.
  String asset(String languageCode) => 'assets/legal/${name}_${languageCode == 'de' ? 'de' : 'en'}.md';
}

/// Ein Block des (bewusst kleinen) Markdown-Teils, den die Rechtstexte nutzen.
sealed class LegalBlock {
  const LegalBlock(this.text);

  final String text;
}

class LegalTitle extends LegalBlock {
  const LegalTitle(super.text);
}

class LegalHeading extends LegalBlock {
  const LegalHeading(super.text);
}

class LegalParagraph extends LegalBlock {
  const LegalParagraph(super.text);
}

class LegalBullet extends LegalBlock {
  const LegalBullet(super.text);
}

/// `# Titel`, `## Abschnitt`, `- Punkt`, Absätze durch Leerzeilen; Zeilen eines Absatzes bleiben
/// Zeilen (Anschriften). Mehr braucht es für Datenschutz, Nutzungsbedingungen und Impressum nicht.
List<LegalBlock> parseLegal(String markdown) {
  final blocks = <LegalBlock>[];
  final paragraph = <String>[];
  void flush() {
    if (paragraph.isNotEmpty) blocks.add(LegalParagraph(paragraph.join('\n')));
    paragraph.clear();
  }

  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('## ')) {
      flush();
      blocks.add(LegalHeading(line.substring(3).trim()));
    } else if (line.startsWith('# ')) {
      flush();
      blocks.add(LegalTitle(line.substring(2).trim()));
    } else if (line.startsWith('- ')) {
      flush();
      blocks.add(LegalBullet(line.substring(2).trim()));
    } else if (blocks.lastOrNull is LegalBullet && paragraph.isEmpty && raw.startsWith('  ')) {
      // Fortsetzung eines Punkts (eingerückt).
      final last = blocks.removeLast();
      blocks.add(LegalBullet('${last.text} $line'));
    } else {
      paragraph.add(line);
    }
  }
  flush();
  return blocks;
}
