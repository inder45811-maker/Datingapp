import 'dart:io';

class AppConstants {
  static const String supabaseUrl = 'https://YOUR_SUPABASE_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String revenueCatAppleApiKey = 'appl_YOUR_REVENUECAT_API_KEY';
  static const String revenueCatGoogleApiKey = 'goog_YOUR_REVENUECAT_API_KEY';

  /// Google Cloud OAuth 2.0 Web client ID (required by google_sign_in on Android).
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';

  static const String revenueCatEntitlementId = 'orbit_plus';
  static const int adInterleaveFrequency = 10;
  static const double defaultSearchRadiusMeters = 80000.0;

  // Google sample / test units — replace with production IDs before store release.
  static const String _adMobNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const String _adMobNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String _adMobRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const String _adMobRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';

  static String get revenueCatApiKey =>
      Platform.isIOS ? revenueCatAppleApiKey : revenueCatGoogleApiKey;

  static String get adMobNativeAdUnitId =>
      Platform.isIOS ? _adMobNativeIos : _adMobNativeAndroid;

  static String get adMobRewardedAdUnitId =>
      Platform.isIOS ? _adMobRewardedIos : _adMobRewardedAndroid;
}
