import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Teilen-Sheet des Systems. Auf dem iPad braucht es den Ursprung (das antippte Element), sonst
/// stürzt das Popover ab – deshalb immer mit dem `context` des Knopfs aufrufen.
abstract final class AppShare {
  static Future<void> text(BuildContext context, String text) => SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: _origin(context)));

  static Future<void> files(BuildContext context, List<XFile> files, {String? subject}) =>
      SharePlus.instance.share(ShareParams(files: files, subject: subject, sharePositionOrigin: _origin(context)));

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  }
}
