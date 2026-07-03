import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // no banner ads on web
    _ad = AdService.instance.createBanner(
      onFailed: (ad, error) {
        ad.dispose();
        if (mounted) setState(() => _loaded = false);
      },
    );
    _ad!.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always reserve the banner height so the game layout doesn't
    // shift when the ad loads (or stays empty when it fails).
    return SafeArea(
      top: false,
      child: SizedBox(
        height: AdSize.banner.height.toDouble(),
        child: (_loaded && _ad != null)
            ? Center(
                child: SizedBox(
                  width: _ad!.size.width.toDouble(),
                  height: _ad!.size.height.toDouble(),
                  child: AdWidget(ad: _ad!),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
