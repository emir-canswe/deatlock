import 'dart:async';
import 'dart:math' as math;
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

/// Per-mode accent color pair (gradient start, gradient end).
(Color, Color) _modeGradient(GameMode mode) {
  switch (mode) {
    case GameMode.levels:
      return (const Color(0xFFF7B733), const Color(0xFFE08C1E));
    case GameMode.daily:
      return (const Color(0xFF38BDF8), const Color(0xFF2563EB));
    case GameMode.sprint:
      return (const Color(0xFFFF7A45), const Color(0xFFE63946));
    case GameMode.zen:
      return (const Color(0xFF34D399), const Color(0xFF059669));
  }
}

/// Premium animated main menu / mode select screen for DEADLOCK.
class ModeSelectScreen extends StatefulWidget {
  final ProgressController progressController;

  const ModeSelectScreen({
    super.key,
    required this.progressController,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  // The ambient drift and the pulsing glow are decorative and very slow, so
  // they are stepped by a 10fps timer rather than a repeating vsync ticker.
  // A forever-repeating ticker makes Flutter rasterize a new frame 60 times a
  // second indefinitely, which pinned the raster thread and heated the device
  // until it thermal-throttled.
  Timer? _idleAnimTimer;
  double _pulsePhase = 0.0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    const tick = Duration(milliseconds: 100);
    const ambientStep = 100 / 16000;
    const pulseStep = 100 / 1700;
    _idleAnimTimer = Timer.periodic(tick, (_) {
      if (!mounted) return;
      _ambient.value = (_ambient.value + ambientStep) % 1.0;
      // Triangle wave so the glow eases up and back down without popping.
      _pulsePhase = (_pulsePhase + pulseStep) % 1.0;
      _pulse.value =
          _pulsePhase < 0.5 ? _pulsePhase * 2 : 2 - _pulsePhase * 2;
    });
  }

  @override
  void dispose() {
    _idleAnimTimer?.cancel();
    _ambient.dispose();
    _pulse.dispose();
    _entrance.dispose();
    super.dispose();
  }

  /// Staggered entrance: fade + slide-up based on [index].
  Widget _reveal(int index, Widget child) {
    final start = (index * 0.075).clamp(0.0, 0.55);
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 22),
          child: c,
        ),
      ),
      child: child,
    );
  }

  void _navigateToGame(GameMode mode, {int? levelNumber}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        mode: mode,
        progressController: widget.progressController,
        levelNumber: levelNumber,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.progressController;
    return ListenableBuilder(
      listenable: pc,
      builder: (context, _) {
        final activeMode = pc.activeMode;
        final unlockedLevel = pc.unlockedLevel;
        final streak = pc.dailyStore.streak;
        final hasPlayedDaily = pc.dailyStore.hasPlayedToday;
        final s = S.of(context);
        final dailyText = hasPlayedDaily
            ? (streak > 0 ? s.dailyStreak(streak) : s.dailySolved)
            : s.dailyReady;
        final sprintBest = pc.sprintBest;

        return Scaffold(
          body: Stack(
            children: [
              // ── Ambient animated background ──────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Palette.bgStart, Palette.bgEnd],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) => CustomPaint(
                      painter: _AmbientPainter(_ambient.value, Palette.isDark),
                    ),
                  ),
                ),
              ),

              // ── Foreground content ───────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _reveal(0, _TopBar(progressController: pc)),
                        const SizedBox(height: 18),

                        // ── Hero: emblem + wordmark + stat chips ───────
                        _reveal(
                          1,
                          _Hero(
                            unlockedLevel: unlockedLevel,
                            totalStars: pc.totalStars,
                            streak: streak,
                            pulse: _pulse,
                            s: s,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Big Play button ────────────────────────────
                        _reveal(
                          2,
                          _BigPlayButton(
                            s: s,
                            activeMode: activeMode,
                            unlockedLevel: unlockedLevel,
                            pulse: _pulse,
                            onPressed: () {
                              Haptics.mediumImpact();
                              if (activeMode == GameMode.levels) {
                                _navigateToGame(GameMode.levels,
                                    levelNumber: unlockedLevel);
                              } else {
                                _navigateToGame(activeMode);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 26),

                        _reveal(3, _SectionHeader(label: s.gameModes)),
                        const SizedBox(height: 14),

                        // ── Mode grid ──────────────────────────────────
                        _reveal(
                          4,
                          Row(
                            children: [
                              Expanded(
                                child: _ModeCard(
                                  title: s.modeLevels,
                                  subtitle: s.levelSubtitle(unlockedLevel),
                                  tag: '${s.isTr ? 'Bölüm' : 'Level'} $unlockedLevel',
                                  emoji: '🏆',
                                  mode: GameMode.levels,
                                  isSelected: activeMode == GameMode.levels,
                                  progress: (unlockedLevel / 500).clamp(0.0, 1.0),
                                  onTap: () {
                                    Haptics.selectionClick();
                                    pc.changeMode(GameMode.levels);
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => LevelsScreen(
                                          progressController: pc),
                                    ));
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ModeCard(
                                  title: s.modeDaily,
                                  subtitle: dailyText,
                                  tag: hasPlayedDaily
                                      ? (s.isTr ? '✓ Bitti' : '✓ Done')
                                      : (s.isTr ? 'Yeni' : 'New'),
                                  emoji: '📅',
                                  mode: GameMode.daily,
                                  isSelected: activeMode == GameMode.daily,
                                  onTap: () {
                                    Haptics.selectionClick();
                                    pc.changeMode(GameMode.daily);
                                    _navigateToGame(GameMode.daily);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _reveal(
                          5,
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
                                    pc.changeMode(GameMode.sprint);
                                    _navigateToGame(GameMode.sprint);
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
                                    pc.changeMode(GameMode.zen);
                                    _navigateToGame(GameMode.zen);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        _reveal(6, _SectionHeader(label: s.dailyMission)),
                        const SizedBox(height: 14),
                        _reveal(
                          7,
                          _DailyMissionCard(
                            hasPlayedDaily: hasPlayedDaily,
                            streak: streak,
                            s: s,
                            onTap: () {
                              Haptics.selectionClick();
                              pc.changeMode(GameMode.daily);
                              _navigateToGame(GameMode.daily);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Ambient background painter — drifting puzzle blocks + soft glows.
// ══════════════════════════════════════════════════════════════════════
class _AmbientPainter extends CustomPainter {
  final double t; // 0..1 looping
  final bool isDark;
  const _AmbientPainter(this.t, this.isDark);

  // (xFrac, yFrac, wFrac, hFrac, colorIndex, driftAmp, speed, phase)
  static const List<List<double>> _blocks = [
    [0.07, 0.20, 0.17, 0.065, 0, 18, 0.7, 0.0],
    [0.82, 0.12, 0.085, 0.13, 1, 22, 0.9, 1.4],
    [0.86, 0.45, 0.085, 0.085, 2, 16, 1.1, 2.7],
    [0.05, 0.58, 0.10, 0.10, 3, 20, 0.8, 0.6],
    [0.60, 0.74, 0.19, 0.07, 4, 24, 0.6, 3.5],
    [0.28, 0.88, 0.10, 0.10, 1, 18, 1.0, 2.0],
    [0.88, 0.82, 0.075, 0.075, 0, 15, 1.2, 4.2],
  ];

  static const List<Color> _dark = [
    Color(0xFF38BDF8),
    Color(0xFF818CF8),
    Color(0xFF34D399),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];
  static const List<Color> _light = [
    Color(0xFF7AC2F0),
    Color(0xFFA9A9EC),
    Color(0xFF6FD3AE),
    Color(0xFFF2C06B),
    Color(0xFFEFA8C6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cols = isDark ? _dark : _light;
    final blockAlpha = isDark ? 0.13 : 0.16;

    // Two large soft glow orbs for depth. These use a radial gradient instead
    // of MaskFilter.blur: it reads the same but costs a fraction of a real
    // gaussian blur, which previously ran on every single frame.
    final a = t * 2 * math.pi;

    void orb(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    orb(
      Offset(size.width * 0.18 + math.cos(a) * 20,
          size.height * 0.16 + math.sin(a) * 16),
      size.width * 0.34,
      const Color(0xFF1D9E75),
      isDark ? 0.18 : 0.13,
    );
    orb(
      Offset(size.width * 0.86 + math.cos(a + 2) * 22,
          size.height * 0.30 + math.sin(a + 2) * 18),
      size.width * 0.30,
      isDark ? const Color(0xFF6366F1) : const Color(0xFF38BDF8),
      isDark ? 0.16 : 0.12,
    );

    for (final b in _blocks) {
      final x = b[0] * size.width;
      final baseY = b[1] * size.height;
      final w = b[2] * size.width;
      final h = b[3] * size.width; // square-ish unit based on width
      final color = cols[b[4].toInt()];
      final amp = b[5];
      final speed = b[6];
      final phase = b[7];
      final dy = math.sin(a * speed + phase) * amp;
      final dx = math.cos(a * speed * 0.6 + phase) * (amp * 0.4);

      final rect = Rect.fromLTWH(x + dx, baseY + dy, w, h);
      final rrect =
          RRect.fromRectAndRadius(rect, Radius.circular(h.clamp(8, 20) * 0.45));
      canvas.drawRRect(
          rrect, Paint()..color = color.withValues(alpha: blockAlpha));
    }
  }

  // The drift is a slow 16s loop, so repainting the whole screen on every
  // vsync is pure waste. Quantizing the time value limits this background to
  // ~10 repaints per second instead of 60.
  static int _step(double v) => (v * 160).floor();

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      _step(old.t) != _step(t) || old.isDark != isDark;
}

// ══════════════════════════════════════════════════════════════════════
// Top Bar
// ══════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final ProgressController progressController;
  const _TopBar({required this.progressController});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
              borderColor: Palette.isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1),
              shadowColor: Palette.isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFCBD5E1),
            ),
          ],
        ),
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
              builder: (_) =>
                  SettingsScreen(progressController: progressController),
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

// ══════════════════════════════════════════════════════════════════════
// Hero: board emblem + animated wordmark + stat chips
// ══════════════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  final int unlockedLevel;
  final int totalStars;
  final int streak;
  final Animation<double> pulse;
  final S s;

  const _Hero({
    required this.unlockedLevel,
    required this.totalStars,
    required this.streak,
    required this.pulse,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Board emblem with pulsing glow halo
        AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            final g = Curves.easeInOut.transform(pulse.value);
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Palette.targetEnd.withValues(alpha: 0.18 + g * 0.18),
                    blurRadius: 24 + g * 16,
                    spreadRadius: 1 + g * 3,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: const _BoardEmblem(size: 96),
        ),
        const SizedBox(height: 16),

        // DEADLOCK wordmark with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: Palette.isDark
                ? [
                    const Color(0xFF7DD3FC),
                    const Color(0xFF818CF8),
                    const Color(0xFF34D399),
                  ]
                : [
                    const Color(0xFF0C447C),
                    const Color(0xFF2563EB),
                    const Color(0xFF1D9E75),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'REDBOUND',
            textAlign: TextAlign.center,
            style: ThemeConfig.headingStyle.copyWith(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3.0,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.isTr ? 'BULMACA & STRATEJİ' : 'PUZZLE & STRATEGY',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: Palette.textLow,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 16),

        // Stat chips row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              emoji: '🏆',
              value: '$unlockedLevel',
              label: s.isTr ? 'Bölüm' : 'Level',
              accent: Palette.coinGold,
            ),
            const SizedBox(width: 10),
            _StatChip(
              emoji: '⭐',
              value: '$totalStars',
              label: s.isTr ? 'Yıldız' : 'Stars',
              accent: Palette.coinGold,
            ),
            const SizedBox(width: 10),
            _StatChip(
              emoji: '🔥',
              value: '$streak',
              label: s.isTr ? 'Seri' : 'Streak',
              accent: const Color(0xFFF97316),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color accent;

  const _StatChip({
    required this.emoji,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Palette.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Palette.textHigh,
                  height: 1.0,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Palette.textLow,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small stylized sliding-block board used as the brand emblem.
class _BoardEmblem extends StatelessWidget {
  final double size;
  const _BoardEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BoardEmblemPainter(Palette.isDark)),
    );
  }
}

class _BoardEmblemPainter extends CustomPainter {
  final bool isDark;
  const _BoardEmblemPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.26),
    );

    // Board frame
    final frame = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF0C447C);
    canvas.drawRRect(r, frame);

    final innerPad = size.width * 0.12;
    final inner = Rect.fromLTWH(
      innerPad,
      innerPad,
      size.width - innerPad * 2,
      size.height - innerPad * 2,
    );
    final innerR =
        RRect.fromRectAndRadius(inner, Radius.circular(size.width * 0.16));
    final board = Paint()
      ..color = isDark ? const Color(0xFF0B111E) : const Color(0xFFF1F6FC);
    canvas.drawRRect(innerR, board);

    // 4x4 grid of pockets
    const n = 4;
    final cell = inner.width / n;
    final gap = cell * 0.14;
    final pocket = Paint()
      ..color = isDark ? const Color(0xFF131D31) : const Color(0xFFE2EBF5);
    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        final cr = Rect.fromLTWH(
          inner.left + col * cell + gap,
          inner.top + row * cell + gap,
          cell - gap * 2,
          cell - gap * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cr, Radius.circular(cell * 0.18)),
          pocket,
        );
      }
    }

    void drawBlock(int col, int row, int w, int h, Color a, Color b) {
      final rect = Rect.fromLTWH(
        inner.left + col * cell + gap,
        inner.top + row * cell + gap,
        cell * w - gap * 2,
        cell * h - gap * 2,
      );
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.22));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            colors: [a, b],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
      );
    }

    // Decorative blocks
    drawBlock(0, 0, 1, 2, const Color(0xFFAFA9EC), const Color(0xFF6D63D6)); // purple vertical
    drawBlock(3, 1, 1, 2, const Color(0xFF5DCAA5), const Color(0xFF189E78)); // teal vertical
    // Red target (row 2, 2-wide) heading to the exit on the right
    drawBlock(0, 2, 2, 1, Palette.targetStart, Palette.targetEnd);

    // Exit glow notch on the right edge of the target row
    final notchY = inner.top + 2 * cell + cell * 0.5;
    final notch = Paint()
      ..color = (isDark ? const Color(0xFF34D399) : const Color(0xFF19BFA0))
          .withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.width - innerPad * 0.5, notchY),
        size.width * 0.045, notch);
  }

  @override
  bool shouldRepaint(covariant _BoardEmblemPainter old) =>
      old.isDark != isDark;
}

// ══════════════════════════════════════════════════════════════════════
// Big Play Button with pulsing glow ring
// ══════════════════════════════════════════════════════════════════════
class _BigPlayButton extends StatefulWidget {
  final S s;
  final GameMode activeMode;
  final int unlockedLevel;
  final Animation<double> pulse;
  final VoidCallback onPressed;

  const _BigPlayButton({
    required this.s,
    required this.activeMode,
    required this.unlockedLevel,
    required this.pulse,
    required this.onPressed,
  });

  @override
  State<_BigPlayButton> createState() => _BigPlayButtonState();
}

class _BigPlayButtonState extends State<_BigPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final modeLabel = widget.activeMode == GameMode.levels
        ? s.levelTitle(widget.unlockedLevel).toUpperCase()
        : widget.activeMode == GameMode.daily
            ? s.dailyTitle
            : widget.activeMode == GameMode.sprint
                ? s.sprintTitle
                : s.zenTitle;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: widget.pulse,
        builder: (context, child) {
          final g = Curves.easeInOut.transform(widget.pulse.value);
          return AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22B885), Palette.primary, Color(0xFF0F7A5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Palette.primaryDark.withValues(alpha: 0.5),
                    blurRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Palette.primary.withValues(alpha: 0.25 + g * 0.22),
                    blurRadius: 20 + g * 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
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
                    const SizedBox(height: 6),
                    Text(
                      s.play,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Section Header
// ══════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 15,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Palette.primary, Color(0xFF0F7A5C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Palette.textHigh,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Palette.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Mode Card — gradient badge, press animation, optional progress bar
// ══════════════════════════════════════════════════════════════════════
class _ModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final String emoji;
  final GameMode mode;
  final bool isSelected;
  final double? progress;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.emoji,
    required this.mode,
    required this.isSelected,
    required this.onTap,
    this.progress,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (accentStart, accentEnd) = _modeGradient(widget.mode);
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Palette.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accentStart : Palette.cardBorder,
              width: selected ? 2.2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? accentStart.withValues(alpha: 0.25)
                    : Palette.cardShadow,
                blurRadius: selected ? 16 : 6,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient emoji badge
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentStart, accentEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentStart.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentStart.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.tag,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentEnd,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConfig.titleStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Palette.textHigh,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConfig.bodyStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? accentEnd : Palette.textLow,
                    ),
                  ),
                  if (widget.progress != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        minHeight: 5,
                        backgroundColor: Palette.isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFE2E8F0),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(accentStart),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Daily Mission Card
// ══════════════════════════════════════════════════════════════════════
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
            color: hasPlayedDaily ? const Color(0xFF10B981) : Palette.coinGold,
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
                        : (s.isTr
                            ? 'Günlük bulmaca seni bekliyor'
                            : 'Daily puzzle awaits'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color:
                          hasPlayedDaily ? const Color(0xFF10B981) : Palette.textLow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: hasPlayedDaily ? 1.0 : 0.0,
                      minHeight: 7,
                      backgroundColor: Palette.isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasPlayedDaily ? const Color(0xFF10B981) : Palette.coinGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
                      color:
                          hasPlayedDaily ? const Color(0xFF10B981) : Palette.coinGold,
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
