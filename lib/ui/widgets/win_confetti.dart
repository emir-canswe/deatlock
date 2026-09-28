import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen celebratory confetti burst and sparkle shower.
class WinConfettiOverlay extends StatefulWidget {
  const WinConfettiOverlay({super.key});

  @override
  State<WinConfettiOverlay> createState() => _WinConfettiOverlayState();
}

class _WinConfettiOverlayState extends State<WinConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiPiece> _pieces = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _controller.addListener(() {
      for (final p in _pieces) {
        p.update();
      }
      setState(() {});
    });

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pieces.isEmpty) {
      final size = MediaQuery.of(context).size;
      _initPieces(size);
    }
  }

  void _initPieces(Size size) {
    const colors = [
      Color(0xFFF59E0B), // gold
      Color(0xFF10B981), // emerald
      Color(0xFF38BDF8), // sky blue
      Color(0xFFEC4899), // pink
      Color(0xFFA855F7), // purple
      Color(0xFFF97316), // coral orange
      Color(0xFFFFFFFF), // pure white sparkle
    ];

    for (int i = 0; i < 70; i++) {
      final startX = size.width * (0.15 + _random.nextDouble() * 0.70);
      final startY = size.height * (0.18 + _random.nextDouble() * 0.25);
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 1.6;
      final speed = 4.0 + _random.nextDouble() * 9.0;

      _pieces.add(_ConfettiPiece(
        x: startX,
        y: startY,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 7.0 + _random.nextDouble() * 7.0,
        color: colors[i % colors.length],
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.25,
        isCircle: i % 4 == 0,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _WinConfettiPainter(_pieces, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPiece {
  double x, y;
  double vx, vy;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isCircle,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.26;
    vx *= 0.985;
    rotation += rotationSpeed;
  }
}

class _WinConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _WinConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = progress < 0.75 ? 1.0 : (1.0 - (progress - 0.75) / 0.25);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in pieces) {
      paint.color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WinConfettiPainter oldDelegate) => true;
}
