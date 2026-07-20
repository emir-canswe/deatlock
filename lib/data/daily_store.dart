import 'progress_store.dart';

/// Manages daily level states and streaks.
class DailyStore {
  final ProgressStore _store;

  DailyStore(this._store);

  /// Helper to get YYYY-MM-DD string from a DateTime
  static String getTodayKey() {
    final now = DateTime.now();
    return getDateKey(now);
  }

  static String getDateKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static int getSeedForDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Get streak
  int get streak => _store.dailyStreak;

  /// Check if played today
  bool get hasPlayedToday {
    final today = getTodayKey();
    return _store.getDailyMoves(today) != null;
  }

  /// Get status of today (returns null if not played, -1 if failed, otherwise moves)
  int? get todayScore {
    final today = getTodayKey();
    return _store.getDailyMoves(today);
  }

  /// Record daily solve
  Future<void> recordSolve(int moves) async {
    final today = getTodayKey();
    final prevScore = _store.getDailyMoves(today);
    if (prevScore != null) return; // Only first attempt counts

    await _store.setDailyMoves(today, moves);

    // Update streak logic
    final yesterdayStr = getDateKey(DateTime.now().subtract(const Duration(days: 1)));
    final lastPlayedStr = _store.dailyLastDate;

    int newStreak = 1;
    if (lastPlayedStr == yesterdayStr) {
      newStreak = _store.dailyStreak + 1;
    } else if (lastPlayedStr == today) {
      newStreak = _store.dailyStreak; // already set today
    }
    
    await _store.setDailyStreak(newStreak);
    await _store.setDailyLastDate(today);
  }

  /// Record daily reset (invalidates attempt)
  Future<void> recordReset() async {
    final today = getTodayKey();
    final prevScore = _store.getDailyMoves(today);
    if (prevScore != null) return; // Already solved/failed, don't overwrite

    // Mark as -1 (which means failed / "—" in UI)
    await _store.setDailyMoves(today, -1);
    
    // Break streak
    await _store.setDailyStreak(0);
    await _store.setDailyLastDate(today);
  }

  /// Returns history for last 30 days (excluding today if not played yet)
  /// List of map: {'date': DateTime, 'moves': int (moves or -1 for fail)}
  List<Map<String, dynamic>> getLast30DaysHistory() {
    final list = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = getDateKey(date);
      final val = _store.getDailyMoves(key);
      list.add({
        'date': date,
        'key': key,
        'moves': val, // null if not played, -1 if failed, positive if solved
      });
    }
    return list;
  }
}
