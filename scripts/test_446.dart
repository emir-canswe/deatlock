// Quick test: does seed 446 generate without the 447 remap?
// Run with: dart run scripts/test_446.dart

import 'dart:typed_data';
import '../lib/domain/solver.dart';
import '../lib/domain/board_meta.dart';
import '../lib/domain/board_state.dart';
import '../lib/core/prng.dart';

void main() {
  // Test seed 446 WITHOUT remap (raw seed)
  print('Testing seed 446 (no remap):');
  final r1 = testSeed(446, 8, 14, 11);
  print('  Result: ${r1 ?? "FAILED"}');

  // Test seed 446 with large offset remap
  print('Testing seed 446 (offset 10000):');
  final r2 = testSeedWithOffset(446, 10000, 8, 14, 11);
  print('  Result: ${r2 ?? "FAILED"}');

  // Test seed 447 (original, for comparison)
  print('Testing seed 447 (original):');
  final r3 = testSeed(447, 8, 14, 11);
  print('  Result: ${r3 ?? "FAILED"}');

  // Check they produce different puzzles
  if (r1 != null && r3 != null) {
    print('Seed 446 raw vs 447: ${r1 == r3 ? "SAME (bad)" : "DIFFERENT (good)"}');
  }
}

int? testSeed(int seedLevel, int minMoves, int maxMoves, int blocks) {
  int attempt = 0;
  while (attempt < 500) {
    final seed = seedLevel * 7919 + attempt * 104729 + 12345;
    final result = tryGenerate(seed, minMoves, maxMoves, blocks, seedLevel);
    if (result != null) return result;
    attempt++;
  }
  return null;
}

int? testSeedWithOffset(int seedLevel, int offset, int minMoves, int maxMoves, int blocks) {
  int attempt = 0;
  while (attempt < 500) {
    final seed = (seedLevel + offset) * 7919 + attempt * 104729 + 12345;
    final result = tryGenerate(seed, minMoves, maxMoves, blocks, seedLevel);
    if (result != null) return result;
    attempt++;
  }
  return null;
}

int? tryGenerate(int seed, int minMoves, int maxMoves, int blocks, int seedLevel) {
  final prng = Xorshift32(seed);
  final lens = <int>[];
  final horizs = <int>[];
  final fixeds = <int>[];
  final positions = <int>[];

  lens.add(2); horizs.add(1); fixeds.add(2);
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
      lens.add(len); horizs.add(isHoriz); fixeds.add(fixed); positions.add(pos);
    }
  }

  if (lens.length == blocks) {
    final meta = BoardMeta(
      len: Uint8List.fromList(lens), horiz: Uint8List.fromList(horizs),
      fixed: Uint8List.fromList(fixeds), targetIndex: 0,
    );
    final state = BoardState.fromList(positions);
    final solution = solve(meta, state);
    if (solution != null && solution.moves >= minMoves && solution.moves <= maxMoves) {
      return solution.moves;
    }
  }
  return null;
}
