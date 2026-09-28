/// Star Gate logic for Deadlock level progression.
/// Every 50 levels, unlocking the next tier requires reaching a target star count.
class StarGate {
  /// Gate interval (every 50 levels: 50 -> 51, 100 -> 101, etc.)
  static const int interval = 50;

  /// Calculate stars awarded for a level (1 to 3 stars).
  /// - 3 stars: Solved in optimal moves without hints.
  /// - 2 stars: Solved in optimal + 2 moves without hints, or optimal moves with hint.
  /// - 1 star: Any successful completion.
  static int calculateStars({
    required int moves,
    required int optimalMoves,
    required bool hintUsed,
  }) {
    if (moves <= 0) return 0;
    if (hintUsed) {
      return moves <= optimalMoves ? 2 : 1;
    }
    if (moves <= optimalMoves) {
      return 3;
    } else if (moves <= optimalMoves + 2) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Whether reaching this level requires passing a Star Gate.
  /// E.g. Level 51, 101, 151, 201...
  static bool isGateLevel(int level) {
    return level > 1 && (level - 1) % interval == 0;
  }

  /// The level index that triggers this gate (e.g. for level 51, gate is at 50).
  static int triggerLevelFor(int gateLevel) {
    return gateLevel - 1;
  }

  /// Required cumulative stars to unlock the specified level.
  /// Levels 1..50 require 0 stars.
  /// Level 51 requires 100 stars.
  /// Level 101 requires 210 stars.
  /// Level 151 requires 325 stars, etc.
  static int requiredStarsForLevel(int level) {
    if (level <= interval) return 0;

    // Which tier is this level in?
    // level 51..100 -> tier 1 gate (needed to enter tier 2)
    final tier = (level - 1) ~/ interval;
    if (tier <= 0) return 0;

    // Tier 1: 100 stars, Tier 2: 210 (+110), Tier 3: 325 (+115), Tier 4: 440 (+115)...
    if (tier == 1) return 100;
    return 100 + (tier - 1) * 115;
  }

  /// Total possible stars up to a given level (3 stars per level).
  static int maxPossibleStars(int level) {
    return level * 3;
  }

  /// Whether the player has enough stars to unlock `level`.
  static bool canUnlockLevel(int level, int totalStars) {
    return totalStars >= requiredStarsForLevel(level);
  }
}
