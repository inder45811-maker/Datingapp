import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';

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

  Future<void> _ensureMinimalProfile({
    required String userId,
    String? displayName,
  }) async {
    final existing = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) return;

    final name = (displayName ?? 'Orbit User').trim();
    await Supabase.instance.client.from('profiles').insert({
      'id': userId,
      'display_name': name.length >= 2 ? name : 'Orbit User',
      'birthdate': '1995-01-01',
      'gender': 'other',
      'desires': <String>[],
      'location': 'SRID=4326;POINT(-0.1276 51.5072)',
      'photos': <String>['https://placehold.co/600x800.png'],
      'bio': '',
    });
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

      final givenName = credential.givenName ?? 'Orbit';
      final familyName = credential.familyName ?? 'User';
      await _ensureMinimalProfile(
        userId: authResponse.user!.id,
        displayName: '$givenName $familyName'.trim(),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId,
        scopes: const ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Google identity token is null');
      }

      final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      await _ensureMinimalProfile(
        userId: authResponse.user!.id,
        displayName: googleUser.displayName,
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              else ...[
                SignInWithAppleButton(
                  onPressed: _signInWithApple,
                  style: SignInWithAppleButtonStyle.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
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
