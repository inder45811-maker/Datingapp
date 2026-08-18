# Orbit – Production Readiness Checklist

**Last updated**: Prerequisites implementation pass

## Completed in this repository

- [x] Full onboarding flow (`OnboardingScreen`) that collects display name, birthdate (18+ enforced), gender, desires, bio and real location.
- [x] Auth routing: incomplete profiles are forced through onboarding before accessing the deck.
- [x] Service-role `delete-user` edge function that deletes both the public profile (cascades) **and** the `auth.users` record (Apple Guideline 5.1.1).
- [x] Account deletion screen updated to call the edge function and show loading / error states.
- [x] iOS `Info.plist` template with all required usage description strings.
- [x] “Available soon” status fully wired.
- [x] Matches list, swipe engine, and error handling hardened.

## Still required from you (cannot be done without your accounts)

1. **Apple Developer Program** membership ($99/year).
2. Create a real Supabase production project and run the migration.
3. Deploy all four edge functions:
   ```bash
   supabase functions deploy handle-swipe --no-verify-jwt
   supabase functions deploy moderate-image --no-verify-jwt
   supabase functions deploy revenuecat-webhook --no-verify-jwt
   supabase functions deploy delete-user --no-verify-jwt
   ```
4. Replace every placeholder in `lib/core/constants/app_constants.dart`.
5. Configure RevenueCat product ($10.99) + entitlement `orbit_plus`.
6. Create AdMob app + units and register the native ad factory on iOS.
7. Enable Sign in with Apple in both Apple Developer and Supabase Auth.
8. Generate the full Flutter iOS project (`flutter create .` or open in Android Studio / VS Code so the `ios/` folder is complete), then merge the provided `Info.plist` values.
9. Upload a privacy policy and support URL.
10. Create the App Store Connect listing, screenshots, and submit.

## Build commands (run on a Mac)

```bash
cd orbit
flutter pub get
flutter analyze --fatal-infos
flutter build ios --release
# Then archive in Xcode with a valid signing team
```

## Remaining product gaps (non-blocking for first submission but recommended)

- Real photo upload + Sightengine moderation pipeline on the client.
- Per-match private vault grants.
- Events calendar (deferred earlier).
