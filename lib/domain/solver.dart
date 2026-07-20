import 'board_meta.dart';
import 'board_state.dart';
import 'move.dart';

class Solution {
  final int moves;
  final List<Move> path;
  const Solution(this.moves, this.path);
}

class _Node {
  final BoardState state;
  final Move? move;
  final _Node? parent;
  final int depth;
  _Node(this.state, this.move, this.parent, this.depth);
}

Solution? solve(BoardMeta meta, BoardState start) {
  if (start.isSolved(meta)) return const Solution(0, []);

  var frontier = <_Node>[_Node(start, null, null, 0)];
  final visited = <String>{};
  visited.add(String.fromCharCodes(start));

  while (frontier.isNotEmpty) {
    final nextFrontier = <_Node>[];

    for (final node in frontier) {
      if (node.depth >= 60) continue;

      final currentState = node.state;
      final map = currentState.getOccupancyMap(meta);

      for (int i = 0; i < meta.count; i++) {
        final pos = currentState[i];
        final length = meta.len[i];
        final isHoriz = meta.horiz[i] == 1;
        final fixed = meta.fixed[i];

        int back = 0;
        int fwd = 0;

        if (isHoriz) {
          // Count left empty cells
          int d = -1;
          while (pos + d >= 0) {
            final idx = fixed * 6 + (pos + d);
            if (map[idx] != 0 && map[idx] != i + 1) break;
            back++;
            d--;
          }
          // Count right empty cells
          d = 1;
          while (pos + length - 1 + d < 6) {
            final idx = fixed * 6 + (pos + length - 1 + d);
            if (map[idx] != 0 && map[idx] != i + 1) break;
            fwd++;
            d++;
          }
        } else {
          // Count up empty cells
          int d = -1;
          while (pos + d >= 0) {
            final idx = (pos + d) * 6 + fixed;
            if (map[idx] != 0 && map[idx] != i + 1) break;
            back++;
            d--;
          }
          // Count down empty cells
          d = 1;
          while (pos + length - 1 + d < 6) {
            final idx = (pos + length - 1 + d) * 6 + fixed;
            if (map[idx] != 0 && map[idx] != i + 1) break;
            fwd++;
            d++;
          }
        }

        // Try slides
        for (int d = -back; d <= fwd; d++) {
          if (d == 0) continue;

          final nextState = BoardState.fromList(currentState);
          nextState[i] += d;

          if (nextState.isSolved(meta)) {
            final path = <Move>[Move(i, d)];
            var curr = node;
            while (curr.move != null) {
              path.add(curr.move!);
              curr = curr.parent!;
            }
            return Solution(path.length, path.reversed.toList());
          }

          final key = String.fromCharCodes(nextState);
          if (visited.add(key)) {
            nextFrontier.add(_Node(nextState, Move(i, d), node, node.depth + 1));
          }
        }
      }
    }
    frontier = nextFrontier;
  }
  return null;
}
