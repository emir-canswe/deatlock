import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../../core/strings.dart';
import '../../domain/game_mode.dart';
import 'chunky_button.dart';

/// Bottom action bar containing Undo, Hint, and Reset buttons.
/// Styled as premium 3D ChunkyButtons following the block kule aesthetic.
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
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
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

  void _triggerHintShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final showUndo = widget.mode.allowsUndo;
    final showHint = widget.mode.allowsHint;

    final isHintZen = widget.mode == GameMode.zen;
    final isHintZero = widget.hintCount <= 0 && !isHintZen;
    final s = S.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          // 1. Undo Button (3D White with Undo Icon)
          Expanded(
            child: ChunkyButton(
              color: Colors.white,
              shadowColor: const Color(0xFFCBD5E1),
              borderRadius: 16,
              depth: 4,
              enabled: showUndo && widget.canUndo,
              onPressed: widget.onUndo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.undo_rounded, color: Palette.textHigh, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    s.undo,
                    style: ThemeConfig.buttonTextStyle.copyWith(
                      color: Palette.textHigh,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. Hint Button (3D Green with Incandescent Bulb Icon)
          Expanded(
            child: Transform.translate(
              offset: Offset(_shakeAnimation.value, 0.0),
              child: ChunkyButton(
                color: Palette.primary,
                shadowColor: Palette.primaryDark,
                borderRadius: 16,
                depth: 4,
                enabled: showHint,
                onPressed: () {
                  if (isHintZero) {
                    _triggerHintShake();
                  } else {
                    widget.onHint();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_incandescent_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      isHintZen ? s.hint : s.hintN(widget.hintCount),
                      style: ThemeConfig.buttonTextStyle.copyWith(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 3. Reset Button (3D White with Refresh Icon)
          Expanded(
            child: ChunkyButton(
              color: Colors.white,
              shadowColor: const Color(0xFFCBD5E1),
              borderRadius: 16,
              depth: 4,
              onPressed: widget.onReset,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, color: Palette.textHigh, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    s.retry,
                    style: ThemeConfig.buttonTextStyle.copyWith(
                      color: Palette.textHigh,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
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
