import 'board_meta.dart';
import 'board_state.dart';
import 'move.dart';
import 'solver.dart';

Move? nextBestMove(BoardMeta meta, BoardState currentPositions) {
  final sol = solve(meta, currentPositions);
  if (sol == null || sol.path.isEmpty) return null;
  return sol.path.first;
}
