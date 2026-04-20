# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android Release Signing

For security, do not store real signing passwords in repository files.

Release signing can be provided in two ways:

- Local file: create `android/key.properties` from `android/key.properties.example`.
- Environment variables (recommended for CI/CD):
  - `ANDROID_SIGNING_KEYALIAS`
  - `ANDROID_SIGNING_KEYPASSWORD`
  - `ANDROID_SIGNING_STOREFILE`
  - `ANDROID_SIGNING_STOREPASSWORD`

If release signing is missing, release tasks will fail with a clear error,
while debug/non-release tasks continue to work.

## RevenueCat Production Configuration

Do not store RevenueCat keys in source code.

### Flutter app keys (dart-define)

Pass SDK keys at build/run time:

```powershell
flutter run --dart-define=RC_ANDROID_API_KEY=your_android_public_sdk_key

flutter build appbundle --release `
  --dart-define=RC_ANDROID_API_KEY=your_android_public_sdk_key `
  --dart-define=RC_IOS_API_KEY=your_ios_public_sdk_key `
  --dart-define=RC_PRO_OFFERING_ID=pro `
  --dart-define=RC_BUSINESS_OFFERING_ID=business
```

### Cloud Functions secret (server-side validation)

Set RevenueCat secret API key in Firebase Secret Manager:

```powershell
firebase functions:secrets:set REVENUECAT_SECRET_KEY
firebase deploy --only functions
```

After deploy, verify endpoint health:

```powershell
curl https://europe-west3-detailing-pro.cloudfunctions.net/functionsHealth
```
