/// Web implementation. There is no ad network on the web build, so the
/// interstitial never shows and the rewarded "ad" is granted straight away.
class AdsImpl {
  static const int gamesPerInterstitial = 4;

  static bool get privacyOptionsRequired => false;

  static Future<void> init() async {}

  static Future<void> showPrivacyOptions() async {}

  static void registerGameCompleted() {}

  static Future<void> showInterstitialIfDue() async {}

  static Future<bool> showRewarded() async => true;
}
