import 'package:audioplayers/audioplayers.dart';
import '../data/progress_store.dart';

/// Central controller for game audio effects.
///
/// Each asset is loaded into its players exactly ONCE at start-up. Playing a
/// sound then only rewinds + resumes an already-loaded player, instead of
/// re-loading the asset on every tap/slide (which leaks native SoundPool /
/// MediaPlayer handles on Android and progressively stalls the app).
class Audio {
  static const String _clickAsset = 'sounds/click.wav';
  static const String _slideAsset = 'sounds/slide.wav';
  static const String _winAsset = 'sounds/win.wav';

  // Small per-sound pools so rapid taps/slides can overlap without cutting off.
  static final List<AudioPlayer> _clickPool = [];
  static final List<AudioPlayer> _slidePool = [];
  static AudioPlayer? _winPlayer;

  static int _clickIndex = 0;
  static int _slideIndex = 0;

  static bool _enabled = false;
  static bool _initialized = false;
  static bool _ready = false;

  /// Initialize the audio system and pre-load every sound effect.
  static void init(ProgressStore store) {
    if (_initialized) {
      _enabled = store.soundEnabled;
      return;
    }
    _enabled = store.soundEnabled;

    // Keep in sync with the settings toggle.
    store.addListener(() {
      _enabled = store.soundEnabled;
    });

    _initialized = true;
    _warmUp(); // async; sounds become available a moment after launch
  }

  static bool get enabled => _enabled;

  static Future<AudioPlayer> _createPlayer(
    String asset, {
    bool lowLatency = true,
  }) async {
    final player = AudioPlayer();
    if (lowLatency) {
      await player.setPlayerMode(PlayerMode.lowLatency);
    }
    // Keep the decoded source alive so it can be replayed without reloading.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset));
    return player;
  }

  static Future<void> _warmUp() async {
    try {
      for (int i = 0; i < 3; i++) {
        _clickPool.add(await _createPlayer(_clickAsset));
      }
      for (int i = 0; i < 4; i++) {
        _slidePool.add(await _createPlayer(_slideAsset));
      }
      // The win jingle is long, so it uses the normal (non low-latency) mode.
      _winPlayer = await _createPlayer(_winAsset, lowLatency: false);
      _ready = true;
    } catch (_) {
      // Device audio unavailable — the game stays fully playable, just silent.
      _ready = false;
    }
  }

  /// Rewind + play an already-loaded player. Fire-and-forget, never throws.
  static Future<void> _restart(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      // Ignore: a busy/limited audio device must never break gameplay.
    }
  }

  static void _playFrom(List<AudioPlayer> pool, int Function() next) {
    if (!_enabled || !_ready || pool.isEmpty) return;
    _restart(pool[next()]);
  }

  static int _lastSlideMillis = 0;

  static void playClick() {
    _playFrom(_clickPool, () {
      final i = _clickIndex;
      _clickIndex = (_clickIndex + 1) % _clickPool.length;
      return i;
    });
  }

  static void playSlide() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSlideMillis < 50) return;
    _lastSlideMillis = now;
    _playFrom(_slidePool, () {
      final i = _slideIndex;
      _slideIndex = (_slideIndex + 1) % _slidePool.length;
      return i;
    });
  }

  static void playWin() {
    final player = _winPlayer;
    if (!_enabled || !_ready || player == null) return;
    _restart(player);
  }

  /// Clean up audio resources.
  static void dispose() {
    for (final player in [..._clickPool, ..._slidePool]) {
      player.dispose();
    }
    _clickPool.clear();
    _slidePool.clear();
    _winPlayer?.dispose();
    _winPlayer = null;
    _ready = false;
    _initialized = false;
  }
}
