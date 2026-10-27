import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fatablock/domain/board_meta.dart';
import 'package:fatablock/domain/board_state.dart';
import 'package:fatablock/domain/solver.dart';

void main() {
  test('Simple 2-move puzzle v3', () {
    final meta = BoardMeta(
      len: Uint8List.fromList([2, 3]),
      horiz: Uint8List.fromList([1, 0]),
      fixed: Uint8List.fromList([2, 4]),
      targetIndex: 0,
    );
    final positions = BoardState.fromList([0, 0]); // Target col 0, blocker row 0
    
    final solution = solve(meta, positions);
    expect(solution, isNotNull);
    expect(solution!.moves, 2);
  });
}
