# Orbit – Production Readiness Checklist

**Last updated**: Dual-platform (iOS + Android) native Flutter project

## Completed in this repository

- [x] Single Flutter codebase targeting **iOS and Android**
- [x] Full `android/` Gradle project (`com.orbit.app`, minSdk 23, release signing hook, ProGuard)
- [x] Native AdMob factory `listTile` registered on **both** platforms
- [x] Android permissions: location, camera, photos, Ad ID, Play Billing
- [x] iOS Xcode project, Podfile (iOS 13+), Info.plist usage strings, AdMob app id
- [x] Platform-specific RevenueCat + AdMob unit IDs
- [x] Sign in with Apple **and** Google (same screen, both stores)
- [x] Onboarding (18+), delete-user edge function, Available soon
- [x] `codemagic.yaml` workflows for TestFlight and Play internal track

## Still required from you (accounts only)

1. Apple Developer Program + Google Play Console
2. Production Supabase project + migrate + deploy 4 edge functions
3. Replace placeholders in `lib/core/constants/app_constants.dart`
4. Production AdMob app IDs in AndroidManifest + Info.plist
5. RevenueCat products for **both** App Store and Play Store, entitlement `orbit_plus`
6. Google Cloud OAuth clients (iOS, Android SHA-1, Web) + enable Google in Supabase Auth
7. Upload real launcher / App Store / Play icons
8. Privacy policy + support URL
9. Codemagic signing (App Store Connect key + Android keystore)

## Build (Codemagic or a machine with Flutter)

```bash
flutter pub get
flutter analyze --fatal-infos
flutter build appbundle --release   # Android
flutter build ipa --release         # iOS (macOS)
```
