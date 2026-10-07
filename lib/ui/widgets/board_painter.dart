import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../domain/board_meta.dart';

Shader _uiGradient(Offset from, Offset to, List<Color> colors) {
  final isHorizontal = (to.dx - from.dx).abs() > (to.dy - from.dy).abs();
  return LinearGradient(
    begin: isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
    end: isHorizontal ? Alignment.centerRight : Alignment.bottomCenter,
    colors: colors,
  ).createShader(Rect.fromPoints(from, to));
}

/// Static board chrome: drop shadow, frame, surface, cell pockets, the exit
/// lane tint and the exit gate.
///
/// None of this changes while playing, so it lives in its own cached raster
/// layer (see the RepaintBoundary in BoardView) and only repaints when the
/// board size or the theme changes. Keeping the blurred shadow, the 36 pockets
/// and the lane overlay out of the per-frame path is what keeps the game
/// smooth — previously all of it was redrawn 60 times a second.
class BoardBackgroundPainter extends CustomPainter {
  final double cellSize;
  final bool isDark;

  /// Padding baked into the layer so the frame + shadow can extend beyond the
  /// 6x6 board without being clipped by the repaint boundary.
  final double inset;

  const BoardBackgroundPainter({
    required this.cellSize,
    required this.isDark,
    this.inset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(inset, inset);

    final boardPixels = cellSize * 6;
    const frameThickness = 8.0;

    final outerBoardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-frameThickness, -frameThickness,
          boardPixels + frameThickness * 2, boardPixels + frameThickness * 2),
      Radius.circular(boardPixels * 0.065),
    );
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, boardPixels, boardPixels),
      Radius.circular(boardPixels * 0.055),
    );

    // Drop shadow + physical toy frame + playing surface
    canvas.drawRRect(
      outerBoardRect.shift(const Offset(0, 8)),
      Paint()
        ..color = Palette.shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawRRect(outerBoardRect, Paint()..color = Palette.boardOuterFrame);
    canvas.drawRRect(boardRect, Paint()..color = Palette.boardBg);

    // Cell pockets
    final cellPadding = cellSize * 0.035;
    final pocketPaint = Paint()..color = Palette.cellPocket;
    final pocketBorderPaint = Paint()
      ..color = Palette.cellPocketBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        final pocketRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            c * cellSize + cellPadding,
            r * cellSize + cellPadding,
            cellSize - cellPadding * 2,
            cellSize - cellPadding * 2,
          ),
          const Radius.circular(7),
        );
        canvas.drawRRect(pocketRect, pocketPaint);
        canvas.drawRRect(pocketRect, pocketBorderPaint);
      }
    }

    // Ghostly exit lane overlay on row 2
    final exitLanePaint = Paint()..color = const Color(0x18000000);
    final exitLaneBorderPaint = Paint()
      ..color = const Color(0x22E63946)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int c = 0; c < 6; c++) {
      final laneRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c * cellSize + cellPadding,
          2 * cellSize + cellPadding,
          cellSize - cellPadding * 2,
          cellSize - cellPadding * 2,
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(laneRect, exitLanePaint);
      canvas.drawRRect(laneRect, exitLaneBorderPaint);
    }

    // Exit gate on the right edge of row 2
    final exitTop = 2 * cellSize;
    final gateRect = Rect.fromLTWH(
      boardPixels,
      exitTop + cellPadding,
      cellSize * 0.4,
      cellSize - cellPadding * 2,
    );
    canvas.drawRect(
      gateRect,
      Paint()
        ..shader = _uiGradient(
          Offset(boardPixels, exitTop + cellSize / 2),
          Offset(boardPixels + cellSize * 0.4, exitTop + cellSize / 2),
          [Palette.exitGlowEnd, Palette.exitGlowStart],
        ),
    );
    canvas.drawRect(
      gateRect,
      Paint()
        ..color = const Color(0xFF1D9E75).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant BoardBackgroundPainter old) =>
      old.cellSize != cellSize || old.isDark != isDark || old.inset != inset;
}

