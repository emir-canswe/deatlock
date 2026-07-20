import 'package:flutter/widgets.dart';

/// Motion parameters for Deadlock game to make the gameplay feel "alive".
class Motion {
  // Screen and level load
  static const Duration levelLoadDuration = Duration(milliseconds: 260);
  static const Curve levelLoadCurve = Curves.easeOutBack;

  // Block press and release
  static const Duration holdDuration = Duration(milliseconds: 90);
  static const Curve holdCurve = Curves.easeOut;

  // Snap to grid (unified to be incredibly snappy and responsive)
  static const Duration snapDuration = Duration(milliseconds: 140);
  static const Curve snapCurve = Curves.easeOutCubic;

  // Block bump / shake
  static const Duration shakeDuration = Duration(milliseconds: 180);

  // Counter pop
  static const Duration countPopDuration = Duration(milliseconds: 140);

  // Win animation
  static const Duration winDuration = Duration(milliseconds: 300);
  static const Curve winCurve = Curves.easeInCubic;

  // Background gradient shift
  static const Duration bgShiftDuration = Duration(milliseconds: 400);
  static const Curve bgShiftCurve = Curves.easeInOut;

  // v3 specific durations (unified with snapping animation)
  static const Duration breatheDuration = Duration(milliseconds: 2200);
  static const Duration exitArrowDuration = Duration(milliseconds: 1600);
  static const Duration blockedDuration = Duration(milliseconds: 180);
  static const Duration releaseDuration = Duration(milliseconds: 140);
  static const Curve releaseCurve = Curves.easeOutCubic;
  static const Duration confettiDuration = Duration(milliseconds: 900);
}
