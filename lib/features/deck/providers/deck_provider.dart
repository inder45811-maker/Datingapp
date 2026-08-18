import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/deck_card_item.dart';
import '../../auth/models/user_profile.dart';
import '../../../core/constants/app_constants.dart';

final deckProvider = StateNotifierProvider<DeckNotifier, AsyncValue<List<DeckCardItem>>>((ref) {
  return DeckNotifier();
});

class DeckNotifier extends StateNotifier<AsyncValue<List<DeckCardItem>>> {
  DeckNotifier() : super(const AsyncValue.loading()) {
    loadDeck();
  }

  int _swipesCount = 0;

  Future<void> loadDeck() async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Unauthorized');

      // Request location permission if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final List<dynamic> response = await Supabase.instance.client.rpc(
        'get_nearby_deck',
        params: {
          'p_user_id': user.id,
          'p_user_lat': pos.latitude,
          'p_user_long': pos.longitude,
          'p_radius_meters': AppConstants.defaultSearchRadiusMeters,
          'p_limit': 40,
        },
      );

      final List<UserProfile> profiles =
          response.map((e) => UserProfile.fromRpcJson(Map<String, dynamic>.from(e as Map))).toList();

      // Inject native ad units every k cards
      final List<DeckCardItem> items = [];
      for (int i = 0; i < profiles.length; i++) {
        items.add(DeckCardItem.profile(profiles[i]));
        if ((i + 1) % AppConstants.adInterleaveFrequency == 0) {
          items.add(DeckCardItem.ad('ad_${i + 1}'));
        }
      }

      state = AsyncValue.data(items);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<Map<String, dynamic>?> swipe(String targetId, String direction) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    // Ads are dismissed locally only
    if (targetId.startsWith('ad_')) {
      dismissAd(targetId);
      return null;
    }

    _swipesCount++;

    // Optimistically pop top item
    state.whenData((items) {
      state = AsyncValue.data(
        items.where((item) => item.trackingId != targetId).toList(),
      );
    });

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'handle-swipe',
        body: {
          'swiper_id': user.id,
          'swiped_id': targetId,
          'direction': direction,
        },
      );

      if (res.status != 200) {
        // On failure we still keep the optimistic removal to avoid stuck cards
        return null;
      }

      return res.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  void dismissAd(String trackingId) {
    state.whenData((items) {
      state = AsyncValue.data(
        items.where((item) => item.trackingId != trackingId).toList(),
      );
    });
  }
}
