// Fix the 3 failed levels (166, 198, 303) with wider difficulty bands,
// then produce a complete 500-level sorted seed table.
// Run with: dart run scripts/fix_and_sort.dart

import 'dart:typed_data';
import '../lib/domain/solver.dart';
import '../lib/domain/board_meta.dart';
import '../lib/domain/board_state.dart';
import '../lib/core/prng.dart';

class LevelResult {
  final int originalLevel;
  final int optimalMoves;
  final int blocks;
  LevelResult(this.originalLevel, this.optimalMoves, this.blocks);
}

// Wider difficulty params for failed levels
Map<int, List<int>> widerParams = {
  166: [4, 14, 9],  // minMoves, maxMoves, blocks
  198: [4, 14, 9],
  303: [5, 14, 10],
};

// Standard difficulty (matches difficulty.dart)
List<int> getStandardDiff(int level) {
  if (level >= 1 && level <= 100) {
    return _getTableDiff(level);
  }
  if (level == 392 || level == 411) return [7, 13, 10];
  if (level <= 200) return [6, 12, 9];
  if (level <= 300) return [7, 13, 10];
  if (level <= 400) return [8, 14, 10];
  return [8, 14, 11];
}

List<int> _getTableDiff(int level) {
  // Simplified table for the first 100 levels
  final table = <List<int>>[
    [2, 2, 8],    // 0 sentinel
    [2, 2, 8],    // 1
    [2, 4, 8], [2, 4, 8], [2, 4, 8],    // 2-4
    [3, 5, 8], [3, 5, 8], [3, 5, 8], [3, 5, 8], [3, 5, 8], [3, 5, 8],    // 5-10
    [4, 6, 8], [4, 6, 8], [4, 6, 8], [4, 6, 8], [4, 6, 8], [4, 6, 8],    // 11-16
    [5, 7, 9], [5, 7, 9], [5, 7, 9], [5, 7, 9], [5, 7, 9], [5, 7, 9],    // 17-22
    [6, 8, 9], [6, 8, 9], [6, 8, 9], [6, 8, 9], [6, 8, 9], [6, 8, 9],    // 23-28
    [7, 9, 9], [7, 9, 9], [7, 9, 9], [7, 9, 9],    // 29-32
    [7, 10, 10], [7, 9, 9],    // 33-34
    [7, 10, 9], [7, 10, 9],    // 35-36
    [8, 10, 10], [8, 10, 10], [8, 10, 10], [8, 10, 10],    // 37-40
    [8, 11, 10], [8, 11, 10], [8, 11, 10], [8, 11, 10],    // 41-44
    [9, 13, 10], [9, 11, 11], [9, 11, 10], [9, 14, 9], [9, 11, 10],    // 45-49
    [9, 11, 10], [9, 11, 11], [9, 11, 11],    // 50-52
    [10, 12, 11], [10, 12, 11], [10, 12, 11], [10, 12, 11],    // 53-56
    [10, 12, 11], [10, 12, 11], [10, 12, 11], [10, 12, 11],    // 57-60
    [8, 10, 9], [10, 12, 11],    // 61-62
    [8, 10, 11], [10, 13, 11], [10, 13, 11], [10, 13, 11], [10, 13, 11],    // 63-67
    [10, 13, 12], [10, 13, 12], [10, 13, 12],    // 68-70
    [11, 13, 12], [11, 13, 12], [11, 13, 12], [11, 13, 12], [11, 13, 12], [11, 13, 12],    // 71-76
    [11, 14, 12], [11, 14, 12], [11, 14, 12],    // 77-79
    [10, 14, 10],    // 80
    [11, 14, 12], [11, 14, 12],    // 81-82
    [8, 10, 11],    // 83
    [11, 14, 12], [11, 14, 12], [11, 14, 12], [11, 14, 12],    // 84-87
    [9, 12, 9],    // 88
    [11, 14, 12], [11, 14, 12], [11, 14, 12], [11, 14, 12], [11, 14, 12], [11, 14, 12],    // 89-94
    [8, 10, 9],    // 95
    [11, 14, 12],    // 96
    [8, 10, 9],    // 97
    [11, 14, 12], [11, 14, 12], [11, 14, 12],    // 98-100
  ];
  return table[level];
}

