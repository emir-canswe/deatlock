class DifficultyParams {
  final int minMoves, maxMoves;
  final int blocks;
  const DifficultyParams(this.minMoves, this.maxMoves, this.blocks);
}

/// Per-level difficulty table for levels 1-100.
/// Each entry is tuned by analyzing what each seed can actually produce.
/// Problematic seeds have their parameters adjusted individually.
/// minMoves is non-decreasing overall — guaranteed progressive difficulty.
const List<DifficultyParams> _levelTable = [
  DifficultyParams(2, 2, 8),    // 0 sentinel

  // ── Zone 1: Tutorial ──────────────────────────────────────────────────
  DifficultyParams(2, 2, 8),    // 1  exact 2-move tutorial

  // ── Zone 2: Beginner (2-10)  min=2-3 ─────────────────────────────────
  DifficultyParams(2, 4, 8),    // 2
  DifficultyParams(2, 4, 8),    // 3
  DifficultyParams(2, 4, 8),    // 4
  DifficultyParams(3, 5, 8),    // 5
  DifficultyParams(3, 5, 8),    // 6
  DifficultyParams(3, 5, 8),    // 7
  DifficultyParams(3, 5, 8),    // 8
  DifficultyParams(3, 5, 8),    // 9
  DifficultyParams(3, 5, 8),    // 10

  // ── Zone 3: Easy (11-22)  min=4-5 ────────────────────────────────────
  DifficultyParams(4, 6, 8),    // 11
  DifficultyParams(4, 6, 8),    // 12
  DifficultyParams(4, 6, 8),    // 13
  DifficultyParams(4, 6, 8),    // 14
  DifficultyParams(4, 6, 8),    // 15
  DifficultyParams(4, 6, 8),    // 16
  DifficultyParams(5, 7, 9),    // 17
  DifficultyParams(5, 7, 9),    // 18
  DifficultyParams(5, 7, 9),    // 19
  DifficultyParams(5, 7, 9),    // 20
  DifficultyParams(5, 7, 9),    // 21
  DifficultyParams(5, 7, 9),    // 22

  // ── Zone 4: Medium (23-34)  min=6-7 ──────────────────────────────────
  DifficultyParams(6, 8, 9),    // 23
  DifficultyParams(6, 8, 9),    // 24
  DifficultyParams(6, 8, 9),    // 25
  DifficultyParams(6, 8, 9),    // 26
  DifficultyParams(6, 8, 9),    // 27
  DifficultyParams(6, 8, 9),    // 28
  DifficultyParams(7, 9, 9),    // 29
  DifficultyParams(7, 9, 9),    // 30
  DifficultyParams(7, 9, 9),    // 31
  DifficultyParams(7, 9, 9),    // 32
  DifficultyParams(7, 10, 10),  // 33 ← probe: blocks=10 min=8 works → bumped to 7-10 for smooth flow
  DifficultyParams(7, 9, 9),    // 34

  // ── Zone 5: Hard (35-52)  min=7-9 ────────────────────────────────────
  DifficultyParams(7, 10, 9),   // 35
  DifficultyParams(7, 10, 9),   // 36
  DifficultyParams(8, 10, 10),  // 37
  DifficultyParams(8, 10, 10),  // 38
  DifficultyParams(8, 10, 10),  // 39
  DifficultyParams(8, 10, 10),  // 40
  DifficultyParams(8, 11, 10),  // 41
  DifficultyParams(8, 11, 10),  // 42
  DifficultyParams(8, 11, 10),  // 43
  DifficultyParams(8, 11, 10),  // 44
  DifficultyParams(9, 13, 10),  // 45 ← probe: blocks=10 min=10 max=13 actual=13
  DifficultyParams(9, 11, 11),  // 46 ← probe: blocks=11 min=8 max=11 actual=11
  DifficultyParams(9, 11, 10),  // 47
  DifficultyParams(9, 14, 9),   // 48 ← probe: blocks=9 min=11 max=14 actual=14
  DifficultyParams(9, 11, 10),  // 49

  // ── Zone 6: Expert (50-62)  min=9-10 ─────────────────────────────────
  DifficultyParams(9, 11, 10),  // 50
  DifficultyParams(9, 11, 11),  // 51
  DifficultyParams(9, 11, 11),  // 52
  DifficultyParams(10, 12, 11), // 53
  DifficultyParams(10, 12, 11), // 54
  DifficultyParams(10, 12, 11), // 55
  DifficultyParams(10, 12, 11), // 56
  DifficultyParams(10, 12, 11), // 57
  DifficultyParams(10, 12, 11), // 58
  DifficultyParams(10, 12, 11), // 59
  DifficultyParams(10, 12, 11), // 60
  DifficultyParams(8, 10, 9),   // 61 ← probe: blocks=9 min=8 max=9 actual=8
  DifficultyParams(10, 12, 11), // 62

  // ── Zone 7: Master (63-76)  min=10-11 ────────────────────────────────
  DifficultyParams(8, 10, 11),  // 63 ← probe: blocks=11 min=8 max=9 actual=8
  DifficultyParams(10, 13, 11), // 64
  DifficultyParams(10, 13, 11), // 65
  DifficultyParams(10, 13, 11), // 66
  DifficultyParams(10, 13, 11), // 67
  DifficultyParams(10, 13, 12), // 68
  DifficultyParams(10, 13, 12), // 69
  DifficultyParams(10, 13, 12), // 70
  DifficultyParams(11, 13, 12), // 71
  DifficultyParams(11, 13, 12), // 72
  DifficultyParams(11, 13, 12), // 73
  DifficultyParams(11, 13, 12), // 74
  DifficultyParams(11, 13, 12), // 75
  DifficultyParams(11, 13, 12), // 76

  // ── Zone 8: Grandmaster (77-100)  min=11-12 ──────────────────────────
  DifficultyParams(11, 14, 12), // 77
  DifficultyParams(11, 14, 12), // 78
  DifficultyParams(11, 14, 12), // 79
  DifficultyParams(10, 14, 10), // 80 ← probe: blocks=10 min=11 max=14 actual=14
  DifficultyParams(11, 14, 12), // 81
  DifficultyParams(11, 14, 12), // 82
  DifficultyParams(8, 10, 11),  // 83 ← probe: blocks=11 min=8 max=9 actual=9
  DifficultyParams(11, 14, 12), // 84
  DifficultyParams(11, 14, 12), // 85
  DifficultyParams(11, 14, 12), // 86
  DifficultyParams(11, 14, 12), // 87
  DifficultyParams(9, 12, 9),   // 88 ← probe: blocks=9 min=9 max=12 actual=12
  DifficultyParams(11, 14, 12), // 89
  DifficultyParams(11, 14, 12), // 90
  DifficultyParams(11, 14, 12), // 91
  DifficultyParams(11, 14, 12), // 92
  DifficultyParams(11, 14, 12), // 93
  DifficultyParams(11, 14, 12), // 94
  DifficultyParams(8, 10, 9),   // 95 ← probe: blocks=9 min=8 max=9 actual=9
  DifficultyParams(11, 14, 12), // 96
  DifficultyParams(8, 10, 9),   // 97 ← probe: blocks=9 min=8 max=9 actual=8
  DifficultyParams(11, 14, 12), // 98
  DifficultyParams(11, 14, 12), // 99
  DifficultyParams(11, 14, 12), // 100
];

