import 'dart:ui';
import 'package:flutter/material.dart';
import 'palette.dart';

/// Deadlock theme: Nunito typography, soft shadows, light backgrounds.
class ThemeConfig {
  static const String fontFamily = 'Nunito';

  static const TextStyle headingStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    letterSpacing: -0.2,
    color: Palette.textHigh,
  );

  static const TextStyle titleStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: Palette.textHigh,
  );

  // Tabular figures enabled for numbers to prevent layout shifting
  static const TextStyle counterStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 12,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Palette.textHigh,
  );

  static const TextStyle labelStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    color: Palette.textHigh,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: Palette.textLow,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    color: Palette.textHigh,
  );

  static ThemeData buildTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        primary: Palette.targetEnd,
        onPrimary: Colors.white,
        onSurface: Palette.textHigh,
      ),
      useMaterial3: true,
    );
  }
}
