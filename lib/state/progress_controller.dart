import 'package:flutter/foundation.dart';
import '../data/progress_store.dart';
import '../data/daily_store.dart';
import '../domain/game_mode.dart';

import '../domain/star_gate.dart';

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
  int getStars(int level) => _store.getStars(level);
  int get totalStars => _store.totalStars;
  
  // Hint economy
  int get hints => _store.hints;

  Future<void> useHint() async {
    if (hints > 0) {
      await _store.setHints(hints - 1);
      notifyListeners();
    }
  }

  Future<void> addHintReward([int count = 1]) async {
    await _store.setHints(hints + count);
    notifyListeners();
  }

  void changeMode(GameMode mode) {
    _activeMode = mode;
    notifyListeners();
  }

  /// Whether reaching nextLevel is currently blocked by a Star Gate milestone.
  bool isGateBlockedForNext(int currentLevel) {
    final nextLevel = currentLevel + 1;
    if (!StarGate.isGateLevel(nextLevel)) return false;
    return !StarGate.canUnlockLevel(nextLevel, totalStars);
  }

  /// Complete a level in Levels mode
  Future<void> completeLevel(
    int level,
    int moves,
    bool perfect, {
    int? optimalMoves,
    bool? hintUsed,
  }) async {
    await _store.setBestMoves(level, moves);
    
    // Set perfect flag
    if (perfect) {
      await _store.setPerfect(level, true);
    }

    // Calculate & persist stars
    final stars = StarGate.calculateStars(
      moves: moves,
      optimalMoves: optimalMoves ?? moves,
      hintUsed: hintUsed ?? !perfect,
    );
    await _store.setStars(level, stars);
    
    // Check if next level can be unlocked
    final nextLevel = level + 1;
    if (nextLevel > unlockedLevel) {
      if (StarGate.canUnlockLevel(nextLevel, _store.totalStars)) {
        await _store.setUnlockedLevel(nextLevel);
      }
    } else {
      // Check if replaying an earlier level freed up a stuck gate
      final pendingGate = unlockedLevel + 1;
      if (StarGate.isGateLevel(pendingGate) && StarGate.canUnlockLevel(pendingGate, _store.totalStars)) {
        await _store.setUnlockedLevel(pendingGate);
      }
    }

    // Note: Hints are given only upon starting the game (5 hints) and preserved across levels.
    // They are not replenished automatically when completing levels.
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

  String get themeMode => _store.themeMode;
  Future<void> setThemeMode(String value) async {
    await _store.setThemeMode(value);
    notifyListeners();
  }
}
