import 'package:flutter/material.dart';
import '../domain/game_mode.dart';

/// Deadlock color palette matching Block Kule design system with Dark / Neon mode support.
class Palette {
  /// Global state toggle for dark theme. Updated by DeadlockApp.
  static bool isDark = false;

  // Screen Backgrounds
  static Color get bgStart => isDark ? const Color(0xFF0B111E) : const Color(0xFFE6F1FB);
  static Color get bgEnd => isDark ? const Color(0xFF131D31) : const Color(0xFFFFFFFF);

  // Background tint adjustments per mode
  static Color bgMiddle(GameMode mode) {
    if (isDark) {
      switch (mode) {
        case GameMode.levels:
          return const Color(0xFF151D2D);
        case GameMode.daily:
          return const Color(0xFF231A12);
        case GameMode.sprint:
          return const Color(0xFF251318);
        case GameMode.zen:
          return const Color(0xFF10201B);
      }
    }
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
  static Color get boardBg => isDark ? const Color(0xFF131D31) : const Color(0xFFFFFFFF);
  static Color get boardOuterFrame => isDark ? const Color(0xFF1E293B) : const Color(0xFF0C447C);
  static Color get shadowColor => isDark ? const Color(0x4D000000) : const Color(0x1F0C447C);
  static Color get cellPocket => isDark ? const Color(0xFF0B111E) : const Color(0xFFF1F6FC);
  static Color get cellPocketBorder => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // Normal block colors and their corresponding 3D borders (from block kule + neon dark)
  static List<(Color, Color)> get normalBlockGradients => isDark
      ? const [
          (Color(0xFF10B981), Color(0xFF065F46)), // Neon emerald / deep border
          (Color(0xFF8B5CF6), Color(0xFF5B21B6)), // Neon electric violet
          (Color(0xFFF97316), Color(0xFF9A3412)), // Neon coral / orange
          (Color(0xFFEC4899), Color(0xFF9D174D)), // Neon cyber pink
          (Color(0xFFFBBF24), Color(0xFF92400E)), // Neon amber gold
        ]
      : const [
          (Color(0xFF5DCAA5), Color(0xFF0F6E56)), // teal / teal border
          (Color(0xFFAFA9EC), Color(0xFF534AB7)), // purple / purple border
          (Color(0xFFF0997B), Color(0xFF993C1D)), // coral / coral border
          (Color(0xFFF4C0D1), Color(0xFF993556)), // pink / pink border
          (Color(0xFFFAC775), Color(0xFF854F0B)), // amber / amber border
        ];

  /// Single colour used for every obstacle block in Levels mode, so the only
  /// piece that stands out is the red target the player has to free.
  /// Violet contrasts strongly with the red target without clashing with the
  /// green exit gate.
  static (Color, Color) get uniformBlock => isDark
      ? const (Color(0xFF8B5CF6), Color(0xFF5B21B6))
      : const (Color(0xFFAFA9EC), Color(0xFF534AB7));

  // Target block colors (glowing gold/sunset orange-red)
  static const Color targetStart = Color(0xFFFF7A45);
  static const Color targetEnd = Color(0xFFE63946);
  static Color get targetGlow => isDark ? const Color(0x66EF4444) : const Color(0x3AE63946);
  static Color get targetBorder => isDark ? const Color(0xFFB91C1C) : const Color(0xFF991B1B);

  // Primary buttons (from block kule)
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF085041);

  // Coin / Gold / Hint display (from block kule)
  static const Color coinGold = Color(0xFFEF9F27);
  static const Color accent = Color(0xFFEF9F27);
  static Color get coinGoldShadow => isDark ? const Color(0xFF784504) : const Color(0x59EF9F27);

  // Exit colors
  static const Color exitGlowStart = Color(0x001D9E75);
  static Color get exitGlowEnd => isDark ? const Color(0xCC10B981) : const Color(0xB31D9E75);
  static Color get exitArrowColor => isDark ? const Color(0xFF34D399) : const Color(0xFF19BFA0);

  // Text colors (from block kule + dark mode contrast)
  static Color get textHigh => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0C447C);
  static Color get textLow => isDark ? const Color(0xFF94A3B8) : const Color(0xFF185FA5);
  static Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);

  // Cards & 3D button backgrounds
  static Color get cardBg => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get cardBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get cardShadow => isDark ? const Color(0x33000000) : const Color(0x06000000);

  // Chunky button neutral (white) colors
  static Color get buttonWhiteBg => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get buttonWhiteShadow => isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);

  // Segmented control tracks
  static Color get segmentTrack => isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  static Color get segmentTrackBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
}
