import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../../core/strings.dart';
import '../../domain/game_mode.dart';
import 'chunky_button.dart';

/// Top bar for game screen. Renders 3D-styled pill boxes and chunky buttons.
class TopBar extends StatelessWidget {
  final GameMode mode;
  final int? levelNumber;
  final int moves;
  final int? optimalMoves;
  final VoidCallback onBack;

  const TopBar({
    super.key,
    required this.mode,
    this.levelNumber,
    required this.moves,
    this.optimalMoves,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    String title = '';
    String statText = '';
    bool isOverOptimal = false;

    final s = S.of(context);
    switch (mode) {
      case GameMode.levels:
        title = s.levelTitle(levelNumber ?? 1);
        if (optimalMoves != null) {
          statText = '$moves / $optimalMoves';
          isOverOptimal = moves > optimalMoves!;
        } else {
          statText = '$moves';
        }
        break;
      case GameMode.daily:
        title = s.dailyTitle;
        statText = s.moveStat(moves);
        break;
      case GameMode.sprint:
        title = s.sprintTitle;
        statText = s.scoreStat(moves);
        break;
      case GameMode.zen:
        title = s.zenTitle;
        statText = ''; // No counters in Zen
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Back button chunky box
          ChunkyButton(
            color: Palette.buttonWhiteBg,
            shadowColor: Palette.buttonWhiteShadow,
            borderRadius: 22,
            width: 46,
            height: 46,
            depth: 3,
            onPressed: onBack,
            child: Icon(
              Icons.chevron_left_rounded,
              color: Palette.textHigh,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          // Title box (Modern HUD Pill)
          Expanded(
            child: _PillBox(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: ThemeConfig.titleStyle.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: Palette.textHigh,
                ),
              ),
            ),
          ),
          if (statText.isNotEmpty) ...[
            const SizedBox(width: 10),
            // Stat counter box (Modern HUD Pill)
            _PillBox(
              borderColor: isOverOptimal ? Palette.targetEnd.withValues(alpha: 0.7) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: isOverOptimal ? Palette.targetEnd : Palette.textLow,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statText,
                    style: ThemeConfig.counterStyle.copyWith(
                      color: isOverOptimal ? Palette.targetEnd : Palette.textHigh,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillBox extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _PillBox({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final border = borderColor ??
        (Palette.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));
    final shadow = Palette.isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Palette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: shadow,
            offset: const Offset(0, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
