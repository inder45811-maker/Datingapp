import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../../../core/services/supabase_service.dart';

final matchesProvider = FutureProvider<List<MatchSummary>>((ref) async {
  final userId = SupabaseService.currentUserId;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('matches')
        .select('id, user1_id, user2_id, created_at')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('created_at', ascending: false);

    final List<MatchSummary> matches = [];

    for (final row in (response as List)) {
      final map = Map<String, dynamic>.from(row as Map);
      final isUser1 = map['user1_id'] == userId;
      final otherId = isUser1 ? map['user2_id'] as String : map['user1_id'] as String;

      // Resolve other profile
      String otherName = 'Connection';
      String? otherPhoto;

      try {
        final other = await SupabaseService.client
            .from('profiles')
            .select('display_name, photos')
            .eq('id', otherId)
            .maybeSingle();

        if (other != null) {
          otherName = other['display_name'] as String? ?? 'Connection';
          final photos = other['photos'] as List?;
          if (photos != null && photos.isNotEmpty) {
            otherPhoto = photos.first as String?;
          }
        }
      } catch (_) {
        // Keep defaults if profile lookup fails
      }

      matches.add(MatchSummary(
        id: map['id'] as String,
        otherUserId: otherId,
        otherDisplayName: otherName,
        otherPhoto: otherPhoto,
        createdAt: DateTime.parse(map['created_at'] as String),
      ));
    }

    return matches;
  } catch (e) {
    // Return empty on error rather than crashing the UI
    return [];
  }
});

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<MessageModel>>, String>(
  (ref, matchId) => MessagesNotifier(matchId),
);

class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final String matchId;
  RealtimeChannel? _channel;

  MessagesNotifier(this.matchId) : super(const AsyncValue.loading()) {
    _loadAndSubscribe();
  }

  Future<void> _loadAndSubscribe() async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select()
          .eq('match_id', matchId)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = AsyncValue.data(messages);

      _channel = SupabaseService.subscribeToMessages(matchId, (record) {
        try {
          final msg = MessageModel.fromJson(record);
          state.whenData((current) {
            if (!current.any((m) => m.id == msg.id)) {
              state = AsyncValue.data([...current, msg]);
            }
          });
        } catch (_) {
          // Ignore malformed realtime payloads
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null || content.trim().isEmpty) return;

    try {
      await SupabaseService.client.from('messages').insert({
        'match_id': matchId,
        'sender_id': userId,
        'content': content.trim(),
      });
    } catch (_) {
      // Caller can surface error if needed; avoid unhandled exception
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
