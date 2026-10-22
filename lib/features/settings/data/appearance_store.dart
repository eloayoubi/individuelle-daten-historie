import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Merkt sich die gewählte Darstellung (Automatisch, Hell, Dunkel) auf dem Gerät.
abstract interface class AppearanceStore {
  Future<ThemeMode?> read();
  Future<void> write(ThemeMode mode);
}

/// Der Name des [ThemeMode] in einer Textdatei im App-Support-Ordner.
class FileAppearanceStore implements AppearanceStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/appearance.txt');

  @override
  Future<ThemeMode?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      return ThemeMode.values.asNameMap()[(await f.readAsString()).trim()];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(ThemeMode mode) async {
    try {
      await (await _file()).writeAsString(mode.name);
    } catch (_) {
      // Ohne Speicher gilt die Wahl bis zum nächsten Start.
    }
  }
}

/// Für Mock-Modus und Tests.
class MemoryAppearanceStore implements AppearanceStore {
  ThemeMode? _mode;

  @override
  Future<ThemeMode?> read() async => _mode;

  @override
  Future<void> write(ThemeMode mode) async => _mode = mode;
}
