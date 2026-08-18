import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AppleAuthScreen extends StatefulWidget {
  const AppleAuthScreen({super.key});

  @override
  State<AppleAuthScreen> createState() => _AppleAuthScreenState();
}

class _AppleAuthScreenState extends State<AppleAuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple identity token is null');
      }

      final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      // Ensure a minimal profile exists after first sign-in so the rest of the
      // app does not crash. A full onboarding flow should later replace these
      // placeholder values with real user data.
      final userId = authResponse.user!.id;
      final existing = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        final givenName = credential.givenName ?? 'Orbit';
        final familyName = credential.familyName ?? 'User';
        final displayName = '$givenName $familyName'.trim();

        // Placeholder location (London) – user must update in onboarding
        // Placeholder photo – must be replaced before public discovery
        // Note: location must be a valid PostGIS geography. Using a safe
        // London placeholder that the user will replace during onboarding.
        await Supabase.instance.client.from('profiles').insert({
          'id': userId,
          'display_name': displayName.length >= 2 ? displayName : 'Orbit User',
          'birthdate': '1995-01-01',
          'gender': 'other',
          'desires': <String>[],
          'location': 'SRID=4326;POINT(-0.1276 51.5072)',
          'photos': <String>['https://placehold.co/600x800.png'],
          'bio': '',
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                'ORBIT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ethical non-monogamy.\nZero paywalls on connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 3),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
              else
                SignInWithAppleButton(
                  onPressed: _signInWithApple,
                  style: SignInWithAppleButtonStyle.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
              const SizedBox(height: 24),
              const Text(
                'By continuing you confirm you are 18+ and agree to our Terms of Service and Community Guidelines.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
