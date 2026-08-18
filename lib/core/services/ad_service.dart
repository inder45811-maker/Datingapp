import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

class AdService {
  static void loadRewarded(Function(RewardedAd ad) onLoaded) {
    RewardedAd.load(
      adUnitId: AppConstants.adMobRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (LoadAdError error) {
          // Silently fail; utility boosts are optional
        },
      ),
    );
  }

  static Future<void> showRewardedForSpotlight(VoidCallback onRewardEarned) async {
    loadRewarded((loadedAd) {
      loadedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
        },
      );
      loadedAd.show(onUserEarnedReward: (ad, reward) {
        onRewardEarned();
      });
    });
  }
}
