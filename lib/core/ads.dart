// Delegates to a platform-specific implementation chosen at compile time.
// Native builds get the real AdMob code; web builds get a no-op stub because
// google_mobile_ads does not support the web.
import 'ads_io.dart' if (dart.library.js_interop) 'ads_stub.dart';

/// Ad helper: an interstitial after every [AdsImpl.gamesPerInterstitial]
/// finished games, and a rewarded ad that buys one extra hint.
class Ads {
  static Future<void> init() => AdsImpl.init();

  /// True when the player is in a region where they must be able to revisit
  /// their ad-consent choice (EEA/UK). Known once [init] has finished.
  static bool get privacyOptionsRequired => AdsImpl.privacyOptionsRequired;

  static Future<void> showPrivacyOptions() => AdsImpl.showPrivacyOptions();

  /// Call once per finished game (win).
  static void registerGameCompleted() => AdsImpl.registerGameCompleted();

  /// Shows the interstitial if one is due. Call at a natural break, e.g. when
  /// the player moves on to the next game.
  static Future<void> showInterstitialIfDue() => AdsImpl.showInterstitialIfDue();

  /// Shows a rewarded ad. Completes with true only if the reward was earned.
  static Future<bool> showRewarded() => AdsImpl.showRewarded();
}
