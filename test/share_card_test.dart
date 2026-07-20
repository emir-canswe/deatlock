import 'package:flutter_test/flutter_test.dart';
import 'package:deadlock/domain/share_card.dart';

void main() {
  test('Share card generates correctly for optimal solution', () {
    final shareStr = generateShareCard(
      dailyNumber: 218,
      moves: 9,
      optimal: 9,
      gameUrl: 'https://emir-canswe.github.io/deadlock/',
    );
    expect(shareStr.contains('Deadlock #218'), isTrue);
    expect(shareStr.contains('9 hamle (optimal 9)'), isTrue);
    expect(shareStr.contains('🟩🟩🟩🟩🟩🟩🟩🟩🟩'), isTrue);
    expect(shareStr.contains('Optimal ✓'), isTrue);
    expect(shareStr.contains('https://emir-canswe.github.io/deadlock/'), isTrue);
  });

  test('Share card generates correctly for over-optimal solution', () {
    final shareStr = generateShareCard(
      dailyNumber: 218,
      moves: 11,
      optimal: 9,
      gameUrl: 'https://emir-canswe.github.io/deadlock/',
    );
    expect(shareStr.contains('Deadlock #218'), isTrue);
    expect(shareStr.contains('11 hamle (optimal 9)'), isTrue);
    expect(shareStr.contains('🟩🟩🟩🟩🟩🟩🟩🟩🟩🟨🟨'), isTrue);
    expect(shareStr.contains('Optimal ✓'), isFalse);
    expect(shareStr.contains('https://emir-canswe.github.io/deadlock/'), isTrue);
  });
}
