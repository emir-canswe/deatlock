import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Native (Android/iOS) AdMob implementation.
///
/// The defaults below are Google's public TEST ad units. Pass your real ones
/// at build time, e.g.
/// `--dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/yyy`.
class AdsImpl {
  static const int gamesPerInterstitial = 4;

  static const _interstitialAndroid = String.fromEnvironment(
      'ADMOB_INTERSTITIAL_ANDROID',
      defaultValue: 'ca-app-pub-3940256099942544/1033173712');
  static const _interstitialIos = String.fromEnvironment(
      'ADMOB_INTERSTITIAL_IOS',
      defaultValue: 'ca-app-pub-3940256099942544/4411468910');
  static const _rewardedAndroid = String.fromEnvironment(
      'ADMOB_REWARDED_ANDROID',
      defaultValue: 'ca-app-pub-3940256099942544/5224354917');
  static const _rewardedIos = String.fromEnvironment('ADMOB_REWARDED_IOS',
      defaultValue: 'ca-app-pub-3940256099942544/1712485313');

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  static bool _ready = false;
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static bool _loadingInterstitial = false;
  static bool _loadingRewarded = false;
  static int _gamesFinished = 0;
  static bool _interstitialDue = false;

  static bool _privacyOptionsRequired = false;
  static bool get privacyOptionsRequired => _privacyOptionsRequired;

  static Future<void> init() async {
    if (!_supported) return;
    try {
      // GDPR/UK consent (Google UMP). Ads must not be requested before this
      // says we can; outside regulated regions the form is simply skipped.
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('Ads init failed: $e');
    }
  }

  static Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        debugPrint('Consent info update failed: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    _privacyOptionsRequired =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
  }

  /// Re-opens the consent choices (a Play/GDPR requirement where applicable).
  static Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    // The player may have just granted consent: start ads if not running yet.
    if (!_ready && await ConsentInformation.instance.canRequestAds()) {
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
      _loadRewarded();
    }
  }

  static void registerGameCompleted() {
    if (!_ready) return;
    _gamesFinished++;
    if (_gamesFinished % gamesPerInterstitial == 0) _interstitialDue = true;
  }

  static Future<void> showInterstitialIfDue() async {
    if (!_ready || !_interstitialDue) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return; // Stay due; try again at the next break.
    }
    _interstitialDue = false;
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }

  static Future<bool> showRewarded() async {
    if (!_ready) return false;
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    var earned = false;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }

  static void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _interstitialAndroid : _interstitialIos,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  static void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: Platform.isAndroid ? _rewardedAndroid : _rewardedIos,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('Rewarded failed to load: $error');
        },
      ),
    );
  }
}
