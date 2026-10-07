import 'package:flutter/foundation.dart';
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
    // NOTE: PlayerMode.lowLatency uses Android's SoundPool, which does not
    // reliably replay a pre-loaded source here (no playback was registered by
    // the system at all). The default media-player mode supports
    // setSource + seek + resume properly, so we keep the asset loaded once and
    // simply rewind it — still no per-tap reloading.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset));
    return player;
  }

  static Future<void> _warmUp() async {
    // Each player is prepared independently so one failure cannot silence the
    // whole game.
    for (int i = 0; i < 3; i++) {
      final p = await _tryCreate(_clickAsset);
      if (p != null) _clickPool.add(p);
    }
    for (int i = 0; i < 4; i++) {
      final p = await _tryCreate(_slideAsset);
      if (p != null) _slidePool.add(p);
    }
    // The win jingle is long, so it uses the normal (non low-latency) mode.
    _winPlayer = await _tryCreate(_winAsset, lowLatency: false);

    _ready = _clickPool.isNotEmpty || _slidePool.isNotEmpty || _winPlayer != null;
  }

  static Future<AudioPlayer?> _tryCreate(
    String asset, {
    bool lowLatency = true,
  }) async {
    try {
      return await _createPlayer(asset, lowLatency: lowLatency);
    } catch (e) {
      debugPrint('[Audio] could not prepare $asset: $e');
      return null;
    }
  }

  /// Replay an already-loaded player from the start. Never throws.
  ///
  /// `seek` is not supported by Android's SoundPool backend used for
  /// low-latency playback, so a failure there must NOT prevent `resume` from
  /// running — otherwise no sound is heard at all.
  static Future<void> _restart(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
    } catch (_) {
      // Some backends do not support seeking; resume() still restarts it.
    }
    try {
      await player.resume();
    } catch (e) {
      // A busy/limited audio device must never break gameplay.
      debugPrint('[Audio] resume failed: $e');
    }
  }

  static void _playFrom(List<AudioPlayer> pool, int Function() next) {
    if (!_enabled || pool.isEmpty) return;
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