/// Dynamic layer: the animated exit arrows and all the blocks.
class BoardPainter extends CustomPainter {
  final BoardMeta meta;
  final Uint8List positions;
  final int? dragPieceId;
  final double dragPixelOffset;
  final double cellSize;
  final bool isDark;

  /// Levels mode paints every obstacle in one colour so the target block is
  /// unmistakable. The other modes keep the varied palette.
  final bool uniformBlocks;

  final double breathingValue; // 0..1 target glow breathing
  final double exitArrowValue; // 0..1 exit arrow scrolling

  BoardPainter({
    required this.meta,
    required this.positions,
    required this.cellSize,
    this.dragPieceId,
    this.dragPixelOffset = 0.0,
    this.breathingValue = 0.0,
    this.exitArrowValue = 0.0,
    this.isDark = false,
    this.uniformBlocks = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardPixels = cellSize * 6;
    final exitTop = 2 * cellSize;

    // Animated exit arrows — cheap paths, no per-frame text layout.
    final arrowCy = exitTop + cellSize / 2;
    final arrowH = cellSize * 0.26;
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < 2; i++) {
      final progress = (exitArrowValue + i * 0.5) % 1.0;
      final opacity = (1.0 - progress) * 0.95;
      final ax = boardPixels + progress * cellSize * 0.3 + cellSize * 0.08;
      arrowPaint.color = Palette.exitArrowColor.withValues(alpha: opacity);
      final half = arrowH / 2;
      canvas.drawPath(
        Path()
          ..moveTo(ax - half * 0.5, arrowCy - half)
          ..lineTo(ax + half * 0.5, arrowCy)
          ..lineTo(ax - half * 0.5, arrowCy + half),
        arrowPaint,
      );
    }

    // Blocks
    final blockPadding = cellSize * 0.045;
    const blockRadius = Radius.circular(10);
    const highlightHeight = 2.0;

    for (int i = 0; i < meta.count; i++) {
      final isDragging = i == dragPieceId;
      final currentCoord = positions[i];
      final length = meta.len[i];
      final isHoriz = meta.horiz[i] == 1;
      final fixed = meta.fixed[i];
      final isTarget = i == meta.targetIndex;

      double left, top, w, h;

      if (isHoriz) {
        left = currentCoord * cellSize + blockPadding;
        top = fixed * cellSize + blockPadding;
        w = length * cellSize - blockPadding * 2;
        h = cellSize - blockPadding * 2;
      } else {
        left = fixed * cellSize + blockPadding;
        top = currentCoord * cellSize + blockPadding;
        w = cellSize - blockPadding * 2;
        h = length * cellSize - blockPadding * 2;
      }

      if (isDragging) {
        if (isHoriz) {
          left += dragPixelOffset;
        } else {
          top += dragPixelOffset;
        }
      }

      // Proximity-based breathing exit glow for the target block
      if (isTarget) {
        final targetRightCol = left / cellSize + length;
        final distanceFactor = (targetRightCol - 2.0).clamp(0.0, 4.0) / 4.0;
        final glowOpacity = 0.30 + distanceFactor * 0.25;
        final glowRadius = 18.0 * (1.0 + 0.08 * breathingValue);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(left + w / 2, top + h / 2),
              width: w * 1.05,
              height: h * 1.05,
            ),
            blockRadius,
          ),
          Paint()
            ..color = Palette.targetGlow.withValues(alpha: glowOpacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
        );
      }

      if (isDragging) {
        const scale = 1.03;
        final cx = left + w / 2;
        final cy = top + h / 2;
        left = cx - (w * scale) / 2;
        top = cy - (h * scale) / 2;
        w *= scale;
        h *= scale;
      }

