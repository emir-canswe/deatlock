import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/game_mode.dart';
import '../../state/progress_controller.dart';
import '../widgets/chunky_button.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';

/// The entry screen containing mode selection and options.
/// Redesigned to replicate the Block Kule style exactly.
class ModeSelectScreen extends StatelessWidget {
  final ProgressController progressController;

  const ModeSelectScreen({
    super.key,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progressController,
      builder: (context, _) {
        final activeMode = progressController.activeMode;
        final unlockedLevel = progressController.unlockedLevel;
        final streak = progressController.dailyStore.streak;
        final hasPlayedDaily = progressController.dailyStore.hasPlayedToday;
        final s = S.of(context);
        final dailyText = hasPlayedDaily
            ? (streak > 0 ? s.dailyStreak(streak) : s.dailySolved)
            : s.dailyReady;
        
        final sprintBest = progressController.sprintBest;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.bgStart,
                  Palette.bgEnd,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: CoinDisplay on left, Settings ChunkyButton on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 3D Hints Display (replicating block kule CoinDisplay)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.0),
                              border: Border.all(color: Palette.coinGold, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.coinGold.withOpacity(0.35),
                                  offset: const Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '⭐',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  '${progressController.hints}',
                                  style: ThemeConfig.titleStyle.copyWith(
                                    color: Palette.coinGold,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 3D Settings Button
                          ChunkyButton(
                            color: Colors.white,
                            shadowColor: const Color(0xFFCBD5E1),
                            borderRadius: 24,
                            width: 44,
                            height: 44,
                            depth: 3,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SettingsScreen(
                                    progressController: progressController,
                                  ),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.settings_rounded,
                              color: Palette.textHigh,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // App Title (BLOK KULE style)
                      Text(
                        'DEADLOCK',
                        textAlign: TextAlign.center,
                        style: ThemeConfig.headingStyle.copyWith(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Palette.textHigh,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Best score subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${s.bestLevel} $unlockedLevel ',
                            style: ThemeConfig.titleStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Palette.textLow,
                            ),
                          ),
                          const Text('🏆', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Large "OYNA" primary 3D button
                      ChunkyButton(
                        color: Palette.primary,
                        shadowColor: Palette.primaryDark,
                        borderRadius: 20,
                        depth: 5,
                        height: 62,
                        onPressed: () {
                          // Tap OYNA button starts levels directly at the last unlocked level, or launches the selected active mode
                          if (activeMode == GameMode.levels) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GameScreen(
                                  mode: GameMode.levels,
                                  progressController: progressController,
                                  levelNumber: progressController.unlockedLevel,
                                ),
                              ),
                            );
                          } else {
                            _navigateToGame(context, activeMode);
                          }
                        },
                        child: Text(
                          s.play,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Mode Section Header (ŞEHİR TEMALARI style)
                      Text(
                        s.gameModes,
                        style: ThemeConfig.labelStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Palette.textHigh,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row 1: Levels & Daily cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeCard(
                              context: context,
                              title: s.modeLevels,
                              subtitle: s.levelSubtitle(unlockedLevel),
                              emoji: '🏆',
                              mode: GameMode.levels,
                              onTap: () {
                                progressController.changeMode(GameMode.levels);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LevelsScreen(
                                      progressController: progressController,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModeCard(
                              context: context,
                              title: s.modeDaily,
                              subtitle: dailyText,
                              emoji: '📅',
                              mode: GameMode.daily,
                              onTap: () {
                                progressController.changeMode(GameMode.daily);
                                _navigateToGame(context, GameMode.daily);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 2: Sprint & Zen cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeCard(
                              context: context,
                              title: s.modeSprint,
                              subtitle: s.sprintBestSub(sprintBest),
                              emoji: '⚡',
                              mode: GameMode.sprint,
                              onTap: () {
                                progressController.changeMode(GameMode.sprint);
                                _navigateToGame(context, GameMode.sprint);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModeCard(
                              context: context,
                              title: s.modeZen,
                              subtitle: s.modeZenSub,
                              emoji: '🍃',
                              mode: GameMode.zen,
                              onTap: () {
                                progressController.changeMode(GameMode.zen);
                                _navigateToGame(context, GameMode.zen);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Daily Mission Header (GÜNLÜK GÖREVLER style)
                      Text(
                        s.dailyMission,
                        style: ThemeConfig.labelStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Palette.textHigh,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mission Card (Yellow cream body with border)
                      Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF0),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF3E6C9), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  s.dailyMissionDesc,
                                  style: ThemeConfig.titleStyle.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Palette.textHigh,
                                  ),
                                ),
                                // Reward badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECE5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Palette.coinGold, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '+1 ',
                                        style: ThemeConfig.counterStyle.copyWith(
                                          color: Palette.coinGold,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text('⭐', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: hasPlayedDaily ? 1.0 : 0.0,
                                minHeight: 10,
                                backgroundColor: const Color(0xFFEFEFEF),
                                valueColor: const AlwaysStoppedAnimation<Color>(Palette.primary),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasPlayedDaily ? '1 / 1' : '0 / 1',
                              textAlign: TextAlign.right,
                              style: ThemeConfig.bodyStyle.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Palette.textLow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String emoji,
    required GameMode mode,
    required VoidCallback onTap,
  }) {
    final isSelected = progressController.activeMode == mode;
    final s = S.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Palette.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: ThemeConfig.titleStyle.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Palette.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSelected ? s.selected : subtitle,
              style: ThemeConfig.bodyStyle.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Palette.primary : Palette.textLow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          progressController: progressController,
        ),
      ),
    );
  }
}
