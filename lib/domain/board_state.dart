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
        map[r * 6 + c] = i + 1;
      }
    }
    return map;
  }
}
