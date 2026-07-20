import '../../core/strings.dart';
import 'package:flutter/material.dart';
import '../../core/palette.dart';

/// Sprint mode countdown bar. Shows a linear progress indicator
/// representing remaining time, turning red when time is <= 15s.
class SprintBar extends StatelessWidget {
  final int timeLeft;
  final int totalTime;

  const SprintBar({
    super.key,
    required this.timeLeft,
    this.totalTime = 45,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pct = (timeLeft / totalTime).clamp(0.0, 1.0);
    final isCritical = timeLeft <= 10;
    final color = isCritical ? Palette.targetEnd : Palette.normalBlockGradients[0].$1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.timeLabel,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isCritical ? Palette.targetEnd : Palette.textLow,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${timeLeft}s',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isCritical ? Palette.targetEnd : Palette.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: Palette.cellPocket,
              child: Stack(
                children: [
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
