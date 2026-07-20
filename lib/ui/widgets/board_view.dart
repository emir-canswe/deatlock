import 'package:flutter/material.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';
import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../domain/move.dart';
import '../../state/game_controller.dart';
import 'board_painter.dart';
import 'confetti_painter.dart';

class BoardView extends StatefulWidget {
  final GameController controller;
  final VoidCallback? onWin;

  const BoardView({
    super.key,
    required this.controller,
    this.onWin,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _exitArrowController;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // Snap-back animation properties
  late final AnimationController _snapController;
  int? _snapPieceId;
  double _snapFrom = 0.0;
  double _snapTo = 0.0;

  int? _dragPieceId;
  double _dragPixelOffset = 0.0;
  int _dragMinDelta = 0;
  int _dragMaxDelta = 0;
  double _dragStartPixel = 0.0;

  int? _shakePieceId;

  late final ConfettiManager _confettiManager;
  bool _showConfetti = false;
  late final AnimationController _confettiController;

  double _cellSize = 0.0;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: Motion.breatheDuration,
    )..repeat(reverse: true);

    _exitArrowController = AnimationController(
      vsync: this,
      duration: Motion.exitArrowDuration,
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: Motion.blockedDuration,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 4.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 4.0, end: -4.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -4.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _shakePieceId = null;
        });
        _shakeController.reset();
      }
    });

    _snapController = AnimationController(
      vsync: this,
      duration: Motion.releaseDuration,
    );

    _snapController.addListener(() {
      if (_snapPieceId != null) {
        setState(() {
          _dragPixelOffset = Tween<double>(begin: _snapFrom, end: _snapTo)
              .animate(CurvedAnimation(parent: _snapController, curve: Motion.releaseCurve))
              .value;
        });
      }
    });

    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_snapPieceId != null) {
          final delta = (_snapTo / _cellSize).round();
          if (delta != 0) {
            widget.controller.applyMove(Move(_snapPieceId!, delta));
            if (widget.controller.won) {
              _triggerWinSequence();
            } else {
              Audio.playSlide();
            }
          }
          setState(() {
            _dragPieceId = null;
            _snapPieceId = null;
            _dragPixelOffset = 0.0;
          });
        }
        _snapController.reset();
      }
    });

    _confettiManager = ConfettiManager();
    _confettiController = AnimationController(
      vsync: this,
      duration: Motion.confettiDuration,
    );

    _confettiController.addListener(() {
      _confettiManager.update();
    });

    _confettiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _exitArrowController.dispose();
    _shakeController.dispose();
    _snapController.dispose();
    _confettiController.dispose();
    super.dispose();
  }


  void _triggerWinSequence() {
    Haptics.mediumImpact();
    Audio.playWin();
    
    // Gather block colors to spawn matching confetti
    final colors = List.generate(widget.controller.meta.count, (i) {
      if (i == widget.controller.meta.targetIndex) return Palette.targetEnd;
      return Palette.normalBlockGradients[i % Palette.normalBlockGradients.length].$1;
    });

    // Spawn confetti at the exit coordinates
    final exitX = _cellSize * 6;
    final exitY = _cellSize * 2 + _cellSize / 2;
    _confettiManager.spawn(exitX, exitY, colors);

    setState(() {
      _showConfetti = true;
    });
    _confettiController.forward(from: 0.0);

    widget.onWin?.call();
  }

  int? _hitTest(Offset position) {
    final row = (position.dy / _cellSize).floor();
    final col = (position.dx / _cellSize).floor();
    if (row < 0 || row >= 6 || col < 0 || col >= 6) return null;
    final pid = widget.controller.pieceAt(row, col);
    if (pid < 0) return null;
    return pid;
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.controller.won) return;
    if (_snapController.isAnimating) return;

    final pieceIndex = _hitTest(details.localPosition);
    if (pieceIndex == null) return;

    final range = widget.controller.slideRange(pieceIndex);

    // If the piece cannot slide in either direction, do a shake animation
    if (range.$1 == 0 && range.$2 == 0) {
      Haptics.lightImpact();
      setState(() {
        _shakePieceId = pieceIndex;
      });
      _shakeController.forward(from: 0.0);
      return;
    }

    Haptics.selectionClick();

    final isHoriz = widget.controller.meta.horiz[pieceIndex] == 1;

    setState(() {
      _dragPieceId = pieceIndex;
      _dragPixelOffset = 0.0;
      _dragMinDelta = range.$1;
      _dragMaxDelta = range.$2;
      _dragStartPixel = isHoriz ? details.localPosition.dx : details.localPosition.dy;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragPieceId == null || widget.controller.won) return;

    final isHoriz = widget.controller.meta.horiz[_dragPieceId!] == 1;
    final currentPixel = isHoriz ? details.localPosition.dx : details.localPosition.dy;
    double rawOffset = currentPixel - _dragStartPixel;

    // Clamp to slide bounds
    final minPixel = _dragMinDelta * _cellSize;
    final maxPixel = _dragMaxDelta * _cellSize;
    rawOffset = rawOffset.clamp(minPixel, maxPixel);

    setState(() {
      _dragPixelOffset = rawOffset;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragPieceId == null) return;

    int targetDelta = 0;
    // Flick/swipe threshold: if dragged by more than 6 pixels, auto-slide all the way!
    if (_dragPixelOffset > 6.0) {
      targetDelta = _dragMaxDelta;
    } else if (_dragPixelOffset < -6.0) {
      targetDelta = _dragMinDelta;
    } else {
      targetDelta = 0;
    }

    final targetPixel = targetDelta * _cellSize;

    setState(() {
      _snapFrom = _dragPixelOffset;
      _snapTo = targetPixel;
      _snapPieceId = _dragPieceId;
    });

    _snapController.forward(from: 0.0);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.controller.won) return;
    if (_snapController.isAnimating) return;

    final pieceIndex = _hitTest(details.localPosition);
    if (pieceIndex == null) return;

    final range = widget.controller.slideRange(pieceIndex);
    // If the piece cannot slide in either direction, do a shake animation
    if (range.$1 == 0 && range.$2 == 0) {
      Haptics.lightImpact();
      setState(() {
        _shakePieceId = pieceIndex;
      });
      _shakeController.forward(from: 0.0);
      return;
    }

    final isHoriz = widget.controller.meta.horiz[pieceIndex] == 1;
    final variablePos = widget.controller.boardState[pieceIndex];
    final length = widget.controller.meta.len[pieceIndex];
    
    // Calculate center coordinate along its axis of movement
    final double center = (variablePos + length / 2.0) * _cellSize;
    final double touchPos = isHoriz ? details.localPosition.dx : details.localPosition.dy;
    
    int targetDelta = 0;
    if (touchPos > center) {
      // Tapped on the positive side (right/down)
      targetDelta = range.$2; // slide right/down all the way
      if (targetDelta == 0) {
        targetDelta = range.$1; // fallback if blocked
      }
    } else {
      // Tapped on the negative side (left/up)
      targetDelta = range.$1; // slide left/up all the way
      if (targetDelta == 0) {
        targetDelta = range.$2; // fallback if blocked
      }
    }

    if (targetDelta != 0) {
      Haptics.selectionClick();
      setState(() {
        _snapFrom = 0.0;
        _snapTo = targetDelta * _cellSize;
        _snapPieceId = pieceIndex;
      });
      _snapController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardPixels = constraints.maxWidth * 0.92;
        final currentCellSize = boardPixels / 6;
        _cellSize = currentCellSize;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: SizedBox(
                width: boardPixels,
                height: boardPixels,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTapUp: _onTapUp,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _breathingController,
                          _exitArrowController,
                          _shakeController,
                          _snapController,
                        ]),
                        builder: (context, _) {
                          return ListenableBuilder(
                            listenable: widget.controller,
                            builder: (context, _) {
                              double shakeOffset = 0.0;
                              if (_shakePieceId != null) {
                                shakeOffset = _shakeAnimation.value;
                              }

                              return CustomPaint(
                                painter: BoardPainter(
                                  meta: widget.controller.meta,
                                  positions: widget.controller.boardState,
                                  cellSize: currentCellSize,
                                  dragPieceId: _dragPieceId ?? _shakePieceId,
                                  dragPixelOffset: _dragPieceId != null ? _dragPixelOffset : shakeOffset,
                                  breathingValue: _breathingController.value,
                                  exitArrowValue: _exitArrowController.value,
                                ),
                                size: Size(boardPixels, boardPixels),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Confetti overlay inside board coordinate space (isolated repaint loop)
                    if (_showConfetti)
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confettiController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: ConfettiPainter(_confettiManager.particles),
                              size: Size(boardPixels, boardPixels),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
