import 'package:flutter_test/flutter_test.dart';
import 'package:deadlock/domain/game_mode.dart';

void main() {
  test('Game mode properties v3', () {
    expect(GameMode.levels.allowsHint, isTrue);
    expect(GameMode.levels.allowsUndo, isTrue);
    expect(GameMode.daily.allowsHint, isFalse);
    expect(GameMode.sprint.allowsUndo, isFalse);
    expect(GameMode.zen.allowsHint, isTrue);
  });
}
