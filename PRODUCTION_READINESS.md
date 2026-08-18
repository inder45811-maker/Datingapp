# Orbit – Production Readiness Checklist

**Status as of last audit**: Core architecture is coherent. The following items have been hardened or flagged.

## Completed Hardening

- [x] “Available soon” status fully wired (schema, RPC prioritisation, model, UI badge, toggle)
- [x] Matches list provider rewritten to resolve other user profiles safely (no broken dual-FK join)
- [x] Swipe path hardened against ad IDs and network failures (optimistic UI preserved)
- [x] Minimal profile auto-created after Apple Sign-In (prevents null-profile crashes)
- [x] Partial index added for available_soon queries
- [x] Error handling improved in messaging and deck layers
- [x] RLS policies cover insert/update/delete on profiles
- [x] Cascade deletes configured on all core tables

## Required Before App Store Submission

### Credentials & Secrets
- [ ] Replace all placeholders in `lib/core/constants/app_constants.dart`
- [ ] Set Supabase secrets: `SUPABASE_SERVICE_ROLE_KEY`, `SIGHTENGINE_API_USER`, `SIGHTENGINE_API_SECRET`, `RC_WEBHOOK_SECRET`
- [ ] Configure RevenueCat products & entitlement `orbit_plus`
- [ ] Configure AdMob native ad factory (`listTile`) in iOS native code
- [ ] Enable Apple Sign-In capability + configure Supabase Apple provider

### Database
- [ ] Run migration on production Supabase project
- [ ] Verify PostGIS extension and GIST index exist
- [ ] Test `get_nearby_deck` with real coordinates
- [ ] Confirm location insert format works with your PostGIS version (SRID=4326;POINT(...))

### Edge Functions
```bash
supabase functions deploy handle-swipe --no-verify-jwt
supabase functions deploy moderate-image --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

### Flutter / iOS
```bash
flutter pub get
flutter analyze --fatal-infos
flutter test          # add unit tests for providers/models
flutter build ios --no-codesign
```
- [ ] Implement full onboarding (real birthdate, gender, ≥1 real photo, real location)
- [ ] Native AdMob factory registration
- [ ] Info.plist location + camera + photo library usage strings
- [ ] App Tracking Transparency if required
- [ ] Complete account deletion edge function (service-role delete of auth.users)

### Safety & Compliance (Apple 1.2 / 5.1.1)
- [ ] Sightengine credentials live and moderate-image called on every photo upload
- [ ] 1-tap account purge tested end-to-end
- [ ] Block + Report flows verified
- [ ] Age gate (18+) enforced at profile creation

### Known Limitations (intentional for current scope)
- Full multi-partner Constellations not yet implemented
- Events calendar deferred
- Group chat UI exists only as schema flag
- Matches list does N+1 profile lookups (acceptable at low volume; replace with RPC later)
- Placeholder location/photo after first Apple login must be replaced in onboarding

## Verification Commands (run locally)

```bash
# Schema
psql $DATABASE_URL -c "\d profiles"
psql $DATABASE_URL -c "SELECT proname FROM pg_proc WHERE proname = 'get_nearby_deck';"

# Flutter static analysis
flutter analyze --fatal-infos

# Unit tests (once written)
flutter test
```

## Recommended Next Engineering Steps
1. Create a proper onboarding flow that collects real birthdate, gender, photos and location before allowing deck access.
2. Replace the N+1 matches lookup with a single RPC.
3. Add unit tests for `UserProfile.fromRpcJson`, `DeckNotifier.swipe`, and `AuthNotifier.setAvailableSoon`.
4. Implement the full `auth.users` deletion edge function for complete Apple 5.1.1 compliance.
