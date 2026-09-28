import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../domain/board_meta.dart';

/// CustomPainter to render the board, cellular pockets, exit lights, and blocks.
class BoardPainter extends CustomPainter {
  final BoardMeta meta;
  final Uint8List positions;
  final int? dragPieceId;
  final double dragPixelOffset;
  final double cellSize;
  final bool isDark;

  // Animation values
  final double breathingValue; // 0..1 for target glow breathing
  final double exitArrowValue;  // 0..1 for exit arrow scrolling

  BoardPainter({
    required this.meta,
    required this.positions,
    required this.cellSize,
    this.dragPieceId,
    this.dragPixelOffset = 0.0,
    this.breathingValue = 0.0,
    this.exitArrowValue = 0.0,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardPixels = cellSize * 6;

    // 1. Draw Board Shadow & Physical deep blue outer frame
    final frameThickness = 8.0;
    final outerBoardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-frameThickness, -frameThickness, boardPixels + frameThickness * 2, boardPixels + frameThickness * 2),
      Radius.circular(boardPixels * 0.065),
    );

    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, boardPixels, boardPixels),
      Radius.circular(boardPixels * 0.055),
    );

    final shadowPaint = Paint()
      ..color = Palette.shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    // Draw frame shadow
    canvas.drawRRect(outerBoardRect.shift(const Offset(0, 8)), shadowPaint);

    // Draw deep blue/slate toy frame base
    final framePaint = Paint()..color = Palette.boardOuterFrame;
    canvas.drawRRect(outerBoardRect, framePaint);

    // Draw inner white/dark playing surface
    final bgPaint = Paint()..color = Palette.boardBg;
    canvas.drawRRect(boardRect, bgPaint);

    // 2. Draw Cellular Pockets with subtle borders
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

    // 2b. Draw ghostly exit lane overlay on Row 2 (exit row)
    // Subtle dark tint on every cell in row 2 to show the exit path
    final exitLanePaint = Paint()
      ..color = const Color(0x18000000) // ~9% black overlay, breathing subtle
      ..style = PaintingStyle.fill;
    final exitLaneBorderPaint = Paint()
      ..color = const Color(0x22E63946) // very faint red border pulse
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

    // 3. Draw Exit Indicators (Right edge of row 2)
    final exitTop = 2 * cellSize;
    final exitPaint = Paint()
      ..shader = uiGradient(
        Offset(boardPixels, exitTop + cellSize / 2),
        Offset(boardPixels + cellSize * 0.4, exitTop + cellSize / 2),
        [Palette.exitGlowEnd, Palette.exitGlowStart],
      );

    canvas.drawRect(
      Rect.fromLTWH(boardPixels, exitTop + cellPadding, cellSize * 0.4, cellSize - cellPadding * 2),
      exitPaint,
    );

    // Draw exit gate border outline
    final gateBorderPaint = Paint()
      ..color = const Color(0xFF1D9E75).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRect(
      Rect.fromLTWH(boardPixels, exitTop + cellPadding, cellSize * 0.4, cellSize - cellPadding * 2),
      gateBorderPaint,
    );

    // Draw exit moving `›` arrows
    final exitArrowTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 2; i++) {
      final progress = (exitArrowValue + i * 0.5) % 1.0;
      final arrowOpacity = (1.0 - progress) * 0.95; // brighter opacity
      final arrowX = boardPixels + progress * cellSize * 0.3;

      exitArrowTextPainter.text = TextSpan(
        text: '›',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20, // larger font size
          fontWeight: FontWeight.w900,
          color: Palette.exitArrowColor.withOpacity(arrowOpacity),
        ),
      );
      exitArrowTextPainter.layout();
      exitArrowTextPainter.paint(
        canvas,
        Offset(arrowX, exitTop + (cellSize - exitArrowTextPainter.height) / 2),
      );
    }

    // 4. Draw Blocks
    final blockPadding = cellSize * 0.045;
    final blockRadius = const Radius.circular(10);
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

      // Add drag offset
      if (isDragging) {
        if (isHoriz) {
          left += dragPixelOffset;
        } else {
          top += dragPixelOffset;
        }
      }

      // Proximity-based exit glow for target block
      if (isTarget) {
        final targetRightCol = left / cellSize + length;
        final distanceFactor = (targetRightCol - 2.0).clamp(0.0, 4.0) / 4.0; // 0..1 scale
        final glowOpacity = 0.30 + distanceFactor * 0.25;

        // Breathing animation: expands glow radius by 8% over 2200ms
        final breatheScale = 1.0 + (0.08 * breathingValue);
        final glowRadius = 18.0 * breatheScale;

        final targetGlowPaint = Paint()
          ..color = Palette.targetGlow.withOpacity(glowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

        final targetCenter = Offset(left + w / 2, top + h / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: targetCenter, width: w * 1.05, height: h * 1.05),
            blockRadius,
          ),
          targetGlowPaint,
        );

      }

      // Scale block when dragging
      if (isDragging) {
        const scale = 1.03;
        final cx = left + w / 2;
        final cy = top + h / 2;
        left = cx - (w * scale) / 2;
        top = cy - (h * scale) / 2;
        w *= scale;
        h *= scale;
      }

      final blockRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h),
        blockRadius,
      );

      // Create colors
      final Color bodyColor;
      final Color borderColor;
      final bool useGradientBody;

      if (isTarget) {
        bodyColor = Palette.targetStart;
        borderColor = Palette.targetBorder;
        useGradientBody = true;
      } else {
        final pair = Palette.normalBlockGradients[i % Palette.normalBlockGradients.length];
        bodyColor = pair.$1;
        borderColor = pair.$2;
        useGradientBody = false;
      }

      // Fill block body
      final bodyPaint = Paint();
      if (useGradientBody) {
        bodyPaint.shader = uiGradient(
          Offset(left, top),
          Offset(left, top + h),
          [Palette.targetStart, Palette.targetEnd],
        );
      } else {
        bodyPaint.color = bodyColor;
      }
      canvas.drawRRect(blockRect, bodyPaint);

      // Draw chunky outer border
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(blockRect, borderPaint);

      // Inner highlight line (top 2px white strip with 35% opacity)
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill;

      // Inner bottom shadow strip (bottom 4px dark strip with 15% opacity for 3D gloss effect)
      final darkShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.clipRRect(blockRect);
      // Draw top highlight
      canvas.drawRect(Rect.fromLTWH(left + 1, top + 1, w - 2, highlightHeight), highlightPaint);
      // Draw bottom shadow
      canvas.drawRect(Rect.fromLTWH(left + 1, top + h - 5.0, w - 2, 4.0), darkShadowPaint);
      canvas.restore();

      // Target block specific items: `›` character
      if (isTarget) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '›',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Position it on the right side of the block, centered vertically
        final offset = Offset(
          left + w - textPainter.width - 6,
          top + (h - textPainter.height) / 2,
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  Shader uiGradient(Offset from, Offset to, List<Color> colors) {
    final isHorizontal = (to.dx - from.dx).abs() > (to.dy - from.dy).abs();
    return LinearGradient(
      begin: isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: isHorizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: colors,
    ).createShader(Rect.fromPoints(from, to));
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return meta != oldDelegate.meta ||
        positions != oldDelegate.positions ||
        dragPieceId != oldDelegate.dragPieceId ||
        dragPixelOffset != oldDelegate.dragPixelOffset ||
        cellSize != oldDelegate.cellSize ||
        breathingValue != oldDelegate.breathingValue ||
        exitArrowValue != oldDelegate.exitArrowValue ||
        isDark != oldDelegate.isDark;
  }
}
