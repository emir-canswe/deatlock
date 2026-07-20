import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../domain/board_meta.dart';
import '../domain/board_state.dart';
import '../domain/move.dart';

/// Game controller updated for DEADLOCK v3.
/// Coordinates the active board state, moves tracking, undo actions, and hints count.
class GameController extends ChangeNotifier {
  final BoardMeta meta;
  final int optimalMoves;
  
  late BoardState _boardState;
  final List<Move> _undoStack = [];
  bool _won = false;
  bool _hintUsed = false;

  GameController({
    required this.meta,
    required Uint8List initialPositions,
    required this.optimalMoves,
  }) {
    _boardState = BoardState.fromList(initialPositions);
  }

  BoardState get boardState => _boardState;
  int get moveCount => _undoStack.length;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get won => _won;
  bool get hintUsed => _hintUsed;
  
  bool get isPerfect => _won && !_hintUsed && moveCount <= optimalMoves;

  void markHintUsed() {
    _hintUsed = true;
    notifyListeners();
  }

  void applyMove(Move move) {
    if (_won) return;
    
    final nextState = BoardState.fromList(_boardState);
    nextState[move.pieceIndex] += move.delta;
    _boardState = nextState;
    _undoStack.add(move);
    
    if (_boardState.isSolved(meta)) {
      _won = true;
    }
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty || _won) return;
    final lastMove = _undoStack.removeLast();
    
    final nextState = BoardState.fromList(_boardState);
    nextState[lastMove.pieceIndex] -= lastMove.delta;
    _boardState = nextState;
    
    notifyListeners();
  }

  void reset() {
    final currentPos = Uint8List.fromList(_boardState);
    for (int i = _undoStack.length - 1; i >= 0; i--) {
      final m = _undoStack[i];
      currentPos[m.pieceIndex] -= m.delta;
    }
    _boardState = BoardState.fromList(currentPos);
    _undoStack.clear();
    _won = false;
    _hintUsed = false;
    notifyListeners();
  }

  int pieceAt(int row, int col) {
    final map = _boardState.getOccupancyMap(meta);
    final val = map[row * 6 + col];
    return val == 0 ? -1 : val - 1;
  }

  /// Calculate the valid slide range (minDelta, maxDelta) along the piece's sliding axis.
  (int, int) slideRange(int pieceIndex) {
    final pos = _boardState[pieceIndex];
    final length = meta.len[pieceIndex];
    final isHoriz = meta.horiz[pieceIndex] == 1;
    final fixed = meta.fixed[pieceIndex];
    final map = _boardState.getOccupancyMap(meta);

    int minDelta = 0;
    int maxDelta = 0;

    if (isHoriz) {
      // Check left
      int d = -1;
      while (pos + d >= 0) {
        final idx = fixed * 6 + (pos + d);
        if (map[idx] != 0 && map[idx] != pieceIndex + 1) break;
        minDelta = d;
        d--;
      }
      // Check right
      d = 1;
      while (pos + length - 1 + d < 6) {
        final idx = fixed * 6 + (pos + length - 1 + d);
        if (map[idx] != 0 && map[idx] != pieceIndex + 1) break;
        maxDelta = d;
        d++;
      }
      // Target piece can slide fully off the board (to col 6) to trigger win
      if (pieceIndex == meta.targetIndex && pos + length - 1 + maxDelta == 5) {
        maxDelta += 1;
      }
    } else {
      // Check up
      int d = -1;
      while (pos + d >= 0) {
        final idx = (pos + d) * 6 + fixed;
        if (map[idx] != 0 && map[idx] != pieceIndex + 1) break;
        minDelta = d;
        d--;
      }
      // Check down
      d = 1;
      while (pos + length - 1 + d < 6) {
        final idx = (pos + length - 1 + d) * 6 + fixed;
        if (map[idx] != 0 && map[idx] != pieceIndex + 1) break;
        maxDelta = d;
        d++;
      }
    }

    return (minDelta, maxDelta);
  }
}
