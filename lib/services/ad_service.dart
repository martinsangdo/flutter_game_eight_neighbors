import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Replace these with your real AdMob unit IDs before release.
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8762959223087619/3052048635'; // banner Ad Unit ID for Android
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // test
    }
  }

  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8762959223087619/6897929887'; // rewarded Ad Unit ID for Android
    } else {
      return 'ca-app-pub-3940256099942544/1712485313'; // test
    }
  }

  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;

  Future<void> initialize() async {
    if (kIsWeb) return; // google_mobile_ads has no web implementation
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  void loadRewardedAd() {
    if (_rewardedLoading || kIsWeb) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedLoading = false;
        },
      ),
    );
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  void showRewardedAd({required VoidCallback onRewarded, VoidCallback? onFailed}) {
    final ad = _rewardedAd;
    if (ad == null) {
      onFailed?.call();
      loadRewardedAd();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        _rewardedAd = null;
        loadRewardedAd();
        onFailed?.call();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onRewarded());
    _rewardedAd = null;
  }

  BannerAd createBanner({required void Function(Ad, LoadAdError) onFailed}) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: onFailed,
      ),
    );
  }
}
