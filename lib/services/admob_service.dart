import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdMobService {
  // Ad Unit IDs - Update with your actual IDs from AdMob console
  // Middle East targeting এর জন্য region-specific IDs
  
  static const String bannerAdUnitIdAndroid = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy';
  static const String interstitialAdUnitIdAndroid =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy';
  static const String rewardedAdUnitIdAndroid = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy';

  static const String bannerAdUnitIdIOS = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy';
  static const String interstitialAdUnitIdIOS =
      'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy';
  static const String rewardedAdUnitIdIOS = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyy';

  // Test Ad Unit IDs (Google's official test IDs)
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static bool useTestAds = true; // ഡെവലപ്‍മെന്റ് സമയത്ത് true, പ്രൊഡെഖൻ false

  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;

  bool isBannerAdReady = false;
  bool isInterstitialAdReady = false;
  bool isRewardedAdReady = false;

  /// ബാനർ ബിജ്ഞാപനം ലോഡ് ചെയ്യുക (ഏത് സ്ക്രീനിൽ വേണ്ടത് വേണ്ട സ്ഥാനത്ത് കാണിക്കാം)
  void loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: useTestAds ? testBannerAdUnitId : bannerAdUnitIdAndroid,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
          isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: ${error.message}');
          ad.dispose();
          isBannerAdReady = false;
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
        onAdClicked: (ad) {
          print('Banner ad clicked');
        },
        onAdImpression: (ad) {
          print('Banner ad impression');
        },
      ),
    );

    bannerAd!.load();
  }

  /// ഇന്റേർസ്റ്റി‌ഷ്യൽ ബിജ്ഞാപനം ലോഡ് ചെയ്യുക (ചാനൽ മാറ്റുമ്പോൾ കാണിക്കാം)
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: useTestAds ? testInterstitialAdUnitId : interstitialAdUnitIdAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded');
          interstitialAd = ad;
          isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: ${error.message}');
          isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// ഇന്റേർസ്റ്റി‌ഷ്യൽ ബിജ്ഞാപനം കാണിക്കുക
  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (isInterstitialAdReady && interstitialAd != null) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad shown');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial ad dismissed');
          ad.dispose();
          interstitialAd = null;
          onAdClosed?.call();
          // അടുത്ത വിനോദാർത്ഥ കാണിക്കാൻ ലോഡ് ചെയ്യുക
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Failed to show interstitial ${error.message}');
          ad.dispose();
          interstitialAd = null;
        },
      );

      interstitialAd!.show();
    }
  }

  /// പുരസ്കൃത ബിജ്ഞാപനം ലോഡ് ചെയ്യുക (ഉദാ: ആഡ്‍വാൻസ് ഓപ്ഷനുകൾക്കായി)
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: useTestAds ? testRewardedAdUnitId : rewardedAdUnitIdAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('Rewarded ad loaded');
          rewardedAd = ad;
          isRewardedAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Rewarded ad failed to load: ${error.message}');
          isRewardedAdReady = false;
        },
      ),
    );
  }

  /// പുരസ്കൃത ബിജ്ഞാപനം കാണിക്കുക
  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
  }) {
    if (isRewardedAdReady && rewardedAd != null) {
      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Rewarded ad shown');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Rewarded ad dismissed');
          ad.dispose();
          rewardedAd = null;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Failed to show rewarded ad: ${error.message}');
          ad.dispose();
          rewardedAd = null;
        },
      );

      rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
    }
  }

  /// ബാനർ ബിജ്ഞാപനം വിഡ്‍ജെറ്റ് ആയി നിർമ്മിക്കുക (UI-യിൽ കൂട്ടാൻ)
  Widget getBannerAdWidget() {
    if (isBannerAdReady && bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: bannerAd!.size.width.toDouble(),
        height: bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  /// ആൾ നെറ്റ്‍വർക്ക് കണ്ടീഷൻ പരിശോധിച്ച് നെറ്റ്‍വർക്ക്-സ്പെസിഫിക് ബിജ്ഞാപനം കാണിക്കുക
  Future<void> loadContextualAds(String context) async {
    // context: 'channel_switch', 'article_view', 'dubbing_complete', etc.

    switch (context) {
      case 'channel_switch':
        loadInterstitialAd();
        break;
      case 'article_view':
        loadBannerAd();
        break;
      case 'dubbing_complete':
        loadRewardedAd();
        break;
      default:
        loadBannerAd();
    }
  }

  /// സപ്പ്രെസ് ബാനർ ബിജ്ഞാപനം (വിശ്രമ സ്ക്രീനിൽ)
  void disposeBannerAd() {
    bannerAd?.dispose();
    bannerAd = null;
    isBannerAdReady = false;
  }

  /// സപ്പ്രെസ് ഇന്റേർസ്റ്റി‌ഷ്യൽ ബിജ്ഞാപനം
  void disposeInterstitialAd() {
    interstitialAd?.dispose();
    interstitialAd = null;
    isInterstitialAdReady = false;
  }

  /// സപ്പ്രെസ് പുരസ്കൃത ബിജ്ഞാപനം
  void disposeRewardedAd() {
    rewardedAd?.dispose();
    rewardedAd = null;
    isRewardedAdReady = false;
  }

  /// എല്ലാ ബിജ്ഞാപനങ്ങൾ ക്ലീയർ ചെയ്യുക
  void disposeAll() {
    disposeBannerAd();
    disposeInterstitialAd();
    disposeRewardedAd();
  }
}
