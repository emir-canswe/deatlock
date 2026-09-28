import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/game_mode.dart';
import '../../state/progress_controller.dart';
import '../widgets/chunky_button.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';

/// Premium main menu / mode select screen for DEADLOCK.
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Palette.bgStart, Palette.bgEnd],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top Bar ──────────────────────────────────────────
                      _TopBar(progressController: progressController),

                      const SizedBox(height: 24),

                      // ── Hero Brand Section ────────────────────────────────
                      _HeroBrandSection(
                        unlockedLevel: unlockedLevel,
                        totalStars: progressController.totalStars,
                        s: s,
                      ),

                      const SizedBox(height: 22),

                      // ── Big Play Button ───────────────────────────────────
                      _BigPlayButton(
                        s: s,
                        activeMode: activeMode,
                        unlockedLevel: unlockedLevel,
                        progressController: progressController,
                        onPressed: () {
                          Haptics.mediumImpact();
                          if (activeMode == GameMode.levels) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => GameScreen(
                                mode: GameMode.levels,
                                progressController: progressController,
                                levelNumber: unlockedLevel,
                              ),
                            ));
                          } else {
                            _navigateToGame(context, activeMode, progressController);
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── Mode Grid ─────────────────────────────────────────
                      _SectionHeader(label: s.gameModes),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              title: s.modeLevels,
                              subtitle: s.levelSubtitle(unlockedLevel),
                              tag: 'Bölüm $unlockedLevel',
                              emoji: '🏆',
                              mode: GameMode.levels,
                              isSelected: activeMode == GameMode.levels,
                              onTap: () {
                                Haptics.selectionClick();
                                progressController.changeMode(GameMode.levels);
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => LevelsScreen(progressController: progressController),
                                ));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModeCard(
                              title: s.modeDaily,
                              subtitle: dailyText,
                              tag: hasPlayedDaily ? (s.isTr ? '✓ Bitti' : '✓ Done') : (s.isTr ? 'Yeni' : 'New'),
                              emoji: '📅',
                              mode: GameMode.daily,
                              isSelected: activeMode == GameMode.daily,
                              onTap: () {
                                Haptics.selectionClick();
                                progressController.changeMode(GameMode.daily);
                                _navigateToGame(context, GameMode.daily, progressController);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              title: s.modeSprint,
                              subtitle: s.sprintBestSub(sprintBest),
                              tag: '60 Sn',
                              emoji: '⚡',
                              mode: GameMode.sprint,
                              isSelected: activeMode == GameMode.sprint,
                              onTap: () {
                                Haptics.selectionClick();
                                progressController.changeMode(GameMode.sprint);
                                _navigateToGame(context, GameMode.sprint, progressController);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModeCard(
                              title: s.modeZen,
                              subtitle: s.modeZenSub,
                              tag: s.isTr ? 'Sonsuz' : 'Endless',
                              emoji: '🍃',
                              mode: GameMode.zen,
                              isSelected: activeMode == GameMode.zen,
                              onTap: () {
                                Haptics.selectionClick();
                                progressController.changeMode(GameMode.zen);
                                _navigateToGame(context, GameMode.zen, progressController);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Daily Mission Card ────────────────────────────────
                      _SectionHeader(label: s.dailyMission),
                      const SizedBox(height: 12),
                      _DailyMissionCard(hasPlayedDaily: hasPlayedDaily, streak: streak, s: s,
                        onTap: () {
                          Haptics.selectionClick();
                          progressController.changeMode(GameMode.daily);
                          _navigateToGame(context, GameMode.daily, progressController);
                        },
                      ),

                      const SizedBox(height: 20),
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

  static void _navigateToGame(BuildContext context, GameMode mode, ProgressController pc) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(mode: mode, progressController: pc),
    ));
  }
}

// ──────────────────────────────────────────────────────────
// Top Bar: HUD pills on left, settings on right
// ──────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final ProgressController progressController;
  const _TopBar({required this.progressController});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // HUD pills
        Row(
          children: [
            _HudPill(
              icon: '⭐',
              value: '${progressController.totalStars}',
              borderColor: Palette.coinGold,
              shadowColor: Palette.coinGoldShadow,
            ),
            const SizedBox(width: 8),
            _HudPill(
              icon: '💡',
              value: '${progressController.hints}',
              borderColor: Palette.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              shadowColor: Palette.isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            ),
          ],
        ),

        // Settings Button
        ChunkyButton(
          color: Palette.buttonWhiteBg,
          shadowColor: Palette.buttonWhiteShadow,
          borderRadius: 22,
          width: 44,
          height: 44,
          depth: 3,
          onPressed: () {
            Haptics.selectionClick();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SettingsScreen(progressController: progressController),
            ));
          },
          child: Icon(Icons.settings_rounded, color: Palette.textHigh, size: 22),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  final String icon;
  final String value;
  final Color borderColor;
  final Color shadowColor;

  const _HudPill({
    required this.icon,
    required this.value,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            value,
            style: ThemeConfig.titleStyle.copyWith(
              color: Palette.textHigh,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Hero Brand Section
// ──────────────────────────────────────────────────────────
class _HeroBrandSection extends StatelessWidget {
  final int unlockedLevel;
  final int totalStars;
  final S s;

  const _HeroBrandSection({
    required this.unlockedLevel,
    required this.totalStars,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo badge container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Palette.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Palette.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // DEADLOCK wordmark
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: Palette.isDark
                      ? [const Color(0xFF38BDF8), const Color(0xFF818CF8)]
                      : [const Color(0xFF0C447C), const Color(0xFF1D9E75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'DEADLOCK',
                  style: ThemeConfig.headingStyle.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.isTr ? 'BULMACA & STRATEJİ OYUNU' : 'PUZZLE & STRATEGY GAME',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Palette.textLow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatBadge(
                    icon: '🏆',
                    label: s.isTr ? 'Bölüm' : 'Level',
                    value: '$unlockedLevel',
                    color: Palette.coinGold,
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Palette.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  _StatBadge(
                    icon: '⭐',
                    label: s.isTr ? 'Yıldız' : 'Stars',
                    value: '$totalStars',
                    color: Palette.coinGold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Palette.textHigh,
                height: 1.0,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Palette.textLow,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Big Play Button
// ──────────────────────────────────────────────────────────
class _BigPlayButton extends StatelessWidget {
  final S s;
  final GameMode activeMode;
  final int unlockedLevel;
  final ProgressController progressController;
  final VoidCallback onPressed;

  const _BigPlayButton({
    required this.s,
    required this.activeMode,
    required this.unlockedLevel,
    required this.progressController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final modeLabel = activeMode == GameMode.levels
        ? s.levelTitle(unlockedLevel).toUpperCase()
        : activeMode == GameMode.daily
            ? s.dailyTitle
            : activeMode == GameMode.sprint
                ? s.sprintTitle
                : s.zenTitle;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Palette.primary, Color(0xFF0F7A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Palette.primaryDark.withValues(alpha: 0.55),
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Palette.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              // Left: Mode info + Play label
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        modeLabel,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.play,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Glowing play icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Section Header with divider line
// ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Palette.textLow,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Mode Card
// ──────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final String emoji;
  final GameMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.emoji,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  Color get _modeAccent {
    switch (mode) {
      case GameMode.levels:
        return Palette.coinGold;
      case GameMode.daily:
        return const Color(0xFF0EA5E9);
      case GameMode.sprint:
        return Palette.targetEnd;
      case GameMode.zen:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 138,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Palette.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _modeAccent : Palette.cardBorder,
            width: isSelected ? 2.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _modeAccent.withValues(alpha: 0.22)
                  : Palette.cardShadow,
              blurRadius: isSelected ? 12 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: emoji box + tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji box with accent background
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _modeAccent.withValues(alpha: 0.14)
                        : (Palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: _modeAccent.withValues(alpha: 0.35), width: 1.2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),

                // Tag chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _modeAccent.withValues(alpha: 0.14)
                        : (Palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _modeAccent : Palette.textLow,
                    ),
                  ),
                ),
              ],
            ),

            // Bottom: title + subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConfig.titleStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Palette.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConfig.bodyStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _modeAccent : Palette.textLow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Daily Mission Card
// ──────────────────────────────────────────────────────────
class _DailyMissionCard extends StatelessWidget {
  final bool hasPlayedDaily;
  final int streak;
  final S s;
  final VoidCallback onTap;

  const _DailyMissionCard({
    required this.hasPlayedDaily,
    required this.streak,
    required this.s,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasPlayedDaily ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Palette.isDark
                ? [const Color(0xFF1E2638), const Color(0xFF1A2030)]
                : [const Color(0xFFFFFBF0), const Color(0xFFFFF7E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasPlayedDaily
                ? (Palette.isDark ? const Color(0xFF10B981) : const Color(0xFF10B981))
                : Palette.coinGold,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: hasPlayedDaily
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : Palette.coinGoldShadow.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasPlayedDaily
                    ? const Color(0xFF10B981).withValues(alpha: 0.14)
                    : Palette.coinGold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasPlayedDaily
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : Palette.coinGold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  hasPlayedDaily ? '✅' : '🎯',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Middle: text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.dailyMissionDesc,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Palette.textHigh,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPlayedDaily
                        ? (streak > 0
                            ? s.dailyStreak(streak)
                            : (s.isTr ? 'Bugün tamamlandı!' : 'Completed today!'))
                        : (s.isTr ? 'Günlük bulmaca seni bekliyor' : 'Daily puzzle awaits'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: hasPlayedDaily
                          ? const Color(0xFF10B981)
                          : Palette.textLow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: hasPlayedDaily ? 1.0 : 0.0,
                      minHeight: 7,
                      backgroundColor: Palette.isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasPlayedDaily ? const Color(0xFF10B981) : Palette.coinGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right: reward badge or check
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: hasPlayedDaily
                        ? const Color(0xFF10B981).withValues(alpha: 0.14)
                        : Palette.coinGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasPlayedDaily
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : Palette.coinGold.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    hasPlayedDaily ? '✓' : '+1 ⭐',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: hasPlayedDaily ? const Color(0xFF10B981) : Palette.coinGold,
                    ),
                  ),
                ),
                if (!hasPlayedDaily) ...[
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Palette.textLow,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
