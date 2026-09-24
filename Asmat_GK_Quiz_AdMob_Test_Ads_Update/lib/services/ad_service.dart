import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_config.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  Future<InitializationStatus>? _initialization;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  Future<bool> initialize() async {
    try {
      _initialization ??= MobileAds.instance.initialize();
      await _initialization;
      return true;
    } catch (_) {
      _initialization = null;
      return false;
    }
  }

  Future<bool> _ensureInterstitialLoaded() async {
    if (_interstitial != null) return true;
    if (!await initialize()) return false;

    if (_loadingInterstitial) {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (_interstitial != null) return true;
        if (!_loadingInterstitial) break;
      }
      return _interstitial != null;
    }

    _loadingInterstitial = true;
    final completer = Completer<bool>();
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          _interstitial = null;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> showInterstitial() async {
    if (!await _ensureInterstitialLoaded()) return;
    final ad = _interstitial;
    _interstitial = null;
    if (ad == null) return;

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    await completer.future;
  }

  Future<bool> _ensureRewardedLoaded() async {
    if (_rewarded != null) return true;
    if (!await initialize()) return false;

    if (_loadingRewarded) {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (_rewarded != null) return true;
        if (!_loadingRewarded) break;
      }
      return _rewarded != null;
    }

    _loadingRewarded = true;
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          _rewarded = null;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    try {
      return await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> showRewarded() async {
    if (!await _ensureRewardedLoaded()) return false;
    final ad = _rewarded;
    _rewarded = null;
    if (ad == null) return false;

    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
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
