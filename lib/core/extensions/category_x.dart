import 'package:flutter/cupertino.dart';

import '../models/tracking.dart';

/// Icons im Stil von SF Symbols (CupertinoIcons) für die Kategorie-Symbole.
extension CategoryIconX on CategoryIcon {
  IconData get data => switch (this) {
    CategoryIcon.bolt => CupertinoIcons.bolt_fill,
    CategoryIcon.flame => CupertinoIcons.flame_fill,
    CategoryIcon.drop => CupertinoIcons.drop_fill,
    CategoryIcon.house => CupertinoIcons.house_fill,
    CategoryIcon.car => CupertinoIcons.car_fill,
    CategoryIcon.wifi => CupertinoIcons.wifi,
    CategoryIcon.shield => CupertinoIcons.shield_fill,
    CategoryIcon.play => CupertinoIcons.play_rectangle_fill,
    CategoryIcon.cart => CupertinoIcons.cart_fill,
    CategoryIcon.heart => CupertinoIcons.heart_fill,
    CategoryIcon.star => CupertinoIcons.star_fill,
    CategoryIcon.doc => CupertinoIcons.doc_text_fill,
  };
}
