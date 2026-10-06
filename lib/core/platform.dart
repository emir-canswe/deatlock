import 'package:flutter/foundation.dart';

// Delegates to a platform-specific implementation chosen at compile time.
// Native builds get `platform_io.dart` (no web libraries); web builds get
// `platform_web.dart` (modern `dart:js_interop`). This keeps web-only
// libraries out of the native (Android/iOS) compilation.
import 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';

/// Platform utility helper to check Web/PWA specific features.
class PlatformUtils {
  static bool get isWeb => PlatformUtilsImpl.isWeb;

  /// Checks if the JS Navigator Share API is available (Web PWA).
  static bool get hasShareAPI => PlatformUtilsImpl.hasShareAPI;

  /// Trigger sharing or fallback to copy.
  static void shareText(String text, {required VoidCallback onCopied}) =>
      PlatformUtilsImpl.shareText(text, onCopied: onCopied);

  /// Triggers PWA install prompt if captured.
  static void triggerPWAInstall() => PlatformUtilsImpl.triggerPWAInstall();

  /// Checks if PWA install prompt is available.
  static bool get canInstallPWA => PlatformUtilsImpl.canInstallPWA;
}