      final blockRect =
          RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), blockRadius);

      final Color bodyColor;
      final Color borderColor;
      final bool useGradientBody;

      if (isTarget) {
        bodyColor = Palette.targetStart;
        borderColor = Palette.targetBorder;
        useGradientBody = true;
      } else {
        final pair = uniformBlocks
            ? Palette.uniformBlock
            : Palette.normalBlockGradients[
                i % Palette.normalBlockGradients.length];
        bodyColor = pair.$1;
        borderColor = pair.$2;
        useGradientBody = false;
      }

      final bodyPaint = Paint();
      if (useGradientBody) {
        bodyPaint.shader = _uiGradient(
          Offset(left, top),
          Offset(left, top + h),
          [Palette.targetStart, Palette.targetEnd],
        );
      } else {
        bodyPaint.color = bodyColor;
      }
      canvas.drawRRect(blockRect, bodyPaint);

      canvas.drawRRect(
        blockRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      canvas.save();
      canvas.clipRRect(blockRect);
      canvas.drawRect(
        Rect.fromLTWH(left + 1, top + 1, w - 2, highlightHeight),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
      canvas.drawRect(
        Rect.fromLTWH(left + 1, top + h - 5.0, w - 2, 4.0),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );
      canvas.restore();

      // Target block: unmistakable "slide me to the exit" styling
      if (isTarget && isHoriz) {
        canvas.save();
        canvas.clipRRect(blockRect);

        final sheenRect = Rect.fromLTWH(left, top, w, h * 0.55);
        canvas.drawRect(
          sheenRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.30),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(sheenRect),
        );

        // Bullseye emblem marks the piece to free
        final emblem = Offset(left + h * 0.52, top + h / 2);
        final rOuter = h * 0.23;
        canvas.drawCircle(
          emblem,
          rOuter,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * 0.07
            ..color = Colors.white.withValues(alpha: 0.92),
        );
        canvas.drawCircle(
          emblem,
          rOuter * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );

        // Flowing chevrons pointing at the exit
        final chevPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.085
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final zoneLeft = left + h * 1.02;
        final zoneRight = left + w - h * 0.22;
        final span = (zoneRight - zoneLeft).clamp(1.0, 100000.0);
        const count = 3;
        final spacing = span / count;
        final chevH = h * 0.32;
        final half = chevH / 2;
        final cy = top + h / 2;
        for (int k = 0; k < count; k++) {
          final cx = zoneLeft + ((k + exitArrowValue) % count) * spacing;
          final tpos = ((cx - zoneLeft) / span).clamp(0.0, 1.0);
          final fade = (1.0 - (tpos - 0.5).abs() * 2).clamp(0.0, 1.0);
          chevPaint.color = Colors.white.withValues(alpha: 0.18 + fade * 0.6);
          canvas.drawPath(
            Path()
              ..moveTo(cx - half * 0.55, cy - half)
              ..lineTo(cx + half * 0.55, cy)
              ..lineTo(cx - half * 0.55, cy + half),
            chevPaint,
          );
        }
        canvas.restore();

        canvas.drawRRect(
          blockRect.deflate(1.6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.5),
        );
      }
    }
  }

  /// The idle decorations (breathing target glow, scrolling exit arrows) are
  /// quantized so the board repaints ~10-15x per second instead of on every
  /// vsync. Gameplay stays perfectly smooth: drags and snap animations change
  /// [positions] / [dragPixelOffset], which are still compared exactly.
  static int _step(double v, int steps) => (v * steps).floor();

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return meta != oldDelegate.meta ||
        positions != oldDelegate.positions ||
        dragPieceId != oldDelegate.dragPieceId ||
        dragPixelOffset != oldDelegate.dragPixelOffset ||
        cellSize != oldDelegate.cellSize ||
        isDark != oldDelegate.isDark ||
        uniformBlocks != oldDelegate.uniformBlocks ||
        _step(breathingValue, 22) != _step(oldDelegate.breathingValue, 22) ||
        _step(exitArrowValue, 24) != _step(oldDelegate.exitArrowValue, 24);
  }
}
