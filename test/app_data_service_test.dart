import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_1/core/app_data_service.dart';
import 'package:flutter_application_1/core/constants.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.orders);
    await Hive.openBox(HiveBoxes.settings);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('AppDataService', () {
    test('syncOrderToCloud should handle basic order sync', () async {
      final order = {'id': 'test_order', 'clientName': 'Test Client'};

      await AppDataService.syncOrderToCloud(order);

      final hiveOrder = Hive.box(HiveBoxes.orders).get('test_order');
      expect(hiveOrder, isNotNull);
    });

    test('deleteOrderFromCloud should remove from Hive', () async {
      await Hive.box(
        HiveBoxes.orders,
      ).put('test_delete', {'id': 'test_delete'});

      await AppDataService.deleteOrderFromCloud('test_delete');

      final deletedOrder = Hive.box(HiveBoxes.orders).get('test_delete');
      expect(deletedOrder, isNull);
    });
  });
}
