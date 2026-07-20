import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/progress_store.dart';

/// State controller for Sprint (Koşu) mode.
/// Handles a 180s countdown timer, rewards (+8s per solve), and score tracking.
class SprintController extends ChangeNotifier {
  final ProgressStore _store;

  int _timeLeft = 45;
  int _score = 0;
  bool _running = false;
  Timer? _timer;

  SprintController(this._store);

  int get timeLeft => _timeLeft;
  int get score => _score;
  bool get isRunning => _running;
  bool get isTimeCritical => _timeLeft <= 10;
  int get personalBest => _store.sprintBest;

  void start() {
    _timeLeft = 45;
    _score = 0;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (!_running) return;
    if (_timeLeft > 0) {
      _timeLeft--;
      notifyListeners();
    } else {
      stop();
    }
  }

  /// Called when a level in sprint mode is successfully solved.
  /// Adds 6 seconds and increments score.
  void recordWin() {
    if (!_running) return;
    _score++;
    _timeLeft += 6;
    notifyListeners();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _store.setSprintBest(_score);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_running) {
      stop();
    }
    _timer?.cancel();
    super.dispose();
  }
}
