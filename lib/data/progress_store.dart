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

  // Star economy (1 to 3 stars per level)
  int getStars(int level) {
    final stored = _prefs.getInt('stars_$level');
    if (stored != null) return stored;
    // Backward compatibility fallback
    if (isPerfect(level)) return 3;
    if (getBestMoves(level) != null) return 1;
    return 0;
  }

  Future<void> setStars(int level, int stars) async {
    final current = getStars(level);
    if (stars > current) {
      await _prefs.setInt('stars_$level', stars);
      notifyListeners();
    }
  }

  /// Total stars collected across all unlocked/played levels.
  int get totalStars {
    int sum = 0;
    final maxLvl = unlockedLevel;
    for (int i = 1; i <= maxLvl; i++) {
      sum += getStars(i);
    }
    return sum;
  }

  // Hint economy (starts at 5 on initial game launch, strictly preserved across levels)
  int get hints {
    if (!_prefs.containsKey('hints')) {
      return 5;
    }
    // Upgrade previous default of 3 to 5 if present
    if ((_prefs.getBool('hints_initial_5_v2') ?? false) == false && _prefs.getInt('hints') == 3) {
      _prefs.setInt('hints', 5);
      _prefs.setBool('hints_initial_5_v2', true);
      return 5;
    }
    return _prefs.getInt('hints') ?? 5;
  }

  Future<void> setHints(int count) async {
    final clamped = count < 0 ? 0 : count;
    await _prefs.setInt('hints', clamped);
    await _prefs.setBool('hints_initial_5_v2', true);
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

  String get themeMode => _prefs.getString('theme_mode') ?? 'system';
  Future<void> setThemeMode(String value) async {
    await _prefs.setString('theme_mode', value);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    final haptics = hapticsEnabled;
    final sound = soundEnabled;
    final lang = language;
    final theme = themeMode;
    await _prefs.clear();
    await _prefs.setBool('haptics', haptics);
    await _prefs.setBool('sound', sound);
    await _prefs.setString('language', lang);
    await _prefs.setString('theme_mode', theme);
    await setHints(5);
    notifyListeners();
  }
}
