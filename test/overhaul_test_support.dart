import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'test_helpers.dart';

void useTestDatabase() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });
  setUp(() => wipeDatabaseAndReseed(DatabaseService.instance));
}

Future<void> pumpPage(WidgetTester t, Widget page) async {
  await t.binding.setSurfaceSize(const Size(600, 2400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(theme: lockoutTestTheme(), home: page));
  await settle(t);
}

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NvField && w.label == label),
  matching: find.byType(TextFormField),
);
Future<void> press(WidgetTester t, String label) async {
  final f = find.text(label).last;
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await settle(t);
}

Future<void> flushUndo(WidgetTester t) => t.pump(const Duration(seconds: 6));
