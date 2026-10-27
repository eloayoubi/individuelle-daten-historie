import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_release.dart';

/// Der laufende Build: Version, Build-Nummer (vergibt `fastlane beta`) und Vertriebsweg.
///
/// Einen Vertriebsweg haben nur Release-Builds aus TestFlight oder dem App Store. Debug, Simulator
/// und Android bleiben ohne – sie sperrt das Pflicht-Update nie (in der Entwicklung steht die
/// Build-Nummer auf 1).
class InstalledApp extends Equatable {
  const InstalledApp({required this.version, required this.build, this.channel});

  final String version;
  final int build;
  final ReleaseChannel? channel;

  static Future<InstalledApp> read() async {
    final info = await PackageInfo.fromPlatform();
    return InstalledApp(
      version: info.version,
      build: int.tryParse(info.buildNumber) ?? 0,
      channel: kReleaseMode ? channelOf(info.installerStore) : null,
    );
  }

  /// Vertriebsweg aus dem Installer: iOS meldet TestFlight am Sandbox-Beleg.
  static ReleaseChannel? channelOf(String? installerStore) => switch (installerStore) {
    'com.apple.testflight' => ReleaseChannel.testflight,
    'com.apple' => ReleaseChannel.appStore,
    _ => null,
  };

  @override
  List<Object?> get props => [version, build, channel];
}
