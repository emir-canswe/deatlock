// Script to find the actual achievable move range for problematic seeds
// Run with: dart run scripts/probe_seeds.dart
import 'dart:typed_data';
import '../lib/domain/difficulty.dart';
import '../lib/domain/solver.dart';
import '../lib/domain/board_meta.dart';
import '../lib/domain/board_state.dart';
import '../lib/core/prng.dart';

const problematicLevels = [33, 45, 46, 48, 61, 63, 80, 83, 88, 95, 97];

void main() {
  for (final level in problematicLevels) {
    final result = probeLevel(level);
    print('Level $level → best found: $result');
  }
}

/// Try broad windows to find what this seed CAN actually produce
String probeLevel(int level) {
  for (int targetBlocks in [9, 10, 11, 12]) {
    for (int minM in [8, 9, 10, 11, 12, 13]) {
      for (int maxM in [minM + 1, minM + 2, minM + 3]) {
        final r = tryGenerate(level, minM, maxM, targetBlocks);
        if (r != null) {
          return 'OK blocks=$targetBlocks min=$minM max=$maxM actual=$r';
        }
      }
    }
  }
  return 'IMPOSSIBLE with current seeds';
}

int? tryGenerate(int level, int minM, int maxM, int targetBlocks) {
  int attempt = 0;
  while (attempt < 200) {
    final seed = level * 7919 + attempt * 104729 + 12345;
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

    int pa = 0;
    while (lens.length < targetBlocks && pa < 120) {
      pa++;
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
        lens.add(len); horizs.add(isHoriz);
        fixeds.add(fixed); positions.add(pos);
      }
    }

    if (lens.length == targetBlocks) {
      final meta = BoardMeta(
        len: Uint8List.fromList(lens),
        horiz: Uint8List.fromList(horizs),
        fixed: Uint8List.fromList(fixeds),
        targetIndex: 0,
      );
      final state = BoardState.fromList(positions);
      final solution = solve(meta, state);
      if (solution != null && solution.moves >= minM && solution.moves <= maxM) {
        return solution.moves;
      }
    }
    attempt++;
  }
  return null;
}
