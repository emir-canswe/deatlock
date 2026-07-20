class Move {
  final int pieceIndex;
  final int delta;
  const Move(this.pieceIndex, this.delta);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move && pieceIndex == other.pieceIndex && delta == other.delta;

  @override
  int get hashCode => pieceIndex.hashCode ^ delta.hashCode;
}
