import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';
import 'chat_room_screen.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load matches: $err')),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'No mutual connections yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Keep swiping — messaging unlocks on mutual likes.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              final match = matches[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: match.otherPhoto != null
                      ? CachedNetworkImageProvider(match.otherPhoto!)
                      : null,
                  child: match.otherPhoto == null
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                title: Text(
                  match.otherDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Matched ${_formatDate(match.createdAt)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        matchId: match.id,
                        otherUserName: match.otherDisplayName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
