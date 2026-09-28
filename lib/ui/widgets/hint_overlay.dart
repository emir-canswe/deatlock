import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/board_meta.dart';
import '../../domain/board_state.dart';
import '../../domain/move.dart';
import 'chunky_button.dart';

/// Helper to generate localized move directions for hints.
String getHintMoveInstruction(BuildContext context, BoardMeta meta, Move move) {
  final s = S.of(context);
  final idx = move.pieceIndex;
  final isHoriz = meta.horiz[idx] == 1;
  final isTarget = idx == meta.targetIndex;
  final d = move.delta;

  if (isTarget) {
    if (d > 0) return s.slideRedRight(d);
    return s.slideRedLeft(d.abs());
  } else if (isHoriz) {
    if (d > 0) return s.slideHorizRight(d);
    return s.slideHorizLeft(d.abs());
  } else {
    if (d > 0) return s.slideVertDown(d);
    return s.slideVertUp(d.abs());
  }
}

/// Visual hint overlay rendered directly on top of the 6x6 board stack.
/// - Glowing golden/amber neon pulse on the piece to move.
/// - Ghost destination target box.
/// - Direction trajectory arrow with pulsing flow.
/// - Animated gliding hand gesture demonstrating the slide.
/// - Completely transparent to touch inputs (IgnorePointer) so the player can drag pieces freely!
class BoardHintOverlay extends StatefulWidget {
  final BoardMeta meta;
  final BoardState boardState;
  final Move move;
  final double cellSize;

  const BoardHintOverlay({
    super.key,
    required this.meta,
    required this.boardState,
    required this.move,
    required this.cellSize,
  });

  @override
  State<BoardHintOverlay> createState() => _BoardHintOverlayState();
}

