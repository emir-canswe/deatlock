import 'package:flutter/foundation.dart';
import '../data/progress_store.dart';
import '../data/daily_store.dart';
import '../domain/game_mode.dart';

/// Progress controller managing levels, hints economy, and daily logs.
class ProgressController extends ChangeNotifier {
  final ProgressStore _store;
  late final DailyStore _dailyStore;

  GameMode _activeMode = GameMode.levels;

  ProgressController(this._store) {
    _dailyStore = DailyStore(_store);
    _store.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    super.dispose();
  }

  DailyStore get dailyStore => _dailyStore;
  GameMode get activeMode => _activeMode;

  int get unlockedLevel => _store.unlockedLevel;
  int? getBestMoves(int level) => _store.getBestMoves(level);
  bool isPerfect(int level) => _store.isPerfect(level);
  
  // Hint economy
  int get hints => _store.hints;

  Future<void> useHint() async {
    if (hints > 0) {
      await _store.setHints(hints - 1);
      notifyListeners();
    }
  }

  Future<void> addHintReward() async {
    if (hints < 5) {
      await _store.setHints(hints + 1);
      notifyListeners();
    }
  }

  void changeMode(GameMode mode) {
    _activeMode = mode;
    notifyListeners();
  }

  /// Complete a level in Levels mode
  Future<void> completeLevel(int level, int moves, bool perfect) async {
    await _store.setBestMoves(level, moves);
    
    // Set perfect flag (perfect = not using hints & solved in optimal moves)
    if (perfect) {
      await _store.setPerfect(level, true);
    }
    
    // Unlock next level
    if (level >= unlockedLevel) {
      await _store.setUnlockedLevel(level + 1);
    }

    // Reward 1 hint on successful level solve, capped at 5
    await addHintReward();

    notifyListeners();
  }

  /// Record daily attempt win
  Future<void> recordDailyWin(int moves) async {
    await _dailyStore.recordSolve(moves);
    notifyListeners();
  }

  /// Record daily attempt reset (fail/break streak)
  Future<void> recordDailyReset() async {
    await _dailyStore.recordReset();
    notifyListeners();
  }

  /// Reset all statistics
  Future<void> resetProgress() async {
    await _store.resetProgress();
    notifyListeners();
  }

  int get sprintBest => _store.sprintBest;
  bool get soundEnabled => _store.soundEnabled;

  Future<void> setSoundEnabled(bool value) async {
    await _store.setSoundEnabled(value);
    notifyListeners();
  }

  ProgressStore getProgressStore() => _store;

  String get language => _store.language;
  Future<void> setLanguage(String value) async {
    await _store.setLanguage(value);
    notifyListeners();
  }
}
