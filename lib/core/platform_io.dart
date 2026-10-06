import 'package:flutter/foundation.dart';

/// Native (Android/iOS/desktop) implementation. No web libraries.
class PlatformUtilsImpl {
  static bool get isWeb => false;

  // Native platforms are treated as always having a share mechanism.
  static bool get hasShareAPI => true;

  static void shareText(String text, {required VoidCallback onCopied}) {
    // Packages are intentionally kept minimal, so native share falls back
    // to copying the text to the clipboard via the caller's [onCopied].
    onCopied();
  }

  static void triggerPWAInstall() {}

  static bool get canInstallPWA => false;
}
