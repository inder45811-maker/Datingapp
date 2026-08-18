import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../premium/screens/paywall_sheet.dart';

class PrivateAlbumScreen extends ConsumerWidget {
  const PrivateAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Vault'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not loaded'));
          }

          if (!profile.isPremium) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Private Vault is an Orbit Plus feature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Encrypted private photo albums are only visible to matches you explicitly grant access to. Upgrade to unlock.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PaywallSheet(),
                      ),
                      child: const Text('Upgrade to Orbit Plus'),
                    ),
                  ],
                ),
              ),
            );
          }

          final privatePhotos = profile.privatePhotos;
          if (privatePhotos.isEmpty) {
            return const Center(
              child: Text(
                'No private photos yet.\nUpload via profile settings (moderated server-side).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: privatePhotos.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: privatePhotos[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.white10),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
