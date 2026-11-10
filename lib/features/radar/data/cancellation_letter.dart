import 'package:intl/intl.dart';

import '../../../core/models/tracking.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Kündigungsschreiben als Vorlage – entsteht auf dem Gerät und verlässt die App nur, wenn der Nutzer
/// es teilt oder kopiert.
///
/// Es kündigt „zum nächstmöglichen Zeitpunkt“: Welche Frist gilt, weiß die App nicht. Name und
/// Anschrift sind Platzhalter, die App kennt sie nicht.
abstract final class CancellationLetter {
  /// Steuerzeichen (C0, DEL, C1), Zeilen- und Absatztrenner und Zeichen, die die Schreibrichtung
  /// umkehren (ALM, LRM, RLM, LRE … RLO, LRI … PDI): In geteilten Kategorien stammen Namen und Details
  /// auch von anderen – sie sollen im Schreiben weder Zeilen einfügen noch Text optisch verdrehen.
  ///
  /// Dazu unsichtbare Zeichen (weicher Trennstrich, Zeichen ohne Breite, BOM, Anmerkungs- und
  /// Tag-Zeichen): Was man im Schreiben sieht, ist auch, was kopiert und geteilt wird.
  static bool _unsafe(int rune) =>
      rune < 0x20 ||
      (rune >= 0x7F && rune <= 0x9F) ||
      rune == 0x00AD ||
      rune == 0x034F ||
      rune == 0x061C ||
      rune == 0x180E ||
      (rune >= 0x200B && rune <= 0x200F) ||
      (rune >= 0x2028 && rune <= 0x202E) ||
      (rune >= 0x2060 && rune <= 0x2069) ||
      rune == 0xFEFF ||
      (rune >= 0xFFF9 && rune <= 0xFFFB) ||
      (rune >= 0xE0000 && rune <= 0xE007F);

  /// Länger wird keine Zeile aus Namen und Details, und mehr Details nennt das Schreiben nicht.
  static const maxLineLength = 200;
  static const maxDetails = 10;

  /// [text] als eine Zeile: unsichere Zeichen werden zu Leerzeichen, nach [maxLineLength] Zeichen ist Schluss.
  static String _line(String text) =>
      String.fromCharCodes([for (final rune in text.runes.take(maxLineLength)) _unsafe(rune) ? 0x20 : rune]).trim();

  /// Text-Details des Trackers mit Wert (Anbieter, Vertragsnummer), je als „Name: Wert“.
  static List<String> details(Tracker tracker) => [
    for (final field in tracker.detailFields)
      if (field.kind == FieldKind.text)
        if (tracker.detailValue(field.id) case final String value when _line(value).isNotEmpty) '${_line(field.name)}: ${_line(value)}',
  ].take(maxDetails).toList();

  static String build(AppLocalizations l, {required Category category, required Tracker tracker, required DateTime today}) {
    final name = _line(tracker.name), group = _line(category.name);
    return [
      l.radarLetterSender,
      '',
      DateFormat.yMd(l.localeName).format(today),
      '',
      l.radarLetterSubject(group.isEmpty || group == name ? name : '$name ($group)'),
      ...details(tracker),
      '',
      l.radarLetterBody,
    ].join('\n');
  }
}
