import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/apple_auth_screen.dart';
import 'features/deck/screens/swipe_deck_screen.dart';

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

class OrbitRoot extends StatelessWidget {
  const OrbitRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return const SwipeDeckScreen();
          }
          return const AppleAuthScreen();
        },
      ),
    );
  }
}
