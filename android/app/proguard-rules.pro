# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }

# Google Mobile Ads / AdMob
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.**

# Supabase / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
