import 'package:flutter/material.dart';
import '../../core/audio.dart';
import '../../core/haptics.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../../domain/game_mode.dart';

/// Premium, juicy 3D bottom action bar.
/// Features tactile physical buttons with proper height (52-56px),
/// high-contrast styling in both dark and light modes, glowing central Hint button
/// with badge counter, and long-press repeat support for Undo.
class BottomBar extends StatefulWidget {
  final GameMode mode;
  final int hintCount;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onReset;
  final VoidCallback? onUndoLongPressStart;
  final VoidCallback? onUndoLongPressEnd;

  const BottomBar({
    super.key,
    required this.mode,
    required this.hintCount,
    required this.canUndo,
    required this.onUndo,
    required this.onHint,
    required this.onReset,
    this.onUndoLongPressStart,
    this.onUndoLongPressEnd,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _shakeController.addListener(() => setState(() {}));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showUndo = widget.mode.allowsUndo;
    final showHint = widget.mode.allowsHint;
    final isHintZen = widget.mode == GameMode.zen;
    // With no hints left the button offers a rewarded ad instead.
    final isHintAd = widget.hintCount <= 0 && !isHintZen;
    final s = S.of(context);
    final isDark = Palette.isDark;

    // Card & button surface colors
    final secondaryBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final secondaryBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final secondaryShadow = isDark ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);
    final secondaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0C447C);
    final secondaryIconColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0C447C);

    // Hint active colors
    final hintBg = isDark ? const Color(0xFF10B981) : const Color(0xFF1D9E75);
    final hintBorder = isDark ? const Color(0xFF34D399) : const Color(0xFF2DD4BF);
    final hintShadow = isDark ? const Color(0xFF047857) : const Color(0xFF0F5B46);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. Undo Button (3D Tile)
          Expanded(
            flex: 10,
            child: _Action3DButton(
              height: 52,
              color: secondaryBg,
              borderColor: secondaryBorder,
              shadowColor: secondaryShadow,
              borderRadius: 18,
              depth: 4,
              enabled: showUndo && widget.canUndo,
              onPressed: widget.onUndo,
              onLongPressStart: widget.onUndoLongPressStart,
              onLongPressEnd: widget.onUndoLongPressEnd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.undo_rounded, color: secondaryIconColor, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    s.undo,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 2. Hint Button (Elevated 56px Center Hero Button with Glowing Bulb & Badge)
          Expanded(
            flex: 12,
            child: Transform.translate(
              offset: Offset(_shakeAnimation.value, 0.0),
              child: _Action3DButton(
                height: 56,
                color: hintBg,
                borderColor: hintBorder,
                shadowColor: hintShadow,
                borderRadius: 20,
                depth: 4.5,
                enabled: showHint,
                glowColor: hintBg.withValues(alpha: isDark ? 0.35 : 0.25),
                onPressed: widget.onHint,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing incandescent lightbulb
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0x33FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Color(0xFFFDE047), // bright sunny amber
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.hint,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Hint counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isHintZen ? '∞' : (isHintAd ? 'AD' : '${widget.hintCount}'),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 3. Reset Button (3D Tile)
          Expanded(
            flex: 10,
            child: _Action3DButton(
              height: 52,
              color: secondaryBg,
              borderColor: secondaryBorder,
              shadowColor: secondaryShadow,
              borderRadius: 18,
              depth: 4,
              enabled: true,
              onPressed: widget.onReset,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: secondaryIconColor, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    s.retry,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final Color? glowColor;
  final double height;
  final double depth;
  final double borderRadius;
  final bool enabled;

  const _Action3DButton({
    required this.child,
    required this.color,
    required this.borderColor,
    required this.shadowColor,
    this.glowColor,
    this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.height = 52.0,
    this.depth = 4.0,
    this.borderRadius = 18.0,
    this.enabled = true,
  });

  @override
  State<_Action3DButton> createState() => _Action3DButtonState();
}

class _Action3DButtonState extends State<_Action3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Opacity(
        opacity: 0.38,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: widget.borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      );
    }

    final double topOffset = _isPressed ? widget.depth : 0.0;
    final double shadowHeight = _isPressed ? 0.0 : widget.depth;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        Haptics.selectionClick();
        Audio.playClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onLongPressStart: widget.onLongPressStart != null
          ? (_) {
              setState(() => _isPressed = true);
              Haptics.mediumImpact();
              widget.onLongPressStart?.call();
            }
          : null,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onLongPressEnd?.call();
            }
          : null,
      child: AnimatedContainer(
        height: widget.height,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: topOffset, bottom: widget.depth - topOffset),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.borderColor, width: 1.8),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.shadowColor,
                offset: Offset(0, shadowHeight),
                blurRadius: 0,
              ),
            if (widget.glowColor != null && !_isPressed)
              BoxShadow(
                color: widget.glowColor!,
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
