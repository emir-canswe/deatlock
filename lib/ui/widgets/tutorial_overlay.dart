import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/board_meta.dart';
import '../../domain/board_state.dart';
import '../../domain/move.dart';
import '../../domain/solver.dart';

/// GPS-style turn-by-turn navigation card for the first 5 levels.
/// Positioned at the top of the screen (under TopBar).
class TutorialGpsCard extends StatelessWidget {
  final int levelNumber;
  final BoardMeta meta;
  final BoardState boardState;
  final int optimalMoves;
  final bool isMinimized;
  final VoidCallback onToggleMinimize;

  const TutorialGpsCard({
    super.key,
    required this.levelNumber,
    required this.meta,
    required this.boardState,
    required this.optimalMoves,
    required this.isMinimized,
    required this.onToggleMinimize,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Compute optimal solution from current state
    final solution = solve(meta, boardState);
    final remainingMoves = solution?.moves ?? 0;
    final Move? nextMove =
        (solution != null && solution.path.isNotEmpty) ? solution.path.first : null;

    final int totalOptimal = optimalMoves > 0 ? optimalMoves : 1;
    final int currentStep =
        (totalOptimal - remainingMoves + 1).clamp(1, totalOptimal);

    // Stage theme metadata for levels 1 through 5
    final String stageTitle;
    final String stageDesc;
    final IconData stageIcon;

    switch (levelNumber) {
      case 1:
        stageTitle = s.tutorialTitle1;
        stageDesc = s.tutorialDesc1;
        stageIcon = Icons.flag_rounded;
        break;
      case 2:
        stageTitle = s.tutorialTitle2;
        stageDesc = s.tutorialDesc2;
        stageIcon = Icons.alt_route_rounded;
        break;
      case 3:
        stageTitle = s.tutorialTitle3;
        stageDesc = s.tutorialDesc3;
        stageIcon = Icons.swap_horiz_rounded;
        break;
      case 4:
        stageTitle = s.tutorialTitle4;
        stageDesc = s.tutorialDesc4;
        stageIcon = Icons.link_rounded;
        break;
      case 5:
      default:
        stageTitle = s.tutorialTitle5;
        stageDesc = s.tutorialDesc5;
        stageIcon = Icons.stars_rounded;
        break;
    }

    // Human-readable action description for the next move
    String actionText = s.optimalRouteReady;
    if (nextMove != null) {
      final idx = nextMove.pieceIndex;
      final isTarget = idx == meta.targetIndex;
      final isHoriz = meta.horiz[idx] == 1;
      final delta = nextMove.delta;
      final deltaAbs = delta.abs();

      if (isTarget) {
        actionText = delta > 0 ? s.slideRedRight(delta) : s.slideRedLeft(deltaAbs);
      } else if (isHoriz) {
        actionText = delta > 0 ? s.slideHorizRight(delta) : s.slideHorizLeft(deltaAbs);
      } else {
        actionText = delta > 0 ? s.slideVertDown(delta) : s.slideVertUp(deltaAbs);
      }
    }

    if (isMinimized) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onToggleMinimize,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Palette.buttonWhiteBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Palette.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.navigation_rounded, color: Palette.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${s.yolTarifi} (${s.stepFormat(currentStep, totalOptimal)})',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Palette.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.visibility_rounded, color: Palette.primary, size: 14),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.buttonWhiteBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Palette.primary.withValues(alpha: 0.35),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Palette.primary.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Stage Badge + Step Progress + Minimize
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stageIcon, color: Palette.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stageTitle,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Palette.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Palette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.stepFormat(currentStep, totalOptimal),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Palette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onToggleMinimize,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Palette.cellPocket.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 16,
                      color: Palette.textLow,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),

            // Navigation instruction banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (nextMove?.pieceIndex == meta.targetIndex)
                    ? Palette.targetEnd.withValues(alpha: 0.10)
                    : Palette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (nextMove?.pieceIndex == meta.targetIndex)
                      ? Palette.targetEnd.withValues(alpha: 0.3)
                      : Palette.primary.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    color: (nextMove?.pieceIndex == meta.targetIndex)
                        ? Palette.targetEnd
                        : Palette.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionText,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Palette.textHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Teaching description tip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                stageDesc,
                style: ThemeConfig.bodyStyle.copyWith(
                  fontSize: 10.5,
                  color: Palette.textLow,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual overlay drawn directly on top of the 6x6 board.
/// Shows glowing highlight on the optimal piece, target destination box,
/// trajectory arrow, and gliding animated hand.
class BoardGuideOverlay extends StatefulWidget {
  final BoardMeta meta;
  final BoardState boardState;
  final double cellSize;

  const BoardGuideOverlay({
    super.key,
    required this.meta,
    required this.boardState,
    required this.cellSize,
  });

  @override
  State<BoardGuideOverlay> createState() => _BoardGuideOverlayState();
}

class _BoardGuideOverlayState extends State<BoardGuideOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _pulseController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _handOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.12, 0.88, curve: Curves.easeInOutCubic),
      ),
    );

    _handOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.95), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 0.95), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 0.0), weight: 20),
    ]).animate(_slideController);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final solution = solve(widget.meta, widget.boardState);
    final Move? nextMove =
        (solution != null && solution.path.isNotEmpty) ? solution.path.first : null;

    if (nextMove == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true, // Transparent to touches so user slides blocks underneath freely
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideController, _pulseController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _BoardGuidePainter(
                  meta: widget.meta,
                  boardState: widget.boardState,
                  move: nextMove,
                  cellSize: widget.cellSize,
                  pulseValue: _pulseController.value,
                  slideValue: _slideAnimation.value,
                ),
                size: Size(widget.cellSize * 6, widget.cellSize * 6),
              ),
              _buildAnimatedHand(nextMove),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHand(Move move) {
    final idx = move.pieceIndex;
    final isHoriz = widget.meta.horiz[idx] == 1;
    final length = widget.meta.len[idx];
    final fixed = widget.meta.fixed[idx];
    final currentPos = widget.boardState[idx];
    final cs = widget.cellSize;

    // Center coordinates
    final double srcCenterX = isHoriz
        ? (currentPos + length / 2.0) * cs
        : (fixed + 0.5) * cs;
    final double srcCenterY = isHoriz
        ? (fixed + 0.5) * cs
        : (currentPos + length / 2.0) * cs;

    final double destCenterX = isHoriz
        ? (currentPos + move.delta + length / 2.0) * cs
        : (fixed + 0.5) * cs;
    final double destCenterY = isHoriz
        ? (fixed + 0.5) * cs
        : (currentPos + move.delta + length / 2.0) * cs;

    final handX = srcCenterX + (destCenterX - srcCenterX) * _slideAnimation.value;
    final handY = srcCenterY + (destCenterY - srcCenterY) * _slideAnimation.value;

    return Positioned(
      left: handX - 14,
      top: handY - 8,
      child: Opacity(
        opacity: _handOpacityAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Palette.targetEnd.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.touch_app_rounded,
            size: 38,
            color: Palette.isDark ? Colors.white : Palette.targetEnd,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(1, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardGuidePainter extends CustomPainter {
  final BoardMeta meta;
  final BoardState boardState;
  final Move move;
  final double cellSize;
  final double pulseValue;
  final double slideValue;

  _BoardGuidePainter({
    required this.meta,
    required this.boardState,
    required this.move,
    required this.cellSize,
    required this.pulseValue,
    required this.slideValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final idx = move.pieceIndex;
    final isTarget = idx == meta.targetIndex;
    final isHoriz = meta.horiz[idx] == 1;
    final length = meta.len[idx];
    final fixed = meta.fixed[idx];
    final currentPos = boardState[idx];
    final destPos = currentPos + move.delta;
    final cs = cellSize;
    final bp = cs * 0.045;

    final Color blockColor = isTarget
        ? Palette.targetEnd
        : Palette.normalBlockGradients[idx % Palette.normalBlockGradients.length].$1;

    // ── 1. Destination target ghost box ──────────────────────────────────────
    double destL, destT, destW, destH;
    if (isHoriz) {
      destL = destPos * cs + bp;
      destT = fixed * cs + bp;
      destW = length * cs - bp * 2;
      destH = cs - bp * 2;
    } else {
      destL = fixed * cs + bp;
      destT = destPos * cs + bp;
      destW = cs - bp * 2;
      destH = length * cs - bp * 2;
    }

    final destRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(destL, destT, destW, destH),
      const Radius.circular(10),
    );

    // Soft destination fill
    canvas.drawRRect(
      destRect,
      Paint()
        ..color = blockColor.withValues(alpha: 0.16 + 0.10 * pulseValue)
        ..style = PaintingStyle.fill,
    );

    // Glowing destination stroke
    canvas.drawRRect(
      destRect,
      Paint()
        ..color = blockColor.withValues(alpha: 0.65 + 0.25 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // ── 2. Source piece glowing highlight ────────────────────────────────────
    double srcL, srcT, srcW, srcH;
    if (isHoriz) {
      srcL = currentPos * cs + bp;
      srcT = fixed * cs + bp;
      srcW = length * cs - bp * 2;
      srcH = cs - bp * 2;
    } else {
      srcL = fixed * cs + bp;
      srcT = currentPos * cs + bp;
      srcW = cs - bp * 2;
      srcH = length * cs - bp * 2;
    }

    final srcRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(srcL, srcT, srcW, srcH),
      const Radius.circular(10),
    );

    // Outer glow pulse around source block
    canvas.drawRRect(
      srcRect,
      Paint()
        ..color = blockColor.withValues(alpha: 0.35 * pulseValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.0 + 6.0 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // Bright inner border
    canvas.drawRRect(
      srcRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75 + 0.20 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // ── 3. Animated trajectory arrow ─────────────────────────────────────────
    final Offset start = Offset(srcL + srcW / 2, srcT + srcH / 2);
    final Offset end = Offset(destL + destW / 2, destT + destH / 2);

    // Trail line
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = blockColor.withValues(alpha: 0.4)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Moving arrow head
    final animatedHead = Offset.lerp(start, end, slideValue)!;
    _drawArrowhead(canvas, start, animatedHead, blockColor);
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    if ((to - from).distance < 2) return;
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const size = 11.0;
    const spread = math.pi / 5.0;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - size * math.cos(angle - spread),
        to.dy - size * math.sin(angle - spread),
      )
      ..lineTo(
        to.dx - size * 0.5 * math.cos(angle),
        to.dy - size * 0.5 * math.sin(angle),
      )
      ..lineTo(
        to.dx - size * math.cos(angle + spread),
        to.dy - size * math.sin(angle + spread),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardGuidePainter oldDelegate) => true;
}
