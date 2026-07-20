import 'dart:typed_data';

class BoardMeta {
  final Uint8List len;    // length of each block (2 or 3)
  final Uint8List horiz;  // 1 = horizontal, 0 = vertical
  final Uint8List fixed;  // fixed row (if horiz) or fixed col (if vertical)
  final int targetIndex;  // target block index (always 0)

  const BoardMeta({
    required this.len,
    required this.horiz,
    required this.fixed,
    required this.targetIndex,
  });

  int get count => len.length;
}
