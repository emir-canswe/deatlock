import 'package:audioplayers/audioplayers.dart';
import '../data/progress_store.dart';

/// Central controller for game audio effects with a multi-channel AudioPool.
/// Prevents sound cutoff during fast block sliding or rapid taps.
class Audio {
  static const int _poolSize = 5;
  static final List<AudioPlayer> _pool = [];
  static int _poolIndex = 0;
  static late final AudioPlayer _winPlayer;
  static bool _enabled = false;
  static bool _initialized = false;

  /// Initialize Audio system with a sound pool and dedicated win channel.
  static void init(ProgressStore store) {
    if (_initialized) {
      _enabled = store.soundEnabled;
      return;
    }

    _enabled = store.soundEnabled;

    // Create pool for short, rapid sound effects (click, slide)
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      player.setPlayerMode(PlayerMode.lowLatency);
      _pool.add(player);
    }

    // Dedicated player for the rich C-Major7 win chord
    _winPlayer = AudioPlayer();

    // Listen to changes to dynamically toggle audio on the fly
    store.addListener(() {
      _enabled = store.soundEnabled;
    });

    _initialized = true;
  }

  static bool get enabled => _enabled;

  static int _lastSlideMillis = 0;

  /// Plays sound on next available channel in the pool.
  static void _playPooled(String assetPath) {
    if (!_enabled || _pool.isEmpty) return;

    try {
      final player = _pool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _poolSize;
      player.play(AssetSource(assetPath));
    } catch (_) {
      // Audio playback fails gracefully if device audio is occupied
    }
  }

  static void playClick() {
    _playPooled('sounds/click.wav');
  }

  static void playSlide() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSlideMillis < 50) return;
    _lastSlideMillis = now;
    _playPooled('sounds/slide.wav');
  }

  static void playWin() {
    if (!_enabled) return;
    try {
      _winPlayer.stop();
      _winPlayer.play(AssetSource('sounds/win.wav'));
    } catch (_) {}
  }

  /// Clean up audio resources.
  static void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
    _pool.clear();
    _winPlayer.dispose();
    _initialized = false;
  }
}
