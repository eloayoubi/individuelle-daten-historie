import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../../core/config/app_config.dart';

/// Einladungslinks `de.eloayoubi.kostenkurve://invite?code=K7Q2M9X4TA`: beim Start und während die
/// App läuft. [codes] liefert die Codes, die App öffnet dafür das Beitreten-Sheet.
abstract interface class InviteLinks {
  Stream<String> get codes;

  void start();

  /// Link zum Teilen.
  static String linkFor(String code) => '${AppConfig.appScheme}://invite?code=$code';

  /// Code aus einem Link, `null` wenn es keiner ist.
  static String? codeOf(Uri uri) {
    if (uri.scheme != AppConfig.appScheme || uri.host != 'invite') return null;
    final code = uri.queryParameters['code']?.trim().toUpperCase();
    return code == null || code.isEmpty ? null : code;
  }
}

class AppInviteLinks implements InviteLinks {
  final _codes = StreamController<String>.broadcast();
  final _links = AppLinks();
  StreamSubscription<Uri>? _subscription;

  @override
  Stream<String> get codes => _codes.stream;

  @override
  void start() {
    _subscription ??= _links.uriLinkStream.listen((uri) {
      if (InviteLinks.codeOf(uri) case final String code) _codes.add(code);
    });
  }
}

/// Für Tests und Mock-Modus ohne Plattform.
class NoInviteLinks implements InviteLinks {
  const NoInviteLinks();

  @override
  Stream<String> get codes => const Stream.empty();

  @override
  void start() {}
}
