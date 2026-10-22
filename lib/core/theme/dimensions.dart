import 'package:flutter/widgets.dart';

/// Abstände im 4er-Raster, wie in Apples Layouts.
abstract final class Spacing {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Seitlicher Standardabstand aller Screens (iOS-Rand).
  static const screen = EdgeInsets.symmetric(horizontal: l);

  /// Platz unter dem Inhalt, damit die schwebende Tab-Leiste nichts verdeckt.
  static const tabBarClearance = 112.0;
}

/// Eckenradien; Karten folgen den weichen, großen Radien von iOS 26.
abstract final class Radii {
  static const xs = 6.0;
  static const s = 10.0;
  static const m = 14.0;
  static const l = 20.0;
  static const card = 26.0;
  static const sheet = 32.0;
  static const pill = 999.0;
}

/// Feste Größen, die mehrfach vorkommen.
abstract final class Sizes {
  /// Mindestgröße für Touch-Ziele (HIG: 44 pt).
  static const tap = 44.0;
  static const buttonHeight = 50.0;
  static const rowMinHeight = 52.0;
  static const iconTile = 30.0;
  static const iconTileLarge = 40.0;
  static const tabBarHeight = 64.0;
  static const curveHeight = 96.0;
  static const shareBarHeight = 8.0;
  static const grabber = Size(36, 5);
}

/// Dauer und Kurven für Bewegung.
abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 260);
  static const toast = Duration(milliseconds: 2600);
  static const curve = Curves.easeOutCubic;

  /// Weichzeichner hinter Glasflächen.
  static const glassBlur = 24.0;

  /// Antippen: leicht kleiner und blasser, statt Material-Welle.
  static const pressedScale = 0.97;
  static const pressedOpacity = 0.7;
}
