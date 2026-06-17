import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Replace these with your real AdMob unit IDs before release.
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // test
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // test
    }
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
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
