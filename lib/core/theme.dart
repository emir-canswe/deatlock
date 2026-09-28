import 'package:flutter/material.dart';
import 'palette.dart';

/// Deadlock theme: Nunito typography, soft shadows, light backgrounds.
class ThemeConfig {
  static const String fontFamily = 'Nunito';

  static TextStyle get headingStyle => TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    letterSpacing: -0.2,
    color: Palette.textHigh,
  );

  static TextStyle get titleStyle => TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: Palette.textHigh,
  );

  // Tabular figures enabled for numbers to prevent layout shifting
  static TextStyle get counterStyle => TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 12,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: Palette.textHigh,
  );

  static TextStyle get labelStyle => TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    color: Palette.textHigh,
  );

  static TextStyle get bodyStyle => TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: Palette.textLow,
  );

  static TextStyle get buttonTextStyle => TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    fontSize: 14,
    color: Palette.textHigh,
  );

  static ThemeData buildTheme({bool isDark = false}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: fontFamily,
      colorScheme: isDark
          ? ColorScheme.dark(
              surface: Palette.cardBg,
              primary: Palette.targetEnd,
              onPrimary: Colors.white,
              onSurface: Palette.textHigh,
            )
          : ColorScheme.light(
              surface: Colors.white,
              primary: Palette.targetEnd,
              onPrimary: Colors.white,
              onSurface: Palette.textHigh,
            ),
      useMaterial3: true,
    );
  }
}
