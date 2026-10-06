import 'dart:js_interop';
import 'package:flutter/foundation.dart';

// Bindings to the global JS helpers defined in web/index.html.
@JS('isShareSupported')
external bool _isShareSupported();

@JS('shareText')
external bool _shareText(String text);

@JS('triggerPwaInstall')
external void _triggerPwaInstall();

@JS('canInstallPwa')
external bool _canInstallPwa();

/// Web implementation using modern `dart:js_interop`.
class PlatformUtilsImpl {
  static bool get isWeb => true;

  static bool get hasShareAPI {
    try {
      return _isShareSupported();
    } catch (_) {
      return false;
    }
  }

  static void shareText(String text, {required VoidCallback onCopied}) {
    try {
      final shared = _shareText(text);
      if (!shared) onCopied();
    } catch (_) {
      onCopied();
    }
  }

  static void triggerPWAInstall() {
    try {
      _triggerPwaInstall();
    } catch (_) {}
  }

  static bool get canInstallPWA {
    try {
      return _canInstallPwa();
    } catch (_) {
      return false;
    }
  }
}
