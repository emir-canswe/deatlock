import 'package:flutter_test/flutter_test.dart';
import 'package:redbound/domain/generator.dart';
import 'package:redbound/domain/solver.dart';

void main() {
  test('Generate levels 1-5 deterministically v3', () {
    for (int level = 1; level <= 5; level++) {
      final result1 = generate(level: level);
      final solution = solve(result1.meta, result1.initialPositions);
      expect(solution, isNotNull);
      expect(result1.optimalMoves, greaterThanOrEqualTo(1));
      if (level == 1) {
        expect(result1.optimalMoves, 2);
      }

      final result2 = generate(level: level);
      expect(result1.initialPositions, result2.initialPositions);
      expect(result1.optimalMoves, result2.optimalMoves);
    }
  });
}
