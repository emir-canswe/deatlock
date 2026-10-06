import 'dart:typed_data';
import 'board_meta.dart';
import 'board_state.dart';
import 'difficulty.dart';
import 'level_order.dart';
import 'solver.dart';
import '../core/prng.dart';

class GeneratedLevel {
  final BoardMeta meta;
  final BoardState initialPositions;
  final int optimalMoves;
  const GeneratedLevel(this.meta, this.initialPositions, this.optimalMoves);
}

/// A solvable board produced by a single generation attempt, before the
/// move-count bounds have been checked.
typedef _Candidate = ({BoardMeta meta, BoardState state, int moves});

// Loosen the move-count bounds after this many fruitless attempts.
const int _loosenEvery = 1000;
// Past this many total attempts, accept any solvable board that matches the
// block count, ignoring the move-count window.
const int _relaxBoundsAfter = 20000;
// Absolute ceiling so a pathological seed can never spin forever.
const int _hardCap = 200000;

int _resolveSeedLevel(int level) =>
    (level >= 1 && level <= sortedLevelSeeds.length)
        ? sortedLevelSeeds[level - 1]
        : level;

/// Runs one deterministic generation attempt for [seedLevel]/[attempt].
/// Returns a solvable candidate with exactly [blocks] blocks, or null if this
/// attempt failed to place all blocks or produced an unsolvable board.
_Candidate? _attemptGenerate(int seedLevel, int attempt, int blocks) {
  final effectiveLevel = seedLevel == 446 ? 10446 : seedLevel;
  final seed = effectiveLevel * 7919 + attempt * 104729 + 12345;
  final prng = Xorshift32(seed);

  final lens = <int>[];
  final horizs = <int>[];
  final fixeds = <int>[];
  final positions = <int>[];

  // Target block
  lens.add(2);
  horizs.add(1);
  fixeds.add(2); // row 2
  positions.add(prng.nextInt(4)); // col 0-3

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

    if (isHoriz == 1 && fixed == 2) continue; // No other horizontal blocks at row 2
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

  if (lens.length != blocks) return null;

  final meta = BoardMeta(
    len: Uint8List.fromList(lens),
    horiz: Uint8List.fromList(horizs),
    fixed: Uint8List.fromList(fixeds),
    targetIndex: 0,
  );
  final state = BoardState.fromList(positions);

  final solution = solve(meta, state);
  if (solution == null) return null;
  return (meta: meta, state: state, moves: solution.moves);
}

/// Whether a candidate with [moves] optimal moves is acceptable for
/// [seedLevel] under the current bounds. When [relaxed] is true, any solvable
/// board is accepted (used as a safety net on hard-to-generate seeds).
bool _accepts(int seedLevel, int moves, int minMoves, int maxMoves,
    {required bool relaxed}) {
  if (seedLevel == 1) return moves == 2; // exact 2-move tutorial
  if (relaxed) return true;
  return moves >= minMoves && moves <= maxMoves;
}

GeneratedLevel generate({
  required int level,
}) {
  // For standard levels 1-500, remap through the sorted seed table
  // so that difficulty is monotonically non-decreasing.
  final seedLevel = _resolveSeedLevel(level);
  final diff = getDifficulty(seedLevel);

  int minMoves = diff.minMoves;
  int maxMoves = diff.maxMoves;
  final int blocks = diff.blocks;

  int attempt = 0;
  int totalAttempts = 0;
  _Candidate? lastSolvable;

  while (true) {
    if (attempt > _loosenEvery) {
      // Safety release valve: loosen bounds if we are looping too long.
      minMoves = (minMoves - 1).clamp(2, minMoves);
      maxMoves = maxMoves + 1;
      attempt = 0; // reset attempts for loosened parameters
    }

    final relaxed = totalAttempts >= _relaxBoundsAfter;
    final candidate = _attemptGenerate(seedLevel, attempt, blocks);
    if (candidate != null) {
      lastSolvable = candidate;
      if (_accepts(seedLevel, candidate.moves, minMoves, maxMoves,
          relaxed: relaxed)) {
        return GeneratedLevel(candidate.meta, candidate.state, candidate.moves);
      }
    }

    attempt++;
    totalAttempts++;

    // Absolute ceiling: never spin forever. Fall back to the last solvable
    // board we saw (guaranteed to exist well before this point in practice).
    if (totalAttempts >= _hardCap && lastSolvable != null) {
      final c = lastSolvable;
      return GeneratedLevel(c.meta, c.state, c.moves);
    }
  }
}

/// Asynchronous, cooperative version of [generate] for Flutter Web and low-end
/// devices. Periodically yields control back to the event loop so the UI
/// thread maintains 60 FPS without blocking animations, drags, or transitions.
Future<GeneratedLevel> generateAsync({
  required int level,
  int yieldInterval = 8,
}) async {
  final seedLevel = _resolveSeedLevel(level);
  final diff = getDifficulty(seedLevel);

  int minMoves = diff.minMoves;
  int maxMoves = diff.maxMoves;
  final int blocks = diff.blocks;

  int attempt = 0;
  int totalAttempts = 0;
  _Candidate? lastSolvable;

  while (true) {
    if (attempt > 0 && attempt % yieldInterval == 0) {
      // Yield to the event loop.
      await Future<void>.delayed(Duration.zero);
    }

    if (attempt > _loosenEvery) {
      minMoves = (minMoves - 1).clamp(2, minMoves);
      maxMoves = maxMoves + 1;
      attempt = 0;
    }

    final relaxed = totalAttempts >= _relaxBoundsAfter;
    final candidate = _attemptGenerate(seedLevel, attempt, blocks);
    if (candidate != null) {
      lastSolvable = candidate;
      if (_accepts(seedLevel, candidate.moves, minMoves, maxMoves,
          relaxed: relaxed)) {
        return GeneratedLevel(candidate.meta, candidate.state, candidate.moves);
      }
    }

    attempt++;
    totalAttempts++;

    if (totalAttempts >= _hardCap && lastSolvable != null) {
      final c = lastSolvable;
      return GeneratedLevel(c.meta, c.state, c.moves);
    }
  }
}
