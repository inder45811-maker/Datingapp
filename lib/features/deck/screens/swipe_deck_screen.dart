import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/deck_provider.dart';
import '../models/deck_card_item.dart';
import '../widgets/native_ad_card.dart';
import '../widgets/card_gesture_detector.dart';
import '../../safety/widgets/block_report_modal.dart';
import '../../premium/screens/paywall_sheet.dart';
import '../../chat/screens/matches_list_screen.dart';
import '../../auth/providers/auth_provider.dart';

class SwipeDeckScreen extends ConsumerWidget {
  const SwipeDeckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(deckProvider);
    final profileAsync = ref.watch(authNotifierProvider);
    final isAvailableSoon = profileAsync.valueOrNull?.isAvailableSoon ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'O R B I T',
          style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const PaywallSheet(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: isAvailableSoon ? 'Turn off Available soon' : 'Set Available soon (24h)',
            icon: Icon(
              Icons.schedule_rounded,
              color: isAvailableSoon ? const Color(0xFF10B981) : Colors.white70,
            ),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).setAvailableSoon(
                    enabled: !isAvailableSoon,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAvailableSoon
                          ? 'Available soon status cleared'
                          : 'You are now marked Available soon for 24 hours',
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MatchesListScreen()),
            ),
          ),
        ],
      ),
      body: deckState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error fetching feed: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(deckProvider.notifier).loadDeck(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore_off_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'No more profiles in this sector',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.read(deckProvider.notifier).loadDeck(),
                    child: const Text('Refresh Radius'),
                  ),
                ],
              ),
            );
          }

          final topCard = cards.first;

          if (topCard.type == DeckCardType.nativeAd) {
            return NativeAdCard(
              onDismissed: () => ref.read(deckProvider.notifier).dismissAd(topCard.trackingId),
            );
          }

          final user = topCard.profile!;

          return Center(
            child: CardGestureDetector(
              onLike: () async {
                final matchRes = await ref.read(deckProvider.notifier).swipe(user.id, 'like');
                if (matchRes != null && matchRes['isMatch'] == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF8B5CF6),
                      content: Text(
                        '✨ You and ${user.displayName} connected! Direct messages are open.',
                      ),
                    ),
                  );
                }
              },
              onDislike: () {
                ref.read(deckProvider.notifier).swipe(user.id, 'dislike');
              },
              onSuperLike: () async {
                final matchRes = await ref.read(deckProvider.notifier).swipe(user.id, 'superlike');
                if (matchRes != null && matchRes['isMatch'] == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFEC4899),
                      content: Text(
                        '✨ Super connection with ${user.displayName}!',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                height: MediaQuery.of(context).size.height * 0.74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      user.photos.isNotEmpty
                          ? user.photos.first
                          : 'https://placehold.co/600x800.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.95),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${user.displayName}, ${user.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.shield_outlined, color: Colors.white60),
                            onPressed: () => showUGCSafetySheet(context, user.id),
                          ),
                        ],
                      ),
                      if (user.isCoupled) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Coupled with ${user.partnerName ?? 'Partner'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (user.isAvailableSoon) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Available soon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: user.desires
                            .map(
                              (desire) => Chip(
                                label: Text(desire, style: const TextStyle(fontSize: 11)),
                                backgroundColor: Colors.white10,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(user.distanceMeters / 1000).toStringAsFixed(1)} km away',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
