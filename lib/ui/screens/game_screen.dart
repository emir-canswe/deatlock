import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/level_repository.dart';
import '../../data/daily_store.dart';
import '../../domain/game_mode.dart';
import '../../domain/hint.dart';
import '../../domain/move.dart';
import '../../domain/star_gate.dart';
import '../../state/game_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/sprint_controller.dart';
import '../widgets/board_view.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/hint_overlay.dart';
import '../widgets/sprint_bar.dart';
import '../widgets/top_bar.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/win_confetti.dart';
import '../widgets/win_sheet.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final ProgressController progressController;
  final int? levelNumber; // required for levels mode

  const GameScreen({
    super.key,
    required this.mode,
    required this.progressController,
    this.levelNumber,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final LevelRepository _levelRepo = LevelRepository();
  
  late int _currentLevelNumber;
  GameController? _gameController;
  SprintController? _sprintController;

  bool _loading = true;
  bool _showWin = false;
  bool _guideMinimized = false;

  // Board view key for animating auto-play hint moves
  final GlobalKey<BoardViewState> _boardViewKey = GlobalKey<BoardViewState>();

  // Hint state
  int? _hintPieceIndex;
  Move? _hintMove;

  // Sprint specific states
  bool _sprintFinished = false;

  Timer? _undoTimer;

  // Zen mode transition animations
  late final AnimationController _zenTransitionController;
  bool _zenTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentLevelNumber = widget.levelNumber ?? 1;

    _zenTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.mode == GameMode.sprint) {
      _sprintController = SprintController(widget.progressController.getProgressStore());
      _sprintController!.addListener(_onSprintTick);
      _sprintController!.start();
    }

    _loadLevel();
  }

  @override
  void dispose() {
    _sprintController?.removeListener(_onSprintTick);
    _sprintController?.dispose();
    _gameController?.dispose();
    _zenTransitionController.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _onSprintTick() {
    if (!mounted) return;
    if (_sprintController != null && !_sprintController!.isRunning && !_sprintFinished) {
      setState(() {
        _sprintFinished = true;
        _showWin = true;
      });
    }
    setState(() {});
  }

  Future<void> _loadLevel() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _showWin = false;
      _hintPieceIndex = null;
      _hintMove = null;
      _guideMinimized = false;
    });

    int seed;

    if (widget.mode == GameMode.levels) {
      seed = _currentLevelNumber;
    } else if (widget.mode == GameMode.daily) {
      final now = DateTime.now();
      seed = DailyStore.getSeedForDate(now);
    } else if (widget.mode == GameMode.sprint) {
      final currentScore = _sprintController?.score ?? 0;
      seed = 9999 + currentScore;
    } else {
      final rand = DateTime.now().millisecondsSinceEpoch;
      seed = rand;
    }

    final level = await _levelRepo.getLevel(seed);
    if (!mounted) return;

    if (_gameController != null) {
      _gameController!.removeListener(_onGameChange);
      _gameController!.dispose();
    }
    _gameController = GameController(
      meta: level.meta,
      initialPositions: level.initialPositions,
      optimalMoves: level.optimalMoves,
    );
    _gameController!.addListener(_onGameChange);

    setState(() {
      _loading = false;
    });
  }

  void _onGameChange() {
    if (!mounted) return;
    if (_hintPieceIndex != null) {
      _hintPieceIndex = null;
      _hintMove = null;
    }
    setState(() {});
  }

  void _onWin() {
    Haptics.winVibration();
    if (widget.mode == GameMode.sprint) {
      _sprintController?.recordWin();
      _loadLevel();
    } else if (widget.mode == GameMode.zen) {
      _triggerZenTransition();
    } else {
      if (widget.mode == GameMode.levels) {
        widget.progressController.completeLevel(
          _currentLevelNumber,
          _gameController!.moveCount,
          _gameController!.isPerfect,
          optimalMoves: _gameController!.optimalMoves,
          hintUsed: _gameController!.hintUsed,
        );
      } else if (widget.mode == GameMode.daily) {
        widget.progressController.recordDailyWin(_gameController!.moveCount);
      }
      
      setState(() {
        _showWin = true;
      });
    }
  }

  void _triggerZenTransition() {
    if (!mounted) return;
    setState(() => _zenTransitioning = true);
    _zenTransitionController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _loadLevel().then((_) {
        if (!mounted) return;
        _zenTransitionController.reverse(from: 1.0).then((_) {
          if (!mounted) return;
          setState(() => _zenTransitioning = false);
        });
      });
    });
  }

  void _onReset() {
    if (widget.mode == GameMode.daily) {
      // Prompt Daily fail reset warning
      showDialog(
        context: context,
        builder: (ctx) {
          final s = S.of(ctx);
          return AlertDialog(
            backgroundColor: Palette.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(s.warningTitle, style: ThemeConfig.titleStyle),
            content: Text(
              s.dailyResetWarning,
              style: ThemeConfig.bodyStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(s.cancelBtn, style: TextStyle(color: Palette.textLow)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await widget.progressController.recordDailyReset();
                  if (mounted) {
                    Navigator.of(context).pop(); // Back to menu
                  }
                },
                child: Text(s.resetBtn, style: const TextStyle(color: Palette.targetEnd)),
              ),
            ],
          );
        },
      );
    } else {
      _gameController?.reset();
    }
  }

  void _showHint() {
    if (_gameController == null || _gameController!.won) return;

    final s = S.of(context);
    final isHintZen = widget.mode == GameMode.zen;
    final hasHints = widget.progressController.hints > 0 || isHintZen;

    if (!hasHints) {
      Haptics.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.noHintsLeft,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Palette.textHigh,
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
      );
      return;
    }

    // If hint is already visible, don't deduct again — provide soft haptic
    if (_hintPieceIndex != null && _hintMove != null) {
      Haptics.lightImpact();
      return;
    }

    final bestMove = nextBestMove(_gameController!.meta, _gameController!.boardState);
    if (bestMove != null) {
      if (!isHintZen) {
        widget.progressController.useHint();
      }
      _gameController!.markHintUsed();
      Haptics.mediumImpact();
      Audio.playSlide();

      setState(() {
        _hintPieceIndex = bestMove.pieceIndex;
        _hintMove = bestMove;
      });
    }
  }

  void _applyHint() {
    if (_hintMove != null && _boardViewKey.currentState != null) {
      final move = _hintMove!;
      setState(() {
        _hintPieceIndex = null;
        _hintMove = null;
      });
      _boardViewKey.currentState!.animateMove(move);
    }
  }

  void _dismissHint() {
    Haptics.selectionClick();
    setState(() {
      _hintPieceIndex = null;
      _hintMove = null;
    });
  }

  void _startUndoRepeat() {
    if (_gameController == null || !_gameController!.canUndo) return;
    _gameController!.undo();
    _undoTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (_gameController != null && _gameController!.canUndo) {
        _gameController!.undo();
      } else {
        _undoTimer?.cancel();
      }
    });
  }

  void _stopUndoRepeat() {
    _undoTimer?.cancel();
    _undoTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final activeMode = widget.mode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.25, -1.0),
            end: const Alignment(0.25, 1.0),
            colors: [
              Palette.bgStart,
              Palette.bgMiddle(activeMode),
              Palette.bgEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Palette.targetEnd))
              : Stack(
                  children: [
                    Column(
                      children: [
                        // 1. Top HUD
                        TopBar(
                          mode: activeMode,
                          levelNumber: activeMode == GameMode.levels ? _currentLevelNumber : null,
                          moves: activeMode == GameMode.sprint
                              ? (_sprintController?.score ?? 0)
                              : (_gameController?.moveCount ?? 0),
                          optimalMoves: activeMode == GameMode.levels ? _gameController?.optimalMoves : null,
                          onBack: () => Navigator.of(context).pop(),
                        ),

                        // 2. Sprint Timer Bar
                        if (activeMode == GameMode.sprint && _sprintController != null)
                          SprintBar(timeLeft: _sprintController!.timeLeft),

                        // 2.5 Turn-by-Turn GPS Navigation Guide (Levels 1 to 5)
                        if (activeMode == GameMode.levels &&
                            _currentLevelNumber <= 5 &&
                            !_showWin &&
                            _gameController != null)
                          TutorialGpsCard(
                            levelNumber: _currentLevelNumber,
                            meta: _gameController!.meta,
                            boardState: _gameController!.boardState,
                            optimalMoves: _gameController!.optimalMoves,
                            isMinimized: _guideMinimized,
                            onToggleMinimize: () {
                              setState(() {
                                _guideMinimized = !_guideMinimized;
                              });
                            },
                          ),

                        const Spacer(),

                        // 3. Board Area
                        IgnorePointer(
                          ignoring: _zenTransitioning,
                          child: AnimatedBuilder(
                            animation: _zenTransitionController,
                            builder: (context, child) {
                              // Zen transition: slide down 240ms, pop up 260ms
                              final slideVal = _zenTransitionController.value;
                              return Transform.translate(
                                offset: Offset(0.0, slideVal * 400.0),
                                child: Opacity(
                                  opacity: (1.0 - slideVal).clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final boardPixels = constraints.maxWidth * 0.92;
                                final cellSize = boardPixels / 6;

                                return Center(
                                  child: SizedBox(
                                    width: boardPixels,
                                    height: boardPixels,
                                    child: Stack(
                                      children: [
                                        BoardView(
                                          key: _boardViewKey,
                                          controller: _gameController!,
                                          onWin: _onWin,
                                        ),
                                        if (activeMode == GameMode.levels &&
                                            _currentLevelNumber <= 5 &&
                                            !_guideMinimized &&
                                            !_showWin &&
                                            _gameController != null)
                                          BoardGuideOverlay(
                                            meta: _gameController!.meta,
                                            boardState: _gameController!.boardState,
                                            cellSize: cellSize,
                                          ),
                                        if (_hintPieceIndex != null &&
                                            _hintMove != null &&
                                            !_showWin &&
                                            _gameController != null)
                                          BoardHintOverlay(
                                            meta: _gameController!.meta,
                                            boardState: _gameController!.boardState,
                                            move: _hintMove!,
                                            cellSize: cellSize,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Active Hint Action Card
                        if (_hintPieceIndex != null &&
                            _hintMove != null &&
                            !_showWin &&
                            _gameController != null)
                          HintActionCard(
                            meta: _gameController!.meta,
                            move: _hintMove!,
                            onApply: _applyHint,
                            onDismiss: _dismissHint,
                          ),

                        // 4. Bottom action pills
                        if (!_showWin)
                          BottomBar(
                            mode: activeMode,
                            hintCount: widget.progressController.hints,
                            canUndo: _gameController?.canUndo ?? false,
                            onUndo: () => _gameController?.undo(),
                            onUndoLongPressStart: _startUndoRepeat,
                            onUndoLongPressEnd: _stopUndoRepeat,
                            onHint: _showHint,
                            onReset: _onReset,
                          ),
                      ],
                    ),

                    // Win Celebration Overlay & Sheet
                    if (_showWin) ...[
                      // Dimmed soft focus backdrop behind win sheet
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 350),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, opacity, _) {
                            return Container(
                              color: Colors.black.withValues(alpha: 0.45 * opacity),
                            );
                          },
                        ),
                      ),

                      // Full-screen celebratory Confetti & Sparkles
                      const Positioned.fill(
                        child: WinConfettiOverlay(),
                      ),

                      // Spring Bounce Win Sheet
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: TweenAnimationBuilder<Offset>(
                          duration: const Duration(milliseconds: 440),
                          curve: Curves.easeOutBack,
                          tween: Tween(begin: const Offset(0, 1.15), end: Offset.zero),
                          builder: (context, offset, child) {
                            return FractionalTranslation(
                              translation: offset,
                              child: child,
                            );
                          },
                          child: WinSheet(
                            mode: activeMode,
                            moves: _gameController?.moveCount ?? 0,
                            optimalMoves: _gameController?.optimalMoves ?? 0,
                            hintUsed: _gameController?.hintUsed ?? false,
                            isGateBlocked: activeMode == GameMode.levels &&
                                widget.progressController.isGateBlockedForNext(_currentLevelNumber),
                            requiredGateStars: StarGate.requiredStarsForLevel(_currentLevelNumber + 1),
                            totalStars: widget.progressController.totalStars,
                            onToLevels: () {
                              Navigator.of(context).pop();
                            },
                            dailyStreak: widget.progressController.dailyStore.streak,
                            dailyHistory: widget.progressController.dailyStore.getLast30DaysHistory(),
                            sprintScore: _sprintController?.score,
                            sprintBest: _sprintController?.personalBest,
                            onRetry: () {
                              if (activeMode == GameMode.sprint) {
                                _sprintController?.start();
                                setState(() {
                                  _sprintFinished = false;
                                });
                              }
                              _loadLevel();
                            },
                            onNext: () {
                              if (activeMode == GameMode.levels) {
                                if (widget.progressController.isGateBlockedForNext(_currentLevelNumber)) {
                                  Navigator.of(context).pop();
                                } else {
                                  _currentLevelNumber++;
                                  _loadLevel();
                                }
                              } else {
                                Navigator.of(context).pop(); // Back to main menu
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}


