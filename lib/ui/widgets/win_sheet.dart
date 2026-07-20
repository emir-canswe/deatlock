import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/game_mode.dart';

/// WinSheet shown at the bottom of the screen upon solving a level.
class WinSheet extends StatelessWidget {
  final GameMode mode;
  final int moves;
  final int optimalMoves;
  final bool hintUsed;
  final VoidCallback onRetry;
  final VoidCallback onNext;

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
    this.dailyStreak,
    this.dailyHistory,
    this.sprintScore,
    this.sprintBest,
  });

  bool get isPerfect => !hintUsed && moves <= optimalMoves;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (mode == GameMode.zen) {
      return const SizedBox.shrink(); // Zen has no win sheet, auto transitions
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Palette.boardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Palette.shadowColor,
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Palette.cellPocket,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            mode == GameMode.sprint
                ? s.timeUp
                : (isPerfect ? s.perfect : s.completed),
            style: ThemeConfig.headingStyle.copyWith(
              color: mode == GameMode.sprint
                  ? Palette.targetEnd
                  : (isPerfect ? const Color(0xFF19BFA0) : Palette.textHigh),
            ),
          ),
          if (hintUsed && mode != GameMode.sprint) ...[
            const SizedBox(height: 4),
            Text(
              s.hintUsed,
              style: ThemeConfig.bodyStyle.copyWith(color: Palette.targetEnd),
            ),
          ],
          const SizedBox(height: 24),

          // Render stats based on Mode
          if (mode == GameMode.levels) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatItem(label: s.yourMoves, value: '$moves'),
                const SizedBox(width: 48),
                _StatItem(label: s.optimal, value: '$optimalMoves'),
              ],
            ),
          ] else if (mode == GameMode.daily) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatItem(label: s.movesLabel, value: moves == -1 ? '—' : '$moves'),
                const SizedBox(width: 48),
                _StatItem(label: s.streakLabel, value: s.streakDays(dailyStreak ?? 0)),
              ],
            ),
            const SizedBox(height: 20),
            // Daily 30 days grid: çözülen günler dolu, kaçırılanlar boş
            if (dailyHistory != null) ...[
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
                    itemCount: dailyHistory!.length,
                    itemBuilder: (context, index) {
                      final item = dailyHistory![index];
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
          ] else if (mode == GameMode.sprint) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatItem(label: s.solved, value: '${sprintScore ?? 0}'),
                const SizedBox(width: 48),
                _StatItem(label: s.bestLabel, value: '${sprintBest ?? 0}'),
              ],
            ),
          ],

          const SizedBox(height: 32),
          // Buttons
          Row(
            children: [
              // In Sprint and Daily, Retry might behave differently, let's keep it standard
              Expanded(
                child: _SheetButton(
                  label: s.playAgain,
                  onPressed: onRetry,
                  primary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetButton(
                  label: mode == GameMode.daily ? s.okBtn : s.nextBtn,
                  onPressed: onNext,
                  primary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: ThemeConfig.headingStyle.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: ThemeConfig.bodyStyle.copyWith(fontSize: 10, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _SheetButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _SheetButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  @override
  State<_SheetButton> createState() => _SheetButtonState();
}

class _SheetButtonState extends State<_SheetButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.primary ? Palette.targetEnd : Palette.cellPocket,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: ThemeConfig.buttonTextStyle.copyWith(
              color: widget.primary ? Colors.white : Palette.textHigh,
            ),
          ),
        ),
      ),
    );
  }
}
