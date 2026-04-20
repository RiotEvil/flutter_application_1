import 'package:flutter/foundation.dart';

class RevenueCatConfig {
  RevenueCatConfig._();

  // Provide keys via --dart-define in CI/CD or local build command.
  static const String _androidApiKeyEnv = String.fromEnvironment(
    'RC_ANDROID_API_KEY',
    defaultValue: '',
  );
  static const String _iosApiKeyEnv = String.fromEnvironment(
    'RC_IOS_API_KEY',
    defaultValue: '',
  );

  static String get androidApiKey => _androidApiKeyEnv.trim();
  static String get iosApiKey => _iosApiKeyEnv.trim();

  // Entitlement identifiers in RevenueCat.
  static const String proEntitlementId = 'pro';
  static const String businessEntitlementId = 'business';

  // Optional offering identifiers in RevenueCat. Override via dart-define if needed.
  static const String proOfferingId = String.fromEnvironment(
    'RC_PRO_OFFERING_ID',
    defaultValue: 'pro',
  );
  static const String businessOfferingId = String.fromEnvironment(
    'RC_BUSINESS_OFFERING_ID',
    defaultValue: 'business',
  );

  static bool get isEnabledForCurrentPlatform {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidApiKey.isNotEmpty;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosApiKey.isNotEmpty;
    }
    return false;
  }
}
