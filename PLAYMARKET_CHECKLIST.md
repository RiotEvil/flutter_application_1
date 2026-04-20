# Google Play Market Publish Checklist

## Project: DetailingPro Business Management App

## Market: Poland (Primary), Multi-language support

---

## ✅ COMPLETED - Week 1 (Security & Input Validation)

### 1. Firestore Security Rules Hardening

- [x] User role escalation fixed (cannot modify `role`/`orgId` directly)
- [x] Invite code tampering prevention (only `used`, `usedBy`, `usedAt` changeable)
- [x] Chat room creator must be participant
- [x] Booking requests validation + field whitelist + length limits

### 2. Hive Storage Encryption

- [x] flutter_secure_storage integrated
- [x] AES-256 cipher with OS keystore
- [x] Auto-migration from unencrypted legacy data
- [x] Sensitive boxes encrypted: settings, clients, orders, finance, vehicles

### 3. Input Validation

- [x] Phone number validation (7-15 digits, +/- format allowed)
- [x] Service name required + price >= 0
- [x] L10n keys added to all 9 languages

### 4. Version & Signing

- [x] Updated version to 1.0.0+1 (first Play Market release)
- [x] Keystore configured (key.properties in .gitignore ✓)
- [x] Signing config: release build signs with keystore

---

## ✅ IN-PROGRESS/DONE - Play Market Preparation

### 5. OAuth & Secrets

- [x] Google OAuth Client ID extracted to `lib/core/oauth_config.dart`
- [x] Added TODO comment: for production, fetch from backend
- [x] auth_screen.dart updated to use config
- [x] Removed hardcoded Client ID

### 6. Debug Cleanup

- [x] debugPrint disabled in release mode (kReleaseMode check)
- [x] AndroidManifest.xml verified (CAMERA, POST_NOTIFICATIONS, READ_MEDIA_IMAGES)
- [x] Debug banner already disabled

### 7. Gradle & Minification

- [x] Release build: isMinifyEnabled = true
- [x] Release build: isShrinkResources = true
- [x] proguard-rules.pro created (Firebase, Hive, Google Sign-In rules)
- [x] Java 17 desugaring enabled
- [x] gradle.properties optimized for Windows

### 8. Production Settings

- [x] Application ID: com.detailing.business.app ✓
- [x] Min SDK: depends on flutter.minSdkVersion
- [x] Target SDK: depends on flutter.targetSdkVersion

---

## 📋 TODO - Store Listing & Metadata

### 9. Google Play Console Setup

- [ ] Create app listing in Google Play Console
- [ ] App name: "DetailingPro" or "Detailing Pro Business"
- [ ] Category: Business / Tools
- [ ] Content rating questionnaire
- [ ] Privacy policy URL (finalize legal/legalTermsSummaryTitle)
- [ ] Target audience: Professional/Business users (not children)

### 10. App Listing Content

- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max, include all 9 language translations)
- [ ] Screenshots (2-8 per language, show key features)
- [ ] Feature graphic (1024x500px)
- [ ] App icon (512x512px, already present in assets)

### 11. Pricing & Distribution

- [ ] Pricing strategy: Free / In-app purchases / Paid subscription
- [ ] Market listing countries (at least Poland for PLN market)
- [ ] Release track: Beta (internal testing first) → Production

### 12. Legal & Compliance

- [ ] Privacy policy reviewed and finalized
  - Current: `legalPrivacySectionX` in app_en/pl/.arb
  - Update: Contact email, data retention, compliance
- [ ] Terms of service finalized
  - Current: `legalTermsSectionX` in app_en/pl/.arb
  - Update: Jurisdiction (Poland), business structure, limitations
- [ ] Both policies uploaded to public URLs

### 13. App Signing

- [ ] Generate APK or AAB for testing
  ```bash
  flutter build appbundle --release
  # or
  flutter build apk --release
  ```
- [ ] Test on actual device or emulator
- [ ] Verify Firebase initialization
- [ ] Verify Google Sign-In works

### 14. Testing Before Upload

- [ ] Test auth flow (email/password, Google, guest, invite code)
- [ ] Test core features (CRUD clients, orders, services)
- [ ] Test Firestore sync online/offline
- [ ] Test notifications (FCM push notifications)
- [ ] Test on multiple Android versions (min SDK to latest)
- [ ] Memory/performance profiling

### 15. Upload to Google Play

- [ ] Build finalized release AAB
- [ ] Upload to internal testing track first
- [ ] Test link with internal testers (min 3 devices)
- [ ] Fix any Firebase/connectivity issues
- [ ] Move to beta track (optional)
- [ ] Prepare release notes in Polish + English
- [ ] Schedule rollout (staged: 5% → 25% → 100%)

---

## 🔐 Security Checklist

- [x] API keys in firebase_options.dart (acceptable - Firebase-bound by default)
- [x] OAuth Client ID externalized
- [x] keystore passwords in .gitignore
- [x] Firestore Security Rules enforced
- [x] Hive storage encrypted
- [x] Debug info stripped in release build

---

## 📊 Configuration Summary

**App**: DetailingPro (com.detailing.business.app)  
**Version**: 1.0.0 (build 1)  
**Min SDK**: flutter.minSdkVersion (typically 21)  
**Target SDK**: flutter.targetSdkVersion (typically 34+)  
**Signing**: keystore @ android/app/release.jks  
**Locales**: 9 (en, pl, ru, de, es, it, pt, tr, zh)  
**Permissions**: CAMERA, POST_NOTIFICATIONS, READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE

---

## 🚀 Next Steps

1. **Test Build**:

   ```bash
   flutter build appbundle --release
   ```

2. **Manual QA**: Install on device, test all features

3. **Google Play Console**: Create app listing, upload AAB

4. **Legal Finalization**: Review and post privacy policy/terms

5. **Soft Launch**: Beta track with testers

6. **Production Release**: Staged rollout starting at 5%
