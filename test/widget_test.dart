import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    Hive.init('test_hive');

    await Hive.openBox(HiveBoxes.clients);
    await Hive.openBox(HiveBoxes.services);
    await Hive.openBox(HiveBoxes.orders);
    await Hive.openBox(HiveBoxes.inventory);
    await Hive.openBox(HiveBoxes.settings);

    await Hive.box(HiveBoxes.settings).put('locale', 'en');
    await Hive.box(HiveBoxes.settings).put('currency', '€');
  });

  tearDown(() async {
    await Hive.box(HiveBoxes.orders).clear();
    await Hive.box(HiveBoxes.clients).clear();
    await Hive.box(HiveBoxes.services).clear();
    await Hive.box(HiveBoxes.inventory).clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App starts and shows auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DetailingProApp(locale: Locale('en')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
  });
}
