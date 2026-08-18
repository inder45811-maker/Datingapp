import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/apple_auth_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/deck/screens/swipe_deck_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Parallel Services Initialization
  await Future.wait([
    Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    ),
    MobileAds.instance.initialize(),
    Purchases.configure(PurchasesConfiguration(AppConstants.revenueCatAppleApiKey)),
  ]);

  runApp(const ProviderScope(child: OrbitRoot()));
}

class OrbitRoot extends ConsumerWidget {
  const OrbitRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) {
            return const AppleAuthScreen();
          }

          // Profile completeness check
          return FutureBuilder(
            future: _isProfileComplete(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF09090F),
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final complete = profileSnapshot.data ?? false;
              if (complete) {
                return const SwipeDeckScreen();
              }
              return const OnboardingScreen();
            },
          );
        },
      ),
    );
  }

  Future<bool> _isProfileComplete() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('birthdate, photos, display_name')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) return false;

      // Consider the profile incomplete if it still has the placeholder birthdate
      // or the default placeholder photo only.
      final birthdate = row['birthdate'] as String?;
      final photos = (row['photos'] as List?)?.cast<String>() ?? [];
      final name = row['display_name'] as String? ?? '';

      if (birthdate == null || birthdate.startsWith('1995-01-01')) return false;
      if (photos.isEmpty || photos.first.contains('placehold.co')) return false;
      if (name.length < 2) return false;

      return true;
    } catch (_) {
      return false;
    }
  }
}
