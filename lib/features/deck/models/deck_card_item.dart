import '../../auth/models/user_profile.dart';

enum DeckCardType { profile, nativeAd }

class DeckCardItem {
  final DeckCardType type;
  final UserProfile? profile;
  final String trackingId;

  DeckCardItem.profile(UserProfile user)
      : type = DeckCardType.profile,
        profile = user,
        trackingId = user.id;

  DeckCardItem.ad(this.trackingId)
      : type = DeckCardType.nativeAd,
        profile = null;
}
