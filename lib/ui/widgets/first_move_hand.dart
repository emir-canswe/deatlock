import 'package:flutter/material.dart';

/// Silent tutorial hand indicator. Slides target block horizontally after a 4-second delay.
class FirstMoveHand extends StatefulWidget {
  final double cellSize;

  const FirstMoveHand({
    super.key,
    required this.cellSize,
  });

  @override
  State<FirstMoveHand> createState() => _FirstMoveHandState();
}

class _FirstMoveHandState extends State<FirstMoveHand> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.7), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.7), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double xOffset = _slideAnimation.value * widget.cellSize * 1.5;
        return Positioned(
          left: widget.cellSize * 1.0 + xOffset, // Starting near center of target block
          top: widget.cellSize * 2.2, // Row 2 vertical center
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Icons.touch_app,
              color: Colors.white.withValues(alpha: 0.9),
              size: 40,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(2, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
