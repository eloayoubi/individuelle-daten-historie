import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

/// Neue UUID (Version 4) auf dem Gerät. Einträge bekommen ihre Id schon beim Erfassen – so lässt
/// sich ein offline gespeicherter Eintrag später beliebig oft hochladen, ohne doppelt zu landen.
String newId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return _format(bytes);
}

/// Feste UUID im Format von Version 5 (SHA-1 über „namespace/name“, kein RFC-Namensraum) aus
/// [namespace] und [name]: gleiche Eingaben ergeben immer dieselbe
/// Id. Der Umzug in die Cloud leitet so die Id jedes Eintrags aus neuem Tracker und alter Id ab –
/// ein wiederholter Versuch trifft dieselben Einträge, und eine alte Cloud-Kopie mit den
/// ursprünglichen Ids stört nicht.
String derivedId(String namespace, String name) {
  final bytes = sha1.convert(utf8.encode('$namespace/$name')).bytes.sublist(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return _format(bytes);
}

String _format(List<int> bytes) {
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
