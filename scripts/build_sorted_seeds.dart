// Generates all 500 levels, sorts by optimal moves, and outputs a seed map.
// Run with: dart run scripts/build_sorted_seeds.dart

import 'dart:typed_data';
import '../lib/domain/difficulty.dart';
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

void main() {
  final results = <LevelResult>[];

  for (int level = 1; level <= 500; level++) {
    final result = generateAndSolve(level);
    if (result != null) {
      final diff = getDifficulty(level);
      results.add(LevelResult(level, result, diff.blocks));
    } else {
      print('// WARNING: Level $level FAILED to generate!');
    }
  }

  // Sort by optimalMoves ascending, then by originalLevel ascending for ties
  results.sort((a, b) {
    final cmp = a.optimalMoves.compareTo(b.optimalMoves);
    if (cmp != 0) return cmp;
    return a.originalLevel.compareTo(b.originalLevel);
  });

  // Output the sorted seed map as a Dart const list
  print('/// Pre-computed sorted level order for monotonic difficulty.');
  print('/// Each entry is the original level seed that should be played at position [index+1].');
  print('/// Sorted by optimal move count (ascending), ties broken by original level number.');
  print('const List<int> sortedLevelSeeds = [');
  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    final comma = i < results.length - 1 ? ',' : ',';
    print('  ${r.originalLevel},$comma // position ${i + 1}: ${r.optimalMoves} moves (blocks: ${r.blocks})');
  }
  print('];');

  // Print stats
  print('');
  print('// Total levels: ${results.length}');
  print('// Move range: ${results.first.optimalMoves} - ${results.last.optimalMoves}');

  // Verify monotonic
  int regressions = 0;
  for (int i = 1; i < results.length; i++) {
    if (results[i].optimalMoves < results[i - 1].optimalMoves) {
      regressions++;
    }
  }
  print('// Regressions after sort: $regressions');
}

int? generateAndSolve(int level) {
  final diff = getDifficulty(level);
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
    while (lens.length < diff.blocks && placementAttempts < 120) {
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

    if (lens.length == diff.blocks) {
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
        if (level != 1 && solution.moves >= diff.minMoves && solution.moves <= diff.maxMoves) {
          return solution.moves;
        }
      }
    }
    attempt++;
  }
  return null;
}
