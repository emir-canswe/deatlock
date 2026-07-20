import 'package:audioplayers/audioplayers.dart';
import '../data/progress_store.dart';

/// Central controller for game audio effects.
/// Uses AudioPlayer from audioplayers package and respects user settings.
class Audio {
  static late final AudioPlayer _player;
  static bool _enabled = false;

  /// Initialize Audio system by listening to the ProgressStore sound settings.
  static void init(ProgressStore store) {
    _player = AudioPlayer();
    _enabled = store.soundEnabled;

    // Listen to changes to dynamic toggle audio on the fly
    store.addListener(() {
      _enabled = store.soundEnabled;
    });
  }

  static bool get enabled => _enabled;

  static void playClick() {
    if (_enabled) {
      _player.play(AssetSource('sounds/click.wav'));
    }
  }

  static void playSlide() {
    if (_enabled) {
      _player.play(AssetSource('sounds/slide.wav'));
    }
  }

  static void playWin() {
    if (_enabled) {
      _player.play(AssetSource('sounds/win.wav'));
    }
  }
}
