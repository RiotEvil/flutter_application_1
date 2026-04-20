import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/invite_service.dart';

void main() {
  group('InviteService', () {
    test('validateAndJoinOrg should handle no Firebase', () async {
      try {
        await InviteService.validateAndJoinOrg(
          code: 'TESTCODE',
          userUid: 'testUserId',
        );
        fail('Should throw exception');
      } catch (e) {
        expect(e.toString(), contains('Firebase is not initialized'));
      }
    });
  });
}
