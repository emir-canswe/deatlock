/// Generates shareable result card text for Daily mode (without leaking the solution layout).
String generateShareCard({
  required int dailyNumber,
  required int moves,
  required int optimal,
  required String gameUrl,
  bool isEnglish = false,
}) {
  final buffer = StringBuffer();
  buffer.writeln('Redbound #$dailyNumber');
  
  if (isEnglish) {
    buffer.writeln('$moves moves (optimal $optimal)');
  } else {
    buffer.writeln('$moves hamle (optimal $optimal)');
  }

  if (moves <= optimal) {
    buffer.writeln('🟩' * moves);
    buffer.writeln(isEnglish ? 'Optimal ✓' : 'Optimal ✓');
  } else {
    final yellowCount = (moves - optimal).clamp(0, 20);
    buffer.writeln('🟩' * optimal + '🟨' * yellowCount + (moves - optimal > 20 ? '...' : ''));
  }

  buffer.write(gameUrl);
  return buffer.toString();
}
