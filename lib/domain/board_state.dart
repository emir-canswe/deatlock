import 'dart:typed_data';
import 'board_meta.dart';

typedef BoardState = Uint8List;

// Helper extensions or static helpers to work with BoardState and BoardMeta
extension BoardStateHelpers on BoardState {
  bool isSolved(BoardMeta meta) {
    final pos = this[meta.targetIndex];
    final length = meta.len[meta.targetIndex];
    return pos + length >= 6;
  }

  Int8List getOccupancyMap(BoardMeta meta) {
    final map = Int8List(36);
    for (int i = 0; i < meta.count; i++) {
      final pos = this[i];
      final length = meta.len[i];
      final isHoriz = meta.horiz[i] == 1;
      final fixed = meta.fixed[i];
      for (int k = 0; k < length; k++) {
        final r = isHoriz ? fixed : pos + k;
        final c = isHoriz ? pos + k : fixed;
        // The target block can slide past the right edge to trigger the win
        // (pos reaching 6/7); skip any cell that lies outside the 6x6 grid so
        // it never writes into an unrelated row.
        if (r < 0 || r >= 6 || c < 0 || c >= 6) continue;
        map[r * 6 + c] = i + 1;
      }
    }
    return map;
  }
}
