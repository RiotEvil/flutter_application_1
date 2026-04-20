import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/cloud_profile_sync.dart';

void main() {
  group('CloudProfileSync', () {
    test('ensureUserProfile should handle no Firebase', () async {
      await CloudProfileSync.ensureUserProfile(fallbackName: 'Test User');
      // Should not crash
    });

    test('ensurePlanDefaults should handle no Firebase', () async {
      await CloudProfileSync.ensurePlanDefaults();
      // Should not crash
    });
  });
}
