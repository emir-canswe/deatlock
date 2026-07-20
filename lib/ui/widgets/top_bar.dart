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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Back button chunky box
          ChunkyButton(
            color: Colors.white,
            shadowColor: const Color(0xFFCBD5E1),
            borderRadius: 24,
            width: 48,
            height: 48,
            depth: 3,
            onPressed: onBack,
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Palette.textHigh,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          // Title box (3D Pill)
          Expanded(
            child: _PillBox(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: ThemeConfig.titleStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Palette.textHigh,
                ),
              ),
            ),
          ),
          if (statText.isNotEmpty) ...[
            const SizedBox(width: 12),
            // Stat counter box (3D Pill)
            _PillBox(
              child: Text(
                statText,
                style: ThemeConfig.counterStyle.copyWith(
                  color: isOverOptimal ? Palette.targetEnd : Palette.textHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
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

  const _PillBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.textHigh, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Palette.textHigh,
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
