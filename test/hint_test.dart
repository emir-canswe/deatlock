import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:redbound/domain/board_meta.dart';
import 'package:redbound/domain/board_state.dart';
import 'package:redbound/domain/hint.dart';

void main() {
  test('Next best move v3', () {
    final meta = BoardMeta(
      len: Uint8List.fromList([2, 3]),
      horiz: Uint8List.fromList([1, 0]),
      fixed: Uint8List.fromList([2, 4]),
      targetIndex: 0,
    );
    final positions = BoardState.fromList([0, 0]);
    
    final move = nextBestMove(meta, positions);
    expect(move, isNotNull);
    expect(move!.pieceIndex, 1);
  });
}
