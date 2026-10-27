import 'package:flutter/cupertino.dart';

import '../models/tracking.dart';

/// Icons im Stil von SF Symbols (CupertinoIcons) für die Symbole von Kategorien und Trackern.
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
    CategoryIcon.sport => CupertinoIcons.sportscourt_fill,
    CategoryIcon.music => CupertinoIcons.music_note_2,
    CategoryIcon.film => CupertinoIcons.film_fill,
    CategoryIcon.tv => CupertinoIcons.tv_fill,
    CategoryIcon.game => CupertinoIcons.gamecontroller_fill,
    CategoryIcon.headphones => CupertinoIcons.headphones,
    CategoryIcon.book => CupertinoIcons.book_fill,
    CategoryIcon.news => CupertinoIcons.news_solid,
    CategoryIcon.cloud => CupertinoIcons.cloud_fill,
    CategoryIcon.phone => CupertinoIcons.phone_fill,
    CategoryIcon.globe => CupertinoIcons.globe,
    CategoryIcon.gift => CupertinoIcons.gift_fill,
    CategoryIcon.bag => CupertinoIcons.bag_fill,
    CategoryIcon.ticket => CupertinoIcons.ticket_fill,
    CategoryIcon.paw => CupertinoIcons.paw_solid,
    CategoryIcon.capsule => CupertinoIcons.capsule_fill,
    CategoryIcon.person => CupertinoIcons.person_fill,
    CategoryIcon.briefcase => CupertinoIcons.briefcase_fill,
    CategoryIcon.building => CupertinoIcons.building_2_fill,
    CategoryIcon.wrench => CupertinoIcons.wrench_fill,
    CategoryIcon.lightbulb => CupertinoIcons.lightbulb_fill,
    CategoryIcon.tree => CupertinoIcons.tree,
    CategoryIcon.airplane => CupertinoIcons.airplane,
    CategoryIcon.bus => CupertinoIcons.bus,
    CategoryIcon.tram => CupertinoIcons.tram_fill,
    CategoryIcon.creditcard => CupertinoIcons.creditcard_fill,
    CategoryIcon.money => CupertinoIcons.money_euro_circle_fill,
  };
}
