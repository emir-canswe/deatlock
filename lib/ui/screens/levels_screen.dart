import 'package:flutter/material.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/star_gate.dart';
import '../../state/progress_controller.dart';
import '../widgets/chunky_button.dart';
import 'game_screen.dart';

class LevelsScreen extends StatefulWidget {
  final ProgressController progressController;

  const LevelsScreen({
    super.key,
    required this.progressController,
  });

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Auto-scroll to the current unlocked level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLevel = widget.progressController.unlockedLevel;
      if (currentLevel > 4 && _scrollController.hasClients) {
        final row = (currentLevel - 1) ~/ 4;
        final targetOffset = (row * 96.0).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showGateDialog(BuildContext context, int level, int requiredStars, int currentStars) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Palette.coinGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, color: Palette.coinGold, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.starGateTitle,
                style: ThemeConfig.titleStyle.copyWith(color: Palette.coinGold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.starGateRequired(requiredStars, currentStars),
              style: ThemeConfig.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: Palette.textHigh,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.starGateTip,
              style: ThemeConfig.bodyStyle.copyWith(
                fontSize: 13,
                color: Palette.textLow,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (currentStars / requiredStars).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Palette.cellPocket,
                valueColor: const AlwaysStoppedAnimation<Color>(Palette.coinGold),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$currentStars / $requiredStars ⭐',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Palette.coinGold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              s.okBtn,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                color: Palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Palette.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.bgStart, Palette.bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header Bar: Back Button, Title, and Star Counter Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    ChunkyButton(
                      color: Palette.buttonWhiteBg,
                      shadowColor: Palette.buttonWhiteShadow,
                      borderRadius: 22,
                      width: 44,
                      height: 44,
                      depth: 3,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Palette.textHigh,
                        size: 26,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.levelsTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Palette.textHigh,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    // Cumulative Star Counter Pill
                    ListenableBuilder(
                      listenable: widget.progressController,
                      builder: (context, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Palette.coinGold.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Palette.coinGold.withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Palette.coinGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.progressController.totalStars}',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                  color: Palette.coinGold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 2. Stage Progress Card (Aşama 1 • Bölüm 1-50, Progress Bar)
              ListenableBuilder(
                listenable: widget.progressController,
                builder: (context, _) {
                  final unlocked = widget.progressController.unlockedLevel;
                  final tier = ((unlocked - 1) ~/ StarGate.interval) + 1;
                  final tierStart = (tier - 1) * StarGate.interval + 1;
                  final tierEnd = tier * StarGate.interval;

                  int tierSolved = 0;
                  for (int l = tierStart; l <= tierEnd; l++) {
                    if (widget.progressController.getBestMoves(l) != null) {
                      tierSolved++;
                    }
                  }

                  final progressFactor = (tierSolved / StarGate.interval).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Palette.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.explore_rounded,
                                  color: Palette.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.tierProgressTitle(tier, tierStart, tierEnd),
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Palette.textHigh,
                                  ),
                                ),
                              ),
                              Text(
                                s.solvedCount(tierSolved, StarGate.interval),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Palette.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressFactor,
                              minHeight: 7,
                              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(Palette.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 6),

              // 3. Levels Grid with Smooth Animated Hero Cells
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.progressController,
                  builder: (context, _) {
                    final unlocked = widget.progressController.unlockedLevel;
                    final totalStars = widget.progressController.totalStars;
                    final totalVisible = unlocked > 500 ? unlocked : 500;

                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: totalVisible,
                          itemBuilder: (context, index) {
                            final level = index + 1;
                            final isUnlocked = level <= unlocked;
                            final isSolved = widget.progressController.getBestMoves(level) != null;
                            final stars = widget.progressController.getStars(level);
                            final isGate = StarGate.isGateLevel(level);
                            final reqStars = StarGate.requiredStarsForLevel(level);
                            final isGateBlocked = isGate && !isUnlocked && (level - 1 <= unlocked);
                            final isCurrent = level == unlocked && !isSolved;

                            return _LevelGridCell(
                              levelNumber: level,
                              isUnlocked: isUnlocked,
                              isSolved: isSolved,
                              stars: stars,
                              isGateBlocked: isGateBlocked,
                              isCurrent: isCurrent,
                              pulseValue: _pulseController.value,
                              requiredStars: reqStars,
                              onGateTap: () {
                                _showGateDialog(context, level, reqStars, totalStars);
                              },
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GameScreen(
                                      mode: widget.progressController.activeMode,
                                      progressController: widget.progressController,
                                      levelNumber: level,
                                    ),
                                  ),
                                );
                              },
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

/// A high-end 3D grid cell for level selections.
/// - Current active level: Hero pulsing neon emerald cell with "PLAY" badge.
/// - 3-Star solve: Sparkling golden amber 3D tile with bright stars.
/// - 1-2 Star solve: Emerald tile showing earned & missing stars clearly.
/// - Locked: Elegant frosted dark tile with clean lock glyph.
/// - Star Gate: Padlock milestone tile showing required star count.
class _LevelGridCell extends StatefulWidget {
  final int levelNumber;
  final bool isUnlocked;
  final bool isSolved;
  final int stars;
  final bool isGateBlocked;
  final bool isCurrent;
  final double pulseValue;
  final int requiredStars;
  final VoidCallback onGateTap;
  final VoidCallback onTap;

  const _LevelGridCell({
    required this.levelNumber,
    required this.isUnlocked,
    required this.isSolved,
    required this.stars,
    required this.isGateBlocked,
    required this.isCurrent,
    required this.pulseValue,
    required this.requiredStars,
    required this.onGateTap,
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
    final s = S.of(context);
    final isDark = Palette.isDark;

    // ── Case 1: Star Gate Milestone Locked Cell ─────────────────────────────
    if (widget.isGateBlocked) {
      return GestureDetector(
        onTap: widget.onGateTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.coinGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Palette.coinGold.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                color: Palette.coinGold,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                '${widget.requiredStars} ⭐',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Palette.coinGold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Case 2: Ordinary Locked Level Cell ──────────────────────────────────
    if (!widget.isUnlocked) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              size: 15,
            ),
            const SizedBox(height: 3),
            Text(
              '${widget.levelNumber}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    // ── Case 3: Unlocked / Solved / Hero Active Level ────────────────────────
    final Color cardColor;
    final Color borderColor;
    final Color shadowColor;
    final Color textColor;
    List<BoxShadow> extraGlow = [];

    if (widget.isCurrent) {
      // 🌟 HERO CURRENT LEVEL: Glowing neon emerald pulse tile
      cardColor = isDark ? const Color(0xFF10B981) : const Color(0xFF1D9E75);
      borderColor = isDark ? const Color(0xFF34D399) : const Color(0xFF2DD4BF);
      shadowColor = isDark ? const Color(0xFF047857) : const Color(0xFF0F5B46);
      textColor = Colors.white;

      final glowAlpha = 0.30 + 0.20 * widget.pulseValue;
      extraGlow = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: glowAlpha),
          blurRadius: 14,
          spreadRadius: 2 * widget.pulseValue,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (widget.stars == 3) {
      // 🏆 3-STAR MASTERED: Rich warm gold / amber tile
      cardColor = isDark ? const Color(0xFF241B0D) : const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFF59E0B);
      shadowColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D);
      textColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    } else if (widget.isSolved) {
      // ✅ 1-2 STARS SOLVED: Teal / Emerald solved tile
      cardColor = isDark ? const Color(0xFF0F241F) : const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF10B981);
      shadowColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFA7F3D0);
      textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    } else {
      // Unsolved but unlocked secondary tile
      cardColor = Palette.buttonWhiteBg;
      borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      shadowColor = Palette.buttonWhiteShadow;
      textColor = Palette.textHigh;
    }

    final double topOffset = _isPressed ? _depth : 0.0;
    final double shadowHeight = _isPressed ? 0.0 : _depth;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        Haptics.selectionClick();
        Audio.playClick();
      },
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2.0),
          boxShadow: [
            if (!_isPressed) ...[
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, shadowHeight),
                blurRadius: 0,
              ),
              ...extraGlow,
            ],
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.levelNumber}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: widget.isCurrent ? 18 : 17,
                color: textColor,
              ),
            ),
            const SizedBox(height: 3),

            // If Current Level: Show active "PLAY" pill
            if (widget.isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 11, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      s.currentLevelBadge,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            // If Solved: Show crisp 3 Stars row
            else if (widget.isSolved)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final hasStar = (i + 1) <= widget.stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.8),
                    child: Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: hasStar
                          ? const Color(0xFFFBBF24)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
