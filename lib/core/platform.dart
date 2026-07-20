import 'package:flutter/foundation.dart';
import 'dart:js' as js;

/// Platform utility helper to check Web/PWA specific features.
class PlatformUtils {
  static bool get isWeb => kIsWeb;

  /// Checks if the JS Navigator Share API is available (Web PWA)
  static bool get hasShareAPI {
    if (!isWeb) return true; // Mobile has native share
    try {
      return js.context.callMethod('isShareSupported') as bool;
    } catch (_) {
      return false;
    }
  }

  /// Trigger sharing or fallback to copy
  static void shareText(String text, {required VoidCallback onCopied}) {
    if (isWeb) {
      try {
        final shared = js.context.callMethod('shareText', [text]) as bool;
        if (!shared) {
          onCopied();
        }
      } catch (_) {
        onCopied();
      }
    } else {
      // In native Android, we would typically use share_plus,
      // but since we are minimizing packages, we can just copy to clipboard!
      onCopied();
    }
  }

  /// Triggers PWA install prompt if captured
  static void triggerPWAInstall() {
    if (isWeb) {
      try {
        js.context.callMethod('triggerPwaInstall');
      } catch (_) {}
    }
  }

  /// Checks if PWA install prompt is available
  static bool get canInstallPWA {
    if (!isWeb) return false;
    try {
      return js.context.callMethod('canInstallPwa') as bool;
    } catch (_) {
      return false;
    }
  }
}
