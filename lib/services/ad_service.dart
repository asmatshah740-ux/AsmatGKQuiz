class AdService {
  AdService._();
  static final AdService instance = AdService._();

  Future<bool> initialize() async => false;

  Future<void> showInterstitial() async {
    // Ads are temporarily disabled in this boot-stability build.
  }

  Future<bool> showRewarded() async {
    // Ads are temporarily disabled in this boot-stability build.
    return false;
  }

  void dispose() {}
}
