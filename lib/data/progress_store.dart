import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progress store updated for Deadlock v3.
class ProgressStore extends ChangeNotifier {
  final SharedPreferences _prefs;

  ProgressStore(this._prefs);

  bool get isReady => true;

  // Levels mode
  int get unlockedLevel => _prefs.getInt('unlocked') ?? 1;
  Future<void> setUnlockedLevel(int level) async {
    await _prefs.setInt('unlocked', level);
    notifyListeners();
  }

  int? getBestMoves(int level) => _prefs.getInt('best_$level');
  Future<void> setBestMoves(int level, int moves) async {
    final current = getBestMoves(level);
    if (current == null || moves < current) {
      await _prefs.setInt('best_$level', moves);
      notifyListeners();
    }
  }

  bool isPerfect(int level) => _prefs.getBool('perfect_$level') ?? false;
  Future<void> setPerfect(int level, bool perfect) async {
    await _prefs.setBool('perfect_$level', perfect);
    notifyListeners();
  }

  // Hint economy (starts at 3, max 5)
  int get hints => _prefs.getInt('hints') ?? 3;
  Future<void> setHints(int count) async {
    final clamped = count.clamp(0, 5);
    await _prefs.setInt('hints', clamped);
    notifyListeners();
  }

  // Daily mode streak and dates
  int get dailyStreak => _prefs.getInt('daily_streak') ?? 0;
  Future<void> setDailyStreak(int streak) async {
    await _prefs.setInt('daily_streak', streak);
    notifyListeners();
  }

  String? get dailyLastDate => _prefs.getString('daily_last');
  Future<void> setDailyLastDate(String dateStr) async {
    await _prefs.setString('daily_last', dateStr);
    notifyListeners();
  }

  int? getDailyMoves(String dateStr) => _prefs.getInt('daily_$dateStr');
  Future<void> setDailyMoves(String dateStr, int moves) async {
    await _prefs.setInt('daily_$dateStr', moves);
    notifyListeners();
  }

  // Sprint mode best score
  int get sprintBest => _prefs.getInt('sprint_best') ?? 0;
  Future<void> setSprintBest(int score) async {
    final current = sprintBest;
    if (score > current) {
      await _prefs.setInt('sprint_best', score);
      notifyListeners();
    }
  }

  // Settings
  bool get hapticsEnabled => _prefs.getBool('haptics') ?? true;
  Future<void> setHapticsEnabled(bool value) async {
    await _prefs.setBool('haptics', value);
    notifyListeners();
  }

  bool get soundEnabled => _prefs.getBool('sound') ?? false;
  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool('sound', value);
    notifyListeners();
  }

  String get language => _prefs.getString('language') ?? 'system';
  Future<void> setLanguage(String value) async {
    await _prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    final haptics = hapticsEnabled;
    final sound = soundEnabled;
    final lang = language;
    await _prefs.clear();
    await _prefs.setBool('haptics', haptics);
    await _prefs.setBool('sound', sound);
    await _prefs.setString('language', lang);
    await setHints(3);
    notifyListeners();
  }
}
