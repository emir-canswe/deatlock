import 'package:flutter/material.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';

/// A 3D chunky cartoon-style button replicating the theme of Block Kule.
/// Physically sinks when pressed and features a hard solid bottom shadow.
class ChunkyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final Color shadowColor;
  final double borderRadius;
  final double depth;
  final double? width;
  final double? height;
  final bool enabled;

  const ChunkyButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.color,
    required this.shadowColor,
    this.borderRadius = 18.0,
    this.depth = 4.0,
    this.width,
    this.height,
    this.enabled = true,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Opacity(
        opacity: 0.35,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: widget.shadowColor, width: 2),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: widget.child,
        ),
      );
    }

    final double topOffset = _isPressed ? widget.depth : 0.0;
    final double shadowHeight = _isPressed ? 0.0 : widget.depth;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        Haptics.lightImpact();
        Audio.playClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        width: widget.width,
        height: widget.height,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: topOffset, bottom: widget.depth - topOffset),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.shadowColor, width: 2),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.shadowColor,
                offset: Offset(0, shadowHeight),
                blurRadius: 0,
              ),
          ],
        ),
        child: Center(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
