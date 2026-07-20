import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Confetti particle model.
class ConfettiParticle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.2; // gravity
    vx *= 0.98; // air resistance
    rotation += rotationSpeed;
  }
}

/// Painter to draw 24 falling confetti particles on win.
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Helper manager to initialize and update confetti particles.
class ConfettiManager {
  final List<ConfettiParticle> particles = [];
  final math.Random _random = math.Random();

  void spawn(double startX, double startY, List<Color> colors) {
    particles.clear();
    for (int i = 0; i < 24; i++) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * (math.pi / 3); // upward arc
      final speed = 4.0 + _random.nextDouble() * 6.0;
      final color = colors[i % colors.length];

      particles.add(ConfettiParticle(
        x: startX,
        y: startY,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: 8.0 + _random.nextDouble() * 6.0,
        color: color,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
      ));
    }
  }

  void update() {
    for (final p in particles) {
      p.update();
    }
  }
}
