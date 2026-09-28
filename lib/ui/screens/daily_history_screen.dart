import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/strings.dart';
import '../../domain/game_mode.dart';
import '../../state/progress_controller.dart';

/// Screen displaying the history of the daily levels solved over the last 30 days.
class DailyHistoryScreen extends StatelessWidget {
  final ProgressController progressController;

  const DailyHistoryScreen({
    super.key,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    final history = progressController.dailyStore.getLast30DaysHistory();
    final streak = progressController.dailyStore.streak;
    final s = S.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.25, -1.0),
            end: const Alignment(0.25, 1.0),
            colors: [Palette.bgStart, Palette.bgMiddle(GameMode.daily), Palette.bgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: Palette.textHigh, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      s.dailyHistoryTitle,
                      style: ThemeConfig.titleStyle.copyWith(letterSpacing: 1.0),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Streak box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Palette.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.cardShadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StreakItem(label: s.activeStreakLabel, value: s.streakDays(streak)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 30 Days Grid List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final date = item['date'] as DateTime;
                    final score = item['moves'] as int?;

                    final months = s.monthsList;
                    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';
                    String scoreText = s.notPlayed;
                    Color scoreColor = Palette.textLow;

                    if (score != null) {
                      if (score == -1) {
                        scoreText = s.failed;
                        scoreColor = Palette.targetEnd;
                      } else {
                        scoreText = s.movesText(score);
                        scoreColor = const Color(0xFF19BFA0);
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Palette.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.cardShadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: ThemeConfig.labelStyle.copyWith(fontSize: 14),
                          ),
                          Text(
                            scoreText,
                            style: ThemeConfig.bodyStyle.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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

class _StreakItem extends StatelessWidget {
  final String label;
  final String value;

  const _StreakItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: ThemeConfig.headingStyle.copyWith(fontSize: 28, color: Palette.targetStart),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: ThemeConfig.bodyStyle.copyWith(fontSize: 11, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
