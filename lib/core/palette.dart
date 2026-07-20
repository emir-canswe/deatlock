import 'package:flutter/material.dart';
import '../domain/game_mode.dart';

/// Deadlock color palette matching Block Kule design system.
class Palette {
  // Screen Backgrounds (E6F1FB skyDayLight -> FFFFFF surface)
  static const Color bgStart = Color(0xFFE6F1FB);
  static const Color bgEnd = Color(0xFFFFFFFF);

  // Background tint adjustments per mode
  static Color bgMiddle(GameMode mode) {
    switch (mode) {
      case GameMode.levels:
        return const Color(0xFFF1F6FC);
      case GameMode.daily:
        return const Color(0xFFFFF7EF);
      case GameMode.sprint:
        return const Color(0xFFFFF2F4);
      case GameMode.zen:
        return const Color(0xFFF0FAF4);
    }
  }

  // Board colors
  static const Color boardBg = Color(0xFFFFFFFF);
  static const Color shadowColor = Color(0x1F0C447C); // rgba(12,68,124,0.12)
  static const Color cellPocket = Color(0xFFF1F6FC);

  // Normal block colors and their corresponding 3D borders (from block kule)
  static const List<(Color, Color)> normalBlockGradients = [
    (Color(0xFF5DCAA5), Color(0xFF0F6E56)), // teal / teal border
    (Color(0xFFAFA9EC), Color(0xFF534AB7)), // purple / purple border
    (Color(0xFFF0997B), Color(0xFF993C1D)), // coral / coral border
    (Color(0xFFF4C0D1), Color(0xFF993556)), // pink / pink border
    (Color(0xFFFAC775), Color(0xFF854F0B)), // amber / amber border
  ];

  // Target block colors (glowing gold/sunset orange-red)
  static const Color targetStart = Color(0xFFFF7A45);
  static const Color targetEnd = Color(0xFFE63946);
  static const Color targetGlow = Color(0x3AE63946);

  // Primary buttons (from block kule)
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF085041);

  // Coin / Gold / Hint display (from block kule)
  static const Color coinGold = Color(0xFFEF9F27);

  // Exit colors
  static const Color exitGlowStart = Color(0x001D9E75);
  static const Color exitGlowEnd = Color(0xB31D9E75);

  // Text colors (from block kule)
  static const Color textHigh = Color(0xFF0C447C); // textDark
  static const Color textLow = Color(0xFF185FA5);  // textMid
}
