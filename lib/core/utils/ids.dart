import 'dart:math';

final _random = Random.secure();

/// Neue UUID (Version 4) auf dem Gerät. Einträge bekommen ihre Id schon beim Erfassen – so lässt
/// sich ein offline gespeicherter Eintrag später beliebig oft hochladen, ohne doppelt zu landen.
String newId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
