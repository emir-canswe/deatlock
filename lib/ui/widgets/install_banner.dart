import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../../core/platform.dart';
import '../../core/theme.dart';
import '../../core/strings.dart';

/// PWA Install invitation banner. Displays if installation prompt is available in browser.
class InstallBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const InstallBanner({
    super.key,
    required this.onDismiss,
  });

  void _onInstall(BuildContext context) {
    if (PlatformUtils.canInstallPWA) {
      PlatformUtils.triggerPWAInstall();
    } else {
      // iOS Safari fallback instruction dialog
      showDialog(
        context: context,
        builder: (ctx) {
          final sDialog = S.of(ctx);
          return AlertDialog(
            backgroundColor: Palette.boardBg,
            title: Text(
              sDialog.installCta.toUpperCase(),
              style: ThemeConfig.titleStyle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sDialog.installSafariDesc,
                  style: ThemeConfig.labelStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  sDialog.installSafariStep1,
                  style: ThemeConfig.bodyStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  sDialog.installSafariStep2,
                  style: ThemeConfig.bodyStyle,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  sDialog.okBtn,
                  style: ThemeConfig.labelStyle.copyWith(color: Palette.targetEnd),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.cellPocket,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.install_mobile_outlined, color: Palette.textHigh, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _onInstall(context),
              child: Text(
                s.installCta,
                style: ThemeConfig.labelStyle.copyWith(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, color: Palette.textLow, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