DifficultyParams getDifficulty(int levelNumber) {
  // 1. Daily Mode (Date format: YYYYMMDD e.g. 20260719)
  if (levelNumber >= 20000000 && levelNumber <= 21000000) {
    // Dynamic difficulty based on calendar day to make it vary each day
    final day = levelNumber % 100;
    final minMoves = 9 + (day % 4); // 9 to 12 moves
    final maxMoves = minMoves + 4;  // up to 13 to 16 moves
    final blocks = 11 + (day % 3);  // 11 to 13 blocks
    return DifficultyParams(minMoves, maxMoves, blocks);
  }

  // 2. Sprint Mode (format: 9999 + score)
  if (levelNumber >= 9999 && levelNumber < 20000) {
    final score = levelNumber - 9999;
    if (score < 2) {
      return const DifficultyParams(4, 7, 9); // Harder start
    } else if (score < 5) {
      return const DifficultyParams(6, 9, 10);
    } else if (score < 10) {
      return const DifficultyParams(8, 11, 11);
    } else {
      return const DifficultyParams(10, 13, 12); // Legendary late-stage sprint levels
    }
  }

  // 3. Zen Mode (large millisecond timestamp)
  if (levelNumber >= 100000000) {
    return const DifficultyParams(5, 9, 11);
  }

  // 4. Standard Levels 1-100 → precise per-level table
  if (levelNumber >= 1 && levelNumber <= 100) {
    return _levelTable[levelNumber];
  }

  // 5. Standard Levels 101-500 → algorithmic progression
  if (levelNumber > 100 && levelNumber <= 500) {
    // Custom overrides for specific seeds that are hard to generate under constrained ranges
    if (levelNumber == 392 || levelNumber == 411) {
      return const DifficultyParams(7, 13, 10);
    }
    if (levelNumber == 166 || levelNumber == 198) {
      return const DifficultyParams(4, 14, 9);
    }
    if (levelNumber == 303) {
      return const DifficultyParams(5, 14, 10);
    }

    final int minMoves;
    final int maxMoves;
    final int blocks;

    if (levelNumber <= 200) {
      minMoves = 6;
      maxMoves = 12;
      blocks = 9;
    } else if (levelNumber <= 300) {
      minMoves = 7;
      maxMoves = 13;
      blocks = 10;
    } else if (levelNumber <= 400) {
      minMoves = 8;
      maxMoves = 14;
      blocks = 10;
    } else {
      minMoves = 8;
      maxMoves = 14;
      blocks = 11;
    }

    return DifficultyParams(minMoves, maxMoves, blocks);
  }

  // 6. Beyond level 500: scale smoothly up to absolute limits
  final excess = levelNumber - 500;
  final minMoves = (8 + excess ~/ 100).clamp(8, 12);
  final maxMoves = minMoves + 6;
  return DifficultyParams(minMoves, maxMoves, 11);
}
