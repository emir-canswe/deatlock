import '../../core/strings.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../domain/move.dart';

/// Professional hint overlay.
/// - Gently desaturates all other blocks (15% black overlay).
/// - Highlights the hinted block with a bright glow pulse.
/// - Shows destination cells with a soft glow fill.
/// - Draws an animated neon arrow from the block to the destination.
/// Tap anywhere to dismiss.
class HintOverlay extends StatefulWidget {
  final int pieceIndex;
  final int length;
  final bool isHoriz;
  final int fixed;
  final bool isTarget;
  final Move move;
  final int currentPos;
  final double cellSize;
  final double blockPadding;
  final VoidCallback onDismiss;

  const HintOverlay({
    super.key,
    required this.pieceIndex,
    required this.length,
    required this.isHoriz,
    required this.fixed,
    required this.isTarget,
    required this.move,
    required this.currentPos,
    required this.cellSize,
    required this.blockPadding,
    required this.onDismiss,
  });

  @override
  State<HintOverlay> createState() => _HintOverlayState();
}

class _HintOverlayState extends State<HintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _arrowAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Subtle soft dark veil — NOT heavy dimming
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            tween: Tween(begin: 0.0, end: 0.30),
            builder: (context, val, _) {
              return Container(color: Colors.black.withValues(alpha: val));
            },
          ),

          // Main animated hint painter
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _HintPainter(
                  length: widget.length,
                  isHoriz: widget.isHoriz,
                  fixed: widget.fixed,
                  isTarget: widget.isTarget,
                  move: widget.move,
                  currentPos: widget.currentPos,
                  cellSize: widget.cellSize,
                  blockPadding: widget.blockPadding,
                  pulseValue: _pulseAnim.value,
                  arrowValue: _arrowAnim.value,
                  pieceIndex: widget.pieceIndex,
                ),
                size: Size.infinite,
              );
            },
          ),

          // "Hamle yap" label near the arrow
          _HintLabel(
            isHoriz: widget.isHoriz,
            fixed: widget.fixed,
            currentPos: widget.currentPos,
            move: widget.move,
            length: widget.length,
            cellSize: widget.cellSize,
          ),
        ],
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _HintPainter extends CustomPainter {
  final int length;
  final bool isHoriz;
  final int fixed;
  final bool isTarget;
  final Move move;
  final int currentPos;
  final double cellSize;
  final double blockPadding;
  final double pulseValue; // 0..1
  final double arrowValue; // 0..1
  final int pieceIndex;

  _HintPainter({
    required this.length,
    required this.isHoriz,
    required this.fixed,
    required this.isTarget,
    required this.move,
    required this.currentPos,
    required this.cellSize,
    required this.blockPadding,
    required this.pulseValue,
    required this.arrowValue,
    required this.pieceIndex,
  });

  Color get _blockColor => isTarget
      ? Palette.targetEnd
      : Palette.normalBlockGradients[pieceIndex % Palette.normalBlockGradients.length].$1;

  @override
  void paint(Canvas canvas, Size size) {
    final cs = cellSize;
    final bp = blockPadding;

    // ── 1. Destination cells (where the block will slide to) ──────────────
    final destPos = currentPos + move.delta;
    final destColor = _blockColor.withValues(alpha: 0.18 + 0.10 * pulseValue);
    final destBorderColor = _blockColor.withValues(alpha: 0.55 + 0.20 * pulseValue);

    for (int i = 0; i < length; i++) {
      double cellLeft, cellTop;
      if (isHoriz) {
        cellLeft = (destPos + i) * cs + bp;
        cellTop = fixed * cs + bp;
      } else {
        cellLeft = fixed * cs + bp;
        cellTop = (destPos + i) * cs + bp;
      }
      final destRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cellLeft, cellTop, cs - bp * 2, cs - bp * 2),
        const Radius.circular(9),
      );
      // Fill
      canvas.drawRRect(destRect, Paint()..color = destColor);
      // Border
      canvas.drawRRect(destRect, Paint()
        ..color = destBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0);
    }

    // ── 2. Block highlight glow (hinted block itself) ─────────────────────
    double left, top, w, h;
    if (isHoriz) {
      left = currentPos * cs + bp;
      top = fixed * cs + bp;
      w = length * cs - bp * 2;
      h = cs - bp * 2;
    } else {
      left = fixed * cs + bp;
      top = currentPos * cs + bp;
      w = cs - bp * 2;
      h = length * cs - bp * 2;
    }

    final glowRadius = 14.0 + 8.0 * pulseValue;
    final blockCenter = Offset(left + w / 2, top + h / 2);

    // Outer glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: blockCenter, width: w + glowRadius, height: h + glowRadius),
        const Radius.circular(16),
      ),
      Paint()
        ..color = _blockColor.withValues(alpha: 0.20 * pulseValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
    );

    // Block face re-draw as bright highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(10)),
      Paint()
        ..color = _blockColor.withValues(alpha: 0.55 + 0.20 * pulseValue)
        ..style = PaintingStyle.fill,
    );
    // Bright border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(10)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65 + 0.25 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── 3. Animated neon arrow ────────────────────────────────────────────
    _drawAnimatedArrow(canvas, left, top, w, h, destPos, cs);
  }

  void _drawAnimatedArrow(
    Canvas canvas,
    double blockLeft,
    double blockTop,
    double blockW,
    double blockH,
    int destPos,
    double cs,
  ) {
    // Arrow travels from block edge → destination cell center
    Offset arrowStart, arrowEnd;
    if (isHoriz) {
      final blockCenterY = blockTop + blockH / 2;
      if (move.delta > 0) {
        // moving right
        arrowStart = Offset(blockLeft + blockW + 6, blockCenterY);
        arrowEnd = Offset((destPos + length) * cs - blockPadding - 6, blockCenterY);
      } else {
        // moving left
        arrowStart = Offset(blockLeft - 6, blockCenterY);
        arrowEnd = Offset(destPos * cs + blockPadding + 6, blockCenterY);
      }
    } else {
      final blockCenterX = blockLeft + blockW / 2;
      if (move.delta > 0) {
        // moving down
        arrowStart = Offset(blockCenterX, blockTop + blockH + 6);
        arrowEnd = Offset(blockCenterX, (destPos + length) * cs - blockPadding - 6);
      } else {
        // moving up
        arrowStart = Offset(blockCenterX, blockTop - 6);
        arrowEnd = Offset(blockCenterX, destPos * cs + blockPadding + 6);
      }
    }

    // Animate arrow: the head travels along the path based on arrowValue
    final animatedEnd = Offset.lerp(arrowStart, arrowEnd, arrowValue)!;

    final arrowColor = _blockColor;

    // Glowing trail line
    final trailPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.35)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(arrowStart, arrowEnd, trailPaint);

    // Solid line from start to animated head
    final solidPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(arrowStart, animatedEnd, solidPaint);

    // Arrowhead at animated position
    _drawArrowhead(canvas, arrowStart, animatedEnd, arrowColor);
  }

  void _drawArrowhead(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const size = 12.0;
    const spread = math.pi / 5.5;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - size * math.cos(angle - spread),
        to.dy - size * math.sin(angle - spread),
      )
      ..lineTo(
        to.dx - size * 0.55 * math.cos(angle),
        to.dy - size * 0.55 * math.sin(angle),
      )
      ..lineTo(
        to.dx - size * math.cos(angle + spread),
        to.dy - size * math.sin(angle + spread),
      )
      ..close();

    // Glow
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    // Fill
    canvas.drawPath(path, Paint()..color = color);
    // White edge
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── "Kaydır!" label widget ───────────────────────────────────────────────────

class _HintLabel extends StatelessWidget {
  final bool isHoriz;
  final int fixed;
  final int currentPos;
  final Move move;
  final int length;
  final double cellSize;

  const _HintLabel({
    required this.isHoriz,
    required this.fixed,
    required this.currentPos,
    required this.move,
    required this.length,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    // Position the label near the destination
    final cs = cellSize;
    final destPos = currentPos + move.delta;

    double labelLeft, labelTop;
    if (isHoriz) {
      labelLeft = (destPos + length / 2.0) * cs - 36;
      labelTop = fixed * cs - 34;
    } else {
      labelLeft = fixed * cs - 42;
      labelTop = (destPos + length / 2.0) * cs - 18;
    }

    final s = S.of(context);
    return Positioned(
      left: labelLeft.clamp(4, double.infinity),
      top: labelTop.clamp(4, double.infinity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 8,
            )
          ],
        ),
        child: Text(
          s.slide,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
