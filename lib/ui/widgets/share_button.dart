import 'package:flutter/material.dart';
import '../../core/platform.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../domain/share_card.dart';

/// Share button component for Daily mode win sheets.
/// Attempts to open system share sheet, falling back to clipboard copy with visual feedback.
class ShareButton extends StatefulWidget {
  final int dailyNumber;
  final int moves;
  final int optimal;

  const ShareButton({
    super.key,
    required this.dailyNumber,
    required this.moves,
    required this.optimal,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _copied = false;

  void _onShare() {
    final s = S.of(context);
    final text = generateShareCard(
      dailyNumber: widget.dailyNumber,
      moves: widget.moves,
      optimal: widget.optimal,
      gameUrl: 'https://emir-canswe.github.io/deadlock/', // fallback production URL
      isEnglish: !s.isTr,
    );

    PlatformUtils.shareText(
      text,
      onCopied: () {
        setState(() => _copied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.copiedFeedback),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF19BFA0),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _copied = false);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: _onShare,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF19BFA0),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          _copied ? s.copiedLabel : s.shareResultLabel,
          style: ThemeConfig.buttonTextStyle.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
