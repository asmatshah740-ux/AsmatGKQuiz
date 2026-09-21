import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_config.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
  }

  void loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    final ad = _interstitial;
    _interstitial = null;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    await completer.future;
  }

  void loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          _rewarded = null;
        },
      ),
    );
  }

  Future<bool> showRewarded() async {
    final ad = _rewarded;
    _rewarded = null;
    if (ad == null) {
      loadRewarded();
      return false;
    }
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
