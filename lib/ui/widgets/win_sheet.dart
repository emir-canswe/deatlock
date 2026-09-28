import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/game_mode.dart';
import '../../domain/star_gate.dart';
import 'chunky_button.dart';

/// Modern celebratory WinSheet shown at the bottom of the screen upon solving a level.
class WinSheet extends StatefulWidget {
  final GameMode mode;
  final int moves;
  final int optimalMoves;
  final bool hintUsed;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  // Star Gate milestone stats
  final bool isGateBlocked;
  final int requiredGateStars;
  final int totalStars;
  final VoidCallback? onToLevels;

  // Mode specific stats
  final int? dailyStreak;
  final List<Map<String, dynamic>>? dailyHistory; // List of last 30 days
  final int? sprintScore;
  final int? sprintBest;

  const WinSheet({
    super.key,
    required this.mode,
    required this.moves,
    required this.optimalMoves,
    required this.hintUsed,
    required this.onRetry,
    required this.onNext,
    this.isGateBlocked = false,
    this.requiredGateStars = 0,
    this.totalStars = 0,
    this.onToLevels,
    this.dailyStreak,
    this.dailyHistory,
    this.sprintScore,
    this.sprintBest,
  });

  bool get isPerfect => !hintUsed && moves <= optimalMoves;

  @override
  State<WinSheet> createState() => _WinSheetState();
}

