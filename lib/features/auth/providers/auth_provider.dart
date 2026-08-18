import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../../../core/services/supabase_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final response = await SupabaseService.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return UserProfile.fromJson(response);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (response == null) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.data(UserProfile.fromJson(response));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _loadProfile();

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    await SupabaseService.client.from('profiles').update(updates).eq('id', user.id);
    await _loadProfile();
  }

  /// Toggle "Available soon / Meet today" status for the next 24 hours.
  Future<void> setAvailableSoon({bool enabled = true, Duration duration = const Duration(hours: 24)}) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'is_available_soon': enabled,
      'available_until': enabled ? DateTime.now().add(duration).toUtc().toIso8601String() : null,
    };

    await SupabaseService.client.from('profiles').update(updates).eq('id', user.id);
    await _loadProfile();
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  return AuthNotifier();
});
