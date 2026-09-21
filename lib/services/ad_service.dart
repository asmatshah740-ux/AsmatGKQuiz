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
  bool _initialized = false;
  Future<bool>? _initializing;

  Future<bool> initialize() {
    if (_initialized) return Future<bool>.value(true);
    final active = _initializing;
    if (active != null) return active;

    final future = _safeInitialize();
    _initializing = future;
    return future.whenComplete(() => _initializing = null);
  }

  Future<bool> _safeInitialize() async {
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  void _loadInterstitial() {
    if (!_initialized || _loadingInterstitial || _interstitial != null) return;
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
    if (!await initialize()) return;

    final ad = _interstitial;
    _interstitial = null;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    await completer.future;
  }

  void _loadRewarded() {
    if (!_initialized || _loadingRewarded || _rewarded != null) return;
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
    if (!await initialize()) return false;

    final ad = _rewarded;
    _rewarded = null;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        _loadRewarded();
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
