# Orbit

Native Flutter app for iOS and Android. One repository, one Dart codebase, two store listings.

**This is not a web app.** Preview/build happens via Flutter + Codemagic.

## Platforms

| Platform | Package / bundle | Auth | Payments | Ads |
| --- | --- | --- | --- | --- |
| iOS | `com.orbit.app` | Sign in with Apple + Google | RevenueCat / StoreKit 2 | AdMob native + rewarded |
| Android | `com.orbit.app` | Sign in with Google + Apple | RevenueCat / Play Billing | AdMob native + rewarded |

Shared features: free swipe / match / chat, couple linking, private vaults, Available soon, Orbit Plus at $10.99, account purge.

## First-time setup on a machine with Flutter

```bash
git clone https://github.com/inder45811-maker/Datingapp.git
cd Datingapp
flutter pub get
```

If Flutter complains about missing generated files:

```bash
flutter create . --org com.orbit --project-name orbit --platforms=android,ios
```

That command is additive. It will not wipe the custom Android/iOS files already in this repo (AdMob factories, permissions, Info.plist, Gradle config).

Then:

```bash
# Android (Windows is fine)
flutter build appbundle --release

# iOS (macOS or Codemagic)
flutter build ipa --release
```

## Replace these placeholders

`lib/core/constants/app_constants.dart`

- Supabase URL + anon key
- RevenueCat Apple key (`appl_…`) and Google key (`goog_…`)
- Google Web client ID (required for Google Sign-In on Android)
- Production AdMob unit IDs (test IDs are already wired per platform)

Also replace the test AdMob **app** IDs:

- Android: `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
- iOS: `ios/Runner/Info.plist` → `GADApplicationIdentifier`

## Codemagic (recommended from Windows)

This repo includes `codemagic.yaml` with two workflows:

- `ios-release` — builds IPA, uploads to TestFlight
- `android-release` — builds AAB, uploads to Play internal track

In Codemagic:

1. Connect the GitHub repo
2. Add variable group `appstore_credentials` (App Store Connect API key)
3. Add variable group `google_play_credentials` (Play service account JSON + keystore env vars: `CM_KEYSTORE`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_PASSWORD`, `CM_KEY_ALIAS`)
4. Run each workflow

## Backend

```bash
supabase db push
supabase functions deploy handle-swipe --no-verify-jwt
supabase functions deploy moderate-image --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
supabase functions deploy delete-user --no-verify-jwt
```

See `PRODUCTION_READINESS.md` for the full store-submission checklist.
