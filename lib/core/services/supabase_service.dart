import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<Map<String, dynamic>?> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final response = await client.functions.invoke(functionName, body: body);
    return response.data as Map<String, dynamic>?;
  }

  static RealtimeChannel subscribeToMessages(String matchId, void Function(Map<String, dynamic>) onInsert) {
    return client
        .channel('messages:$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
  }
}
