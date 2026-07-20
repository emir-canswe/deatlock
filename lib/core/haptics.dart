import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around HapticFeedback that respects user settings.
class Haptics {
  static bool _enabled = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('haptics') ?? true;
  }

  static bool get enabled => _enabled;

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics', value);
  }

  static void selectionClick() {
    if (_enabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void lightImpact() {
    if (_enabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
  }
}