class _WinSheetState extends State<WinSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _hapticPlayedStars = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    final stars = StarGate.calculateStars(
      moves: widget.moves,
      optimalMoves: widget.optimalMoves,
      hintUsed: widget.hintUsed,
    );

    _controller.addListener(() {
      if (widget.mode == GameMode.levels) {
        if (_controller.value >= 0.20 && _hapticPlayedStars < 1 && stars >= 1) {
          _hapticPlayedStars = 1;
          Haptics.lightImpact();
        }
        if (_controller.value >= 0.42 && _hapticPlayedStars < 2 && stars >= 2) {
          _hapticPlayedStars = 2;
          Haptics.lightImpact();
        }
        if (_controller.value >= 0.64 && _hapticPlayedStars < 3 && stars >= 3) {
          _hapticPlayedStars = 3;
          Haptics.mediumImpact();
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (widget.mode == GameMode.zen) {
      return const SizedBox.shrink(); // Zen has no win sheet, auto transitions
    }

    final stars = StarGate.calculateStars(
      moves: widget.moves,
      optimalMoves: widget.optimalMoves,
      hintUsed: widget.hintUsed,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Palette.boardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: Palette.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Palette.shadowColor,
            blurRadius: 32,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: Palette.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header badge & title with scale entrance
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
              ).value;
              return Transform.scale(
                scale: progress,
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildCelebrationHeader(s, stars),
          ),

          // 3-Star Animated Podium for Levels Mode
          if (widget.mode == GameMode.levels) ...[
            const SizedBox(height: 16),
            _buildAnimatedStarsPodium(stars),
            const SizedBox(height: 8),
            _buildStarHintText(s, stars),
          ],

          const SizedBox(height: 18),

          // Stats cards (Hamle, Optimal, Streak, etc.)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
              ).value;
              return Transform.translate(
                offset: Offset(0, 15 * (1.0 - progress)),
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildStatsContent(s),
          ),

          // Star Gate Blocked Milestone Banner
          if (widget.isGateBlocked) ...[
            const SizedBox(height: 18),
            _buildStarGateBanner(s),
          ],

          const SizedBox(height: 24),

          // Action Buttons (Tekrar / Sonraki Bölüm)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.55, 0.90, curve: Curves.easeOutCubic),
              ).value;
              return Transform.scale(
                scale: 0.9 + 0.1 * progress,
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildActionButtons(s),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationHeader(S s, int stars) {
    if (widget.mode == GameMode.sprint) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Palette.targetEnd.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Palette.targetEnd.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⏱️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  s.timeUp,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Palette.targetEnd,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.timeUp,
            style: ThemeConfig.headingStyle.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Palette.targetEnd,
            ),
          ),
        ],
      );
    }

    final is3Stars = stars == 3;
    final badgeText = is3Stars
        ? (s.isTr ? '✨ KUSURSUZ ÇÖZÜM ✨' : '✨ PERFECT CLEAR ✨')
        : (s.isTr ? '🎉 BÖLÜM GEÇİLDİ 🎉' : '🎉 LEVEL CLEARED 🎉');

    final badgeColor = is3Stars ? const Color(0xFF10B981) : Palette.primary;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          is3Stars
              ? (s.isTr ? 'HARİKA İŞ!' : 'OUTSTANDING!')
              : (s.isTr ? 'TEBRİKLER!' : 'WELL DONE!'),
          style: ThemeConfig.headingStyle.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Palette.textHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedStarsPodium(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Star 1 (Left)
        _buildAnimatedStar(
          earned: stars >= 1,
          size: 44,
          yOffset: 6,
          interval: const Interval(0.12, 0.40, curve: Curves.easeOutBack),
        ),
        const SizedBox(width: 14),
        // Star 2 (Middle Hero Star)
        _buildAnimatedStar(
          earned: stars >= 2,
          size: 58,
          yOffset: 0,
          interval: const Interval(0.32, 0.60, curve: Curves.easeOutBack),
        ),
        const SizedBox(width: 14),
        // Star 3 (Right)
        _buildAnimatedStar(
          earned: stars >= 3,
          size: 44,
          yOffset: 6,
          interval: const Interval(0.52, 0.80, curve: Curves.easeOutBack),
        ),
      ],
    );
  }

  Widget _buildAnimatedStar({
    required bool earned,
    required double size,
    required double yOffset,
    required Interval interval,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final curveVal = CurvedAnimation(
          parent: _controller,
          curve: interval,
        ).value;

        final scale = earned ? curveVal : 1.0;
        final opacity = earned ? curveVal.clamp(0.0, 1.0) : 0.4;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.35),
            child: Opacity(
              opacity: opacity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Golden radiant halo glow behind earned star
                  if (earned && curveVal > 0.35)
                    Container(
                      width: size * 0.85,
                      height: size * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Palette.coinGold.withValues(alpha: 0.5 * curveVal.clamp(0.0, 1.0)),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  // Star icon with smooth shadow
                  Icon(
                    earned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: size,
                    color: earned
                        ? Palette.coinGold
                        : (Palette.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    shadows: earned
                        ? [
                            BoxShadow(
                              color: Palette.coinGoldShadow,
                              offset: const Offset(0, 3),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarHintText(S s, int stars) {
    String text;
    Color textColor = Palette.textLow;

    if (stars == 3) {
      text = s.isTr ? '🎯 En kısa rota ile çözüldü!' : '🎯 Solved in optimal moves!';
      textColor = const Color(0xFF10B981);
    } else if (widget.hintUsed) {
      text = s.isTr ? '💡 İpucu kullanıldığı için en fazla 2 ⭐ verilir' : '💡 Using hints caps maximum stars at 2 ⭐';
      textColor = Palette.targetEnd;
    } else {
      text = s.isTr
          ? '⭐ 3 Yıldız için hedef: ${widget.optimalMoves} hamle'
          : '⭐ 3 Stars goal: ${widget.optimalMoves} moves';
      textColor = Palette.textLow;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: ThemeConfig.bodyStyle.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  Widget _buildStatsContent(S s) {
    if (widget.mode == GameMode.levels) {
      final isOptimal = widget.moves <= widget.optimalMoves;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatCard(
            label: s.yourMoves,
            value: '${widget.moves}',
            emoji: '👆',
            highlight: isOptimal,
            subBadge: isOptimal ? (s.isTr ? 'Optimal ✓' : 'Optimal ✓') : null,
          ),
          const SizedBox(width: 14),
          _StatCard(
            label: s.optimal,
            value: '${widget.optimalMoves}',
            emoji: '🎯',
            subBadge: s.isTr ? 'Hedef' : 'Target',
          ),
        ],
      );
    } else if (widget.mode == GameMode.daily) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatCard(
                label: s.movesLabel,
                value: widget.moves == -1 ? '—' : '${widget.moves}',
                emoji: '👆',
              ),
              const SizedBox(width: 14),
              _StatCard(
                label: s.streakLabel,
                value: s.streakDays(widget.dailyStreak ?? 0),
                emoji: '🔥',
              ),
            ],
          ),
          if (widget.dailyHistory != null) ...[
            const SizedBox(height: 16),
            Text(
              s.last30Days,
              style: ThemeConfig.bodyStyle.copyWith(fontSize: 10, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: Center(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.dailyHistory!.length,
                  itemBuilder: (context, index) {
                    final item = widget.dailyHistory![index];
                    final score = item['moves'] as int?;
                    final isPlayed = score != null;
                    final isSuccess = isPlayed && score > 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? const Color(0xFF19BFA0) // green fill
                            : isPlayed
                                ? Palette.targetEnd // red fail
                                : Palette.cellPocket, // empty unplayed
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      );
    } else if (widget.mode == GameMode.sprint) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatCard(
            label: s.solved,
            value: '${widget.sprintScore ?? 0}',
            emoji: '🧩',
          ),
          const SizedBox(width: 14),
          _StatCard(
            label: s.bestLabel,
            value: '${widget.sprintBest ?? 0}',
            emoji: '🏆',
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStarGateBanner(S s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.isDark ? const Color(0xFF2D1E12) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.coinGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Palette.coinGold.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: Palette.coinGold, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.starGateTitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Palette.coinGold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.starGateBlockedSheetDesc(widget.requiredGateStars, widget.totalStars),
                  style: ThemeConfig.bodyStyle.copyWith(
                    fontSize: 11.5,
                    color: Palette.textHigh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(S s) {
    return Row(
      children: [
        Expanded(
          child: ChunkyButton(
            color: Palette.buttonWhiteBg,
            shadowColor: Palette.buttonWhiteShadow,
            borderRadius: 18,
            depth: 4,
            height: 54,
            onPressed: widget.onRetry,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay_rounded, size: 20, color: Palette.textHigh),
                const SizedBox(width: 6),
                Text(
                  s.playAgain,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Palette.textHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChunkyButton(
            color: Palette.primary,
            shadowColor: Palette.primaryDark,
            borderRadius: 18,
            depth: 4,
            height: 54,
            onPressed: widget.isGateBlocked
                ? (widget.onToLevels ?? widget.onNext)
                : widget.onNext,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.isGateBlocked
                      ? s.toLevels
                      : (widget.mode == GameMode.daily ? s.okBtn : s.nextBtn),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  widget.isGateBlocked
                      ? Icons.grid_view_rounded
                      : Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? emoji;
  final bool highlight;
  final String? subBadge;

  const _StatCard({
    required this.label,
    required this.value,
    this.emoji,
    this.highlight = false,
    this.subBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : (Palette.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Palette.isDark ? Colors.black26 : const Color(0x080C447C),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: ThemeConfig.headingStyle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: highlight ? const Color(0xFF10B981) : Palette.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Palette.textLow,
            ),
          ),
          if (subBadge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (highlight ? const Color(0xFF10B981) : Palette.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subBadge!,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: highlight ? const Color(0xFF10B981) : Palette.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}