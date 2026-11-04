import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/screens/food_tab.dart';
import 'package:lockout/screens/body_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });
  setUp(() => wipeDatabaseAndReseed(DatabaseService.instance));
  Finder field(String label) => find.descendant(
    of: find.byWidgetPredicate((w) => w is NvField && w.label == label),
    matching: find.byType(TextFormField),
  );
  testWidgets('a custom meal is saved to the selected day and can be edited', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: FoodTab()),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('previous-food-day')));
    await settle(tester);
    await tester.tap(find.text('Log food'));
    await settle(tester);
    await tester.enterText(field('Search foods'), 'My test meal');
    await tester.pump();
    await tester.tap(find.text('Add custom: My test meal'));
    await settle(tester);
    await tester.enterText(field('Calories (kcal)'), '240');
    await tester.ensureVisible(find.text('Save food'));
    await settle(tester);
    await tester.tap(find.text('Save food'));
    await settle(tester);
    final date = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;
    final rows = await DatabaseService.instance.getFoodLogsForDate(date);
    expect(rows.single['kcal'], 240);
    expect(rows.single['name'], 'My test meal');
    await tester.scrollUntilVisible(
      find.text('My test meal'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    expect(find.text('My test meal'), findsOneWidget);
    await tester.tap(find.text('My test meal'));
    await settle(tester);
    await tester.enterText(field('Calories (kcal)'), '300');
    await tester.ensureVisible(find.text('Save food'));
    await settle(tester);
    await tester.tap(find.text('Save food'));
    await settle(tester);
    expect(
      (await DatabaseService.instance.getFoodLogsForDate(date)).single['kcal'],
      300,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('a measurement updates the real weight trend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: BodyTab()),
    );
    await settle(tester);
    await tester.tap(find.text('Log measurement'));
    await settle(tester);
    await tester.enterText(field('Weight (kg)'), '82.5');
    await tester.ensureVisible(find.text('Save measurement'));
    await settle(tester);
    await tester.tap(find.text('Save measurement'));
    await settle(tester);
    expect(
      (await DatabaseService.instance.getBodyLogs()).single['weight_kg'],
      82.5,
    );
    expect(find.text('82.5 kg'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('pounds display and entry preserve kilograms in storage', (
    tester,
  ) async {
    await DatabaseService.instance.saveSetting('unit_weight', 'lb');
    addTearDown(
      () => DatabaseService.instance.saveSetting('unit_weight', 'kg'),
    );
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: BodyTab()),
    );
    await settle(tester);
    await tester.tap(find.text('Log measurement'));
    await settle(tester);
    await tester.enterText(field('Weight (lb)'), '220.462');
    await tester.ensureVisible(find.text('Save measurement'));
    await settle(tester);
    await tester.tap(find.text('Save measurement'));
    await settle(tester);
    expect(
      (await DatabaseService.instance.getBodyLogs()).single['weight_kg'],
      closeTo(100, .001),
    );
    expect(find.text('220.5 lb'), findsWidgets);
  });
}
