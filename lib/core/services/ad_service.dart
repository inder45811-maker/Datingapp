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
    RewardedAd? ad;
    loadRewarded((loadedAd) {
      ad = loadedAd;
      ad!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
        },
      );
      ad!.show(onUserEarnedReward: (ad, reward) {
        onRewardEarned();
      });
    });
  }
}
