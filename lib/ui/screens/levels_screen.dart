import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/progress_controller.dart';
import '../widgets/chunky_button.dart';
import 'game_screen.dart';

class LevelsScreen extends StatelessWidget {
  final ProgressController progressController;

  const LevelsScreen({
    super.key,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.bgStart, Palette.bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Row: Chunky Back button on left, title in middle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    ChunkyButton(
                      color: Colors.white,
                      shadowColor: const Color(0xFFCBD5E1),
                      borderRadius: 24,
                      width: 46,
                      height: 46,
                      depth: 3,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Palette.textHigh,
                        size: 26,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.levelsTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Palette.textHigh,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 46), // balance
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Levels Grid
              Expanded(
                child: ListenableBuilder(
                  listenable: progressController,
                  builder: (context, _) {
                    final unlocked = progressController.unlockedLevel;
                    // Show 500 levels by default, or more if unlocked is higher
                    final totalVisible = unlocked > 500 ? unlocked : 500;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 items in a row for better touch targets and premium spacing
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: totalVisible,
                      itemBuilder: (context, index) {
                        final level = index + 1;
                        final isUnlocked = level <= unlocked;
                        final isSolved = progressController.getBestMoves(level) != null;
                        final isPerfect = progressController.isPerfect(level);

                        return _LevelGridCell(
                          levelNumber: level,
                          isUnlocked: isUnlocked,
                          isSolved: isSolved,
                          isPerfect: isPerfect,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GameScreen(
                                  mode: progressController.activeMode,
                                  progressController: progressController,
                                  levelNumber: level,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom stateful 3D grid cell for level selections
class _LevelGridCell extends StatefulWidget {
  final int levelNumber;
  final bool isUnlocked;
  final bool isSolved;
  final bool isPerfect;
  final VoidCallback onTap;

  const _LevelGridCell({
    required this.levelNumber,
    required this.isUnlocked,
    required this.isSolved,
    required this.isPerfect,
    required this.onTap,
  });

  @override
  State<_LevelGridCell> createState() => _LevelGridCellState();
}

class _LevelGridCellState extends State<_LevelGridCell> {
  bool _isPressed = false;
  static const double _depth = 4.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.isUnlocked) {
      // Locked level cell style: flat gray outline box
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${widget.levelNumber}',
              style: ThemeConfig.counterStyle.copyWith(
                color: const Color(0xFF94A3B8).withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.lock_rounded,
                color: Color(0xFF94A3B8),
                size: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Determine colors based on solve status (matching block kule themes)
    final Color cardColor;
    final Color shadowColor;
    final Color textColor;
    Widget? topBadge;

    if (widget.isPerfect) {
      // Perfect solve: 3D Golden box with star badge
      cardColor = const Color(0xFFFFF9E6);
      shadowColor = Palette.coinGold;
      textColor = const Color(0xFF854F0B);
      topBadge = const Text('⭐', style: TextStyle(fontSize: 10));
    } else if (widget.isSolved) {
      // Solved: 3D Soft emerald green box
      cardColor = const Color(0xFFE6FAF4);
      shadowColor = Palette.primary;
      textColor = Palette.primaryDark;
    } else {
      // Unsolved but unlocked: 3D White box
      cardColor = Colors.white;
      shadowColor = const Color(0xFFCBD5E1);
      textColor = Palette.textHigh;
    }

    final double topOffset = _isPressed ? _depth : 0.0;
    final double shadowHeight = _isPressed ? 0.0 : _depth;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: topOffset, bottom: _depth - topOffset),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: shadowColor, width: 1.8),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, shadowHeight),
                blurRadius: 0,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${widget.levelNumber}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: textColor,
              ),
            ),
            if (topBadge != null)
              Positioned(
                top: 4,
                right: 4,
                child: topBadge,
              ),
          ],
        ),
      ),
    );
  }
}