void main() {
  final results = <LevelResult>[];

  for (int level = 1; level <= 500; level++) {
    List<int> diff;
    if (widerParams.containsKey(level)) {
      diff = widerParams[level]!;
    } else {
      diff = getStandardDiff(level);
    }
    
    final result = generateAndSolve(level, diff[0], diff[1], diff[2]);
    if (result != null) {
      results.add(LevelResult(level, result, diff[2]));
    } else {
      print('// STILL FAILED: Level $level');
    }
  }

  // Sort by optimalMoves ascending, ties broken by blocks ascending then originalLevel
  results.sort((a, b) {
    final cmp = a.optimalMoves.compareTo(b.optimalMoves);
    if (cmp != 0) return cmp;
    final cmp2 = a.blocks.compareTo(b.blocks);
    if (cmp2 != 0) return cmp2;
    return a.originalLevel.compareTo(b.originalLevel);
  });

  // Output as a clean Dart const list
  print('/// Pre-computed level ordering for monotonic difficulty.');
  print('/// Index 0 = level 1, index 499 = level 500.');
  print('/// Each value is the original seed-level that should be played at that position.');
  print('/// Sorted by optimal moves ascending. 0 regressions guaranteed.');
  print('const List<int> sortedLevelSeeds = [');
  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    print('  ${r.originalLevel}, // pos ${i + 1}: ${r.optimalMoves} moves, ${r.blocks} blocks');
  }
  print('];');

  // Stats
  print('');
  print('// Total levels: ${results.length}');
  print('// Move range: ${results.first.optimalMoves} - ${results.last.optimalMoves}');

  int regressions = 0;
  for (int i = 1; i < results.length; i++) {
    if (results[i].optimalMoves < results[i - 1].optimalMoves) {
      regressions++;
    }
  }
  print('// Regressions: $regressions');
}

int? generateAndSolve(int level, int minMoves, int maxMoves, int blocks) {
  int attempt = 0;

  while (attempt < 500) {
    final effectiveLevel = level == 446 ? 447 : level;
    final seed = effectiveLevel * 7919 + attempt * 104729 + 12345;
    final prng = Xorshift32(seed);

    final lens = <int>[];
    final horizs = <int>[];
    final fixeds = <int>[];
    final positions = <int>[];

    lens.add(2);
    horizs.add(1);
    fixeds.add(2);
    positions.add(prng.nextInt(4));

    bool overlaps(int lenNew, int horizNew, int fixedNew, int posNew) {
      for (int i = 0; i < lens.length; i++) {
        for (int k1 = 0; k1 < lenNew; k1++) {
          final rNew = horizNew == 1 ? fixedNew : posNew + k1;
          final cNew = horizNew == 1 ? posNew + k1 : fixedNew;
          for (int k2 = 0; k2 < lens[i]; k2++) {
            final rOld = horizs[i] == 1 ? fixeds[i] : positions[i] + k2;
            final cOld = horizs[i] == 1 ? positions[i] + k2 : fixeds[i];
            if (rNew == rOld && cNew == cOld) return true;
          }
        }
      }
      return false;
    }

    int placementAttempts = 0;
    while (lens.length < blocks && placementAttempts < 120) {
      placementAttempts++;
      final isHoriz = prng.nextInt(100) < 45 ? 1 : 0;
      final len = prng.nextInt(100) < 75 ? 2 : 3;
      final maxPos = 6 - len;
      final fixed = prng.nextInt(6);
      final pos = prng.nextInt(maxPos + 1);
      if (isHoriz == 1 && fixed == 2) continue;
      if (isHoriz == 0 && (fixed == 4 || fixed == 5)) {
        if (pos <= 2 && pos + len > 2) continue;
      }
      if (!overlaps(len, isHoriz, fixed, pos)) {
        lens.add(len);
        horizs.add(isHoriz);
        fixeds.add(fixed);
        positions.add(pos);
      }
    }

    if (lens.length == blocks) {
      final meta = BoardMeta(
        len: Uint8List.fromList(lens),
        horiz: Uint8List.fromList(horizs),
        fixed: Uint8List.fromList(fixeds),
        targetIndex: 0,
      );
      final state = BoardState.fromList(positions);
      final solution = solve(meta, state);
      if (solution != null) {
        if (level == 1 && solution.moves == 2) return solution.moves;
        if (level != 1 && solution.moves >= minMoves && solution.moves <= maxMoves) {
          return solution.moves;
        }
      }
    }
    attempt++;
  }
  return null;
}
