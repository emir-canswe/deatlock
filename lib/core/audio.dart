import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/progress_store.dart';

/// Game sound effects for FATABLOCK.
///
/// Every effect is decoded once at start-up and afterwards only re-triggered.
///
/// Effects use PlayerMode.lowLatency, i.e. Android's SoundPool. This matters:
/// the default MediaPlayer mode makes synchronous binder calls into the media
/// server (seekTo/start) on every play, and since Flutter merged the platform
/// and UI threads those calls run ON the UI thread. Measured on a Galaxy A24
/// while dragging blocks, that stalled the UI for up to ~120 ms at a time
/// (p99 frame 116 ms with sound, 14 ms with sound off). SoundPool.play returns
/// immediately and mixes on its own native thread.
///
/// Effects must never take audio focus. By default audioplayers requests
/// AUDIOFOCUS_GAIN on every single play, which
///   (a) is a synchronous call into the system server, made on the main thread
///       for every cell of a block drag, and
///   (b) pauses whatever music the player is listening to.
/// So the effects are configured as game "sonification" with no focus at all.
class Audio {
  static const String _click = 'sounds/click.wav';
  static const String _slide = 'sounds/slide.wav';
  static const String _snap = 'sounds/snap.wav';
  static const String _bump = 'sounds/bump.wav';
  static const String _hint = 'sounds/hint.wav';
  static const String _undo = 'sounds/undo.wav';
  static const String _star1 = 'sounds/star1.wav';
  static const String _star2 = 'sounds/star2.wav';
  static const String _star3 = 'sounds/star3.wav';
  static const String _win = 'sounds/win.wav';

  /// Loaded in this order, so the sounds that matter most during play are
  /// ready first.
  static const List<String> _loadOrder = [
    _slide, _snap, _click, _bump, _undo, _hint, _star1, _star2, _star3, _win,
  ];

  /// Effects that can fire again before the previous one has finished (a fast
  /// drag, rapid taps) get two players that alternate; the rest need one.
  static const Set<String> _overlapping = {_click, _slide};

  static final AudioContext _context = AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.none,
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
    ),
    // Ambient mixes with other audio and follows the silent switch.
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static final Map<String, List<AudioPlayer>> _pools = {};
  static final Map<String, int> _next = {};

  static bool _enabled = false;
  static bool _initialized = false;
  static bool _ready = false;

  /// Initialize the audio system and warm up every sound player.
  static void init(ProgressStore store) {
    if (_initialized) {
      _enabled = store.soundEnabled;
      return;
    }
    _enabled = store.soundEnabled;

    // Keep in sync with the settings sound toggle.
    store.addListener(() {
      _enabled = store.soundEnabled;
    });

    _initialized = true;
    _warmUp(); // async: sounds become available shortly after launch
  }

  static bool get enabled => _enabled;

  static Future<AudioPlayer?> _tryCreate(String asset) async {
    try {
      final player = AudioPlayer();
      // The default FramePositionUpdater schedules a frame callback every frame
      // while a player is "playing". SoundPool never reports completion, so the
      // state stays "playing" and the whole app would render at full rate.
      player.positionUpdater = null;
      await player.setPlayerMode(PlayerMode.lowLatency); // before the source
      await player.setAudioContext(_context);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(asset));
      return player;
    } catch (e) {
      debugPrint('[Audio] could not prepare $asset: $e');
      return null;
    }
  }

  static Future<void> _warmUp() async {
    try {
      await AudioPlayer.global.setAudioContext(_context);
    } catch (e) {
      debugPrint('[Audio] could not set the global audio context: $e');
    }

    // Each player is prepared on its own, so one failure cannot silence the
    // whole game.
    for (final asset in _loadOrder) {
      final count = _overlapping.contains(asset) ? 2 : 1;
      final players = <AudioPlayer>[];
      for (int i = 0; i < count; i++) {
        final p = await _tryCreate(asset);
        if (p != null) players.add(p);
      }
      if (players.isNotEmpty) _pools[asset] = players;
    }
    _ready = _pools.isNotEmpty;
  }

  /// Trigger an already-loaded sound from the start. Never throws.
  ///
  /// SoundPool never reports that a stream finished, so audioplayers keeps the
  /// player flagged as "playing" and a bare resume() would silently do nothing
  /// the second time. stop() clears that flag (and ends any previous stream),
  /// so resume() always starts a fresh one.
  static Future<void> _restart(AudioPlayer player) async {
    try {
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('[Audio] play failed: $e');
    }
  }

  static void _play(String asset) {
    if (!_enabled || !_ready) return;
    final pool = _pools[asset];
    if (pool == null || pool.isEmpty) return;
    final i = _next[asset] ?? 0;
    _next[asset] = (i + 1) % pool.length;
    _restart(pool[i]);
  }

  static int _lastSlideMillis = 0;

  // ── Public Sound Playback API ─────────────────────────────────────────────

  /// UI tap, button click or switch flip.
  static void playClick() => _play(_click);

  /// Block slide. Throttled so a fast drag cannot flood the player.
  static void playSlide() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSlideMillis < 45) return;
    _lastSlideMillis = now;
    _play(_slide);
  }

  /// Block settles into its slot.
  static void playSnap() => _play(_snap);

  /// A blocked move.
  static void playBump() => _play(_bump);

  /// Soft chime when a hint is shown.
  static void playHint() => _play(_hint);

  /// Falling pair of notes on undo.
  static void playUndo() => _play(_undo);

  /// Star 1, 2 or 3 lighting up.
  static void playStar(int starIndex) {
    switch (starIndex) {
      case 1:
        _play(_star1);
        break;
      case 2:
        _play(_star2);
        break;
      default:
        _play(_star3);
    }
  }

  /// Level complete.
  static void playWin() => _play(_win);

  /// Clean up audio resources.
  static void dispose() {
    for (final pool in _pools.values) {
      for (final player in pool) {
        player.dispose();
      }
    }
    _pools.clear();
    _next.clear();
    _ready = false;
    _initialized = false;
  }
}
