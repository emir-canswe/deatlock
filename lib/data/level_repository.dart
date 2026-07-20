import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/generator.dart';

/// Top-level helper function for compute isolate.
GeneratedLevel _generateLevelIsolate(int level) {
  return generate(level: level);
}

/// Generates and caches levels. Uses isolates for complex levels (121+)
/// and background pre-generates the next level.
class LevelRepository {
  final Map<int, GeneratedLevel> _cache = {};
  final Set<int> _preloading = {};

  /// Get a level. Resolves instantly if cached, else generates it.
  /// Automatically triggers background preloading of [levelNumber + 1].
  Future<GeneratedLevel> getLevel(int levelNumber) async {
    if (_cache.containsKey(levelNumber)) {
      _preloadNext(levelNumber + 1);
      return _cache[levelNumber]!;
    }

    final level = await _generate(levelNumber);
    _cache[levelNumber] = level;

    _preloadNext(levelNumber + 1);
    return level;
  }

  /// Check if a level is already generated and cached.
  bool isCached(int levelNumber) => _cache.containsKey(levelNumber);

  /// Synchronously retrieve a level if cached.
  GeneratedLevel? getCachedLevel(int levelNumber) => _cache[levelNumber];

  Future<GeneratedLevel> _generate(int levelNumber) async {
    // Only use isolates for standard progression levels >= 121 (to avoid web worker constraints elsewhere)
    if (levelNumber >= 121 && levelNumber < 9999 && !kIsWeb) {
      return await compute(_generateLevelIsolate, levelNumber);
    } else {
      return generate(level: levelNumber);
    }
  }

  void _preloadNext(int nextLevel) {
    if (_cache.containsKey(nextLevel) || _preloading.contains(nextLevel)) {
      return;
    }

    // Do not preload across mode bounds
    if (nextLevel >= 9999) return;

    _preloading.add(nextLevel);
    _generate(nextLevel).then((level) {
      _cache[nextLevel] = level;
      _preloading.remove(nextLevel);
    }).catchError((_) {
      _preloading.remove(nextLevel);
    });
  }

  void clearCache() {
    _cache.clear();
    _preloading.clear();
  }
}