class _BoardHintOverlayState extends State<BoardHintOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _handOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.10, 0.90, curve: Curves.easeInOutCubic),
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
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // Never block dragging on the board
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _slideController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _BoardHintPainter(
                  meta: widget.meta,
                  boardState: widget.boardState,
                  move: widget.move,
                  cellSize: widget.cellSize,
                  pulseValue: _pulseController.value,
                  slideValue: _slideAnimation.value,
                ),
                size: Size(widget.cellSize * 6, widget.cellSize * 6),
              ),
              _buildAnimatedHand(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHand() {
    final idx = widget.move.pieceIndex;
    final isHoriz = widget.meta.horiz[idx] == 1;
    final length = widget.meta.len[idx];
    final fixed = widget.meta.fixed[idx];
    final currentPos = widget.boardState[idx];
    final cs = widget.cellSize;

    final double srcCenterX = isHoriz
        ? (currentPos + length / 2.0) * cs
        : (fixed + 0.5) * cs;
    final double srcCenterY = isHoriz
        ? (fixed + 0.5) * cs
        : (currentPos + length / 2.0) * cs;

    final double destCenterX = isHoriz
        ? (currentPos + widget.move.delta + length / 2.0) * cs
        : (fixed + 0.5) * cs;
    final double destCenterY = isHoriz
        ? (fixed + 0.5) * cs
        : (currentPos + widget.move.delta + length / 2.0) * cs;

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
                color: Palette.accent.withValues(alpha: 0.40),
                blurRadius: 18,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.touch_app_rounded,
            size: 38,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(1, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardHintPainter extends CustomPainter {
  final BoardMeta meta;
  final BoardState boardState;
  final Move move;
  final double cellSize;
  final double pulseValue;
  final double slideValue;

  _BoardHintPainter({
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
    final isHoriz = meta.horiz[idx] == 1;
    final length = meta.len[idx];
    final fixed = meta.fixed[idx];
    final currentPos = boardState[idx];
    final isTarget = idx == meta.targetIndex;
    final cs = cellSize;
    final bp = cs * 0.045; // block padding

    final hintColor = isTarget ? Palette.targetEnd : Palette.accent;

    // ── 1. Destination Ghost Footprint ─────────────────────────────────────
    final destPos = currentPos + move.delta;
    double dLeft, dTop, dWidth, dHeight;
    if (isHoriz) {
      dLeft = destPos * cs + bp;
      dTop = fixed * cs + bp;
      dWidth = length * cs - bp * 2;
      dHeight = cs - bp * 2;
    } else {
      dLeft = fixed * cs + bp;
      dTop = destPos * cs + bp;
      dWidth = cs - bp * 2;
      dHeight = length * cs - bp * 2;
    }

    final destRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dLeft, dTop, dWidth, dHeight),
      const Radius.circular(10),
    );

    // Soft destination fill
    canvas.drawRRect(
      destRRect,
      Paint()
        ..color = hintColor.withValues(alpha: 0.16 + 0.08 * pulseValue)
        ..style = PaintingStyle.fill,
    );

    // Glowing destination stroke
    canvas.drawRRect(
      destRRect,
      Paint()
        ..color = hintColor.withValues(alpha: 0.65 + 0.25 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // ── 2. Highlight Source Block (Golden Glow & Border) ───────────────────
    double sLeft, sTop, sWidth, sHeight;
    if (isHoriz) {
      sLeft = currentPos * cs + bp;
      sTop = fixed * cs + bp;
      sWidth = length * cs - bp * 2;
      sHeight = cs - bp * 2;
    } else {
      sLeft = fixed * cs + bp;
      sTop = currentPos * cs + bp;
      sWidth = cs - bp * 2;
      sHeight = length * cs - bp * 2;
    }

    final srcRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(sLeft, sTop, sWidth, sHeight),
      const Radius.circular(10),
    );

    // Outer glow around block
    final glowRadius = 14.0 + 8.0 * pulseValue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(sLeft + sWidth / 2, sTop + sHeight / 2),
          width: sWidth + glowRadius,
          height: sHeight + glowRadius,
        ),
        const Radius.circular(14),
      ),
      Paint()
        ..color = hintColor.withValues(alpha: 0.28 * pulseValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
    );

    // Pulsing bright border
    canvas.drawRRect(
      srcRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 + 0.15 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // ── 3. Trajectory Arrow ───────────────────────────────────────────────
    final Offset arrowStart = Offset(sLeft + sWidth / 2, sTop + sHeight / 2);
    final Offset arrowEnd = Offset(dLeft + dWidth / 2, dTop + dHeight / 2);

    // Trajectory background rail
    final railPaint = Paint()
      ..color = hintColor.withValues(alpha: 0.35)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(arrowStart, arrowEnd, railPaint);

    // Animated sliding arrow tip
    final currentTip = Offset.lerp(arrowStart, arrowEnd, slideValue)!;
    final activePaint = Paint()
      ..color = hintColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(arrowStart, currentTip, activePaint);

    _drawArrowhead(canvas, arrowStart, currentTip, hintColor);
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const size = 11.0;
    const spread = math.pi / 5.2;

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
        ..color = Colors.white.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardHintPainter oldDelegate) => true;
}

/// Interactive HUD Card shown when a hint is active.
/// Provides:
/// - Lightbulb icon and clear instruction text.
/// - [HAMLEYİ YAP] 3D button for 1-tap auto glide move execution.
/// - [✕] Close button to dismiss hint.
class HintActionCard extends StatelessWidget {
  final BoardMeta meta;
  final Move move;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const HintActionCard({
    super.key,
    required this.meta,
    required this.move,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final instruction = getHintMoveInstruction(context, meta, move);
    final isTarget = move.pieceIndex == meta.targetIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isTarget
                ? Palette.targetEnd.withValues(alpha: 0.40)
                : Palette.accent.withValues(alpha: 0.40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bulb Icon Container
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: (isTarget ? Palette.targetEnd : Palette.accent)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                color: isTarget ? Palette.targetEnd : Palette.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),

            // Instruction Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.hintTitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isTarget ? Palette.targetEnd : Palette.accent,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    instruction,
                    style: ThemeConfig.bodyStyle.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Palette.textHigh,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Apply Move Button
            SizedBox(
              height: 38,
              child: ChunkyButton(
                color: Palette.primary,
                shadowColor: Palette.primaryDark,
                borderRadius: 12,
                depth: 3,
                onPressed: onApply,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      s.hintApply,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Dismiss Button
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Palette.cellPocket.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Palette.textLow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
