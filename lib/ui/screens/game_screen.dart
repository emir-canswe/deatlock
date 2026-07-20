import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/level_repository.dart';
import '../../data/daily_store.dart';
import '../../domain/game_mode.dart';
import '../../domain/hint.dart';
import '../../domain/move.dart';
import '../../state/game_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/sprint_controller.dart';
import '../widgets/board_view.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/hint_overlay.dart';
import '../widgets/sprint_bar.dart';
import '../widgets/top_bar.dart';
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
    setState(() {});
  }

  void _onWin() {
    if (widget.mode == GameMode.sprint) {
      _sprintController?.recordWin();
      Haptics.mediumImpact();
      _loadLevel();
    } else if (widget.mode == GameMode.zen) {
      Haptics.mediumImpact();
      _triggerZenTransition();
    } else {
      if (widget.mode == GameMode.levels) {
        widget.progressController.completeLevel(
          _currentLevelNumber,
          _gameController!.moveCount,
          _gameController!.isPerfect,
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
            backgroundColor: Palette.boardBg,
            title: Text(s.warningTitle, style: ThemeConfig.titleStyle),
            content: Text(
              s.dailyResetWarning,
              style: ThemeConfig.bodyStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(s.cancelBtn, style: const TextStyle(color: Palette.textLow)),
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
    if (_gameController == null || (widget.progressController.hints <= 0 && widget.mode != GameMode.zen)) return;

    final bestMove = nextBestMove(_gameController!.meta, _gameController!.boardState);
    if (bestMove != null) {
      if (widget.mode != GameMode.zen) {
        widget.progressController.useHint();
      }
      _gameController!.markHintUsed();

      setState(() {
        _hintPieceIndex = bestMove.pieceIndex;
        _hintMove = bestMove;
      });
    }
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
                            child: BoardView(
                              controller: _gameController!,
                              onWin: _onWin,
                            ),
                          ),
                        ),

                        const Spacer(),

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

                    // Ghost Hint Overlay
                    if (_hintPieceIndex != null && _hintMove != null && _gameController != null)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final boardPixels = constraints.maxWidth * 0.92;
                            final cellSize = boardPixels / 6;
                            final padding = cellSize * 0.045;

                            final idx = _hintPieceIndex!;
                            final meta = _gameController!.meta;

                            return HintOverlay(
                              pieceIndex: idx,
                              length: meta.len[idx],
                              isHoriz: meta.horiz[idx] == 1,
                              fixed: meta.fixed[idx],
                              isTarget: idx == meta.targetIndex,
                              move: _hintMove!,
                              currentPos: _gameController!.boardState[idx],
                              cellSize: cellSize,
                              blockPadding: padding,
                              onDismiss: () {
                                setState(() {
                                  _hintPieceIndex = null;
                                  _hintMove = null;
                                });
                              },
                            );
                          },
                        ),
                      ),

                    // Win Sheet overlay
                    if (_showWin)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: TweenAnimationBuilder<Offset>(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween(begin: const Offset(0, 1), end: Offset.zero),
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
                                _currentLevelNumber++;
                                _loadLevel();
                              } else {
                                Navigator.of(context).pop(); // Back to main menu
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}


