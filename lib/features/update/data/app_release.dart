import 'package:equatable/equatable.dart';

/// Vertriebsweg eines Builds – Spalte `channel` in `app_releases`.
enum ReleaseChannel {
  testflight('testflight'),
  appStore('app_store');

  const ReleaseChannel(this.key);

  final String key;
}

/// Neuester Build, den Nutzer auf einem Vertriebsweg laden können (Tabelle `app_releases`).
class AppRelease extends Equatable {
  const AppRelease({required this.build, this.url});

  final int build;

  /// Wo es ihn gibt (öffentlicher TestFlight-Link); ohne nimmt die App ihren eigenen.
  final String? url;

  @override
  List<Object?> get props => [build, url];
}

abstract interface class ReleaseRepository {
  /// Neuester Build auf [channel], `null`, wenn der Server keinen kennt.
  Future<AppRelease?> latest(ReleaseChannel channel);
}

/// Ohne Backend: nie ein Pflicht-Update.
class NoReleaseRepository implements ReleaseRepository {
  const NoReleaseRepository();

  @override
  Future<AppRelease?> latest(ReleaseChannel channel) async => null;
}
