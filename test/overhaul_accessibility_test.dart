import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/screens/main_screen.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/house/nv_button.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });
  setUp(() => wipeDatabaseAndReseed(DatabaseService.instance));
  testWidgets('expressive primary actions support keyboard activation', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvButton(
            variant: NvButtonVariant.filled,
            label: 'Start workout',
            onPressed: () => calls++,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
  });
  testWidgets('all main destinations and appearance fit 360dp at 1.5x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const MainScreen(),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    for (final label in ['Training', 'Progress', 'Food']) {
      await tester.tap(find.text(label));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(find.byKey(const ValueKey('open-settings')).first);
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Appearance'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
