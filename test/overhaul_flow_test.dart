import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/screens/main_screen.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/theme_controller.dart';
import 'package:lockout/theme/lockout_shapes.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });
  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
    ThemeController.instance.resetForTest();
    await ThemeController.instance.load();
  });
  tearDown(() => ThemeController.instance.resetForTest());

  Widget host(Widget child) =>
      MaterialApp(theme: ThemeController.instance.lightTheme, home: child);

  testWidgets(
    'approved shell has four task destinations and focused settings',
    (tester) async {
      await tester.pumpWidget(host(MainScreen()));
      await settle(tester);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-settings')).first);
      await settle(tester);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(
        find.byKey(const ValueKey('start-custom-workout')),
        findsOneWidget,
      );
    },
  );

  testWidgets('a workout minimizes, survives tab changes and resumes', (
    tester,
  ) async {
    await tester.pumpWidget(host(MainScreen()));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('start-custom-workout')));
    await settle(tester);
    expect(find.byKey(const ValueKey('minimize-workout')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byKey(const ValueKey('resume-workout')), findsOneWidget);
    await tester.tap(find.text('Training'));
    await settle(tester);
    expect(find.byKey(const ValueKey('resume-workout')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resume-workout')));
    await settle(tester);
    expect(find.text('Custom session'), findsWidgets);
    expect(find.byKey(const ValueKey('minimize-workout')), findsOneWidget);
    // Dispose the session timer before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
    'expressive action cards fit large text and expose a tap action',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: NvActionCard(
                        title: 'Log food',
                        subtitle: '1,420 kcal left',
                        icon: Icons.restaurant,
                        shape: LockoutShape.bun,
                        tone: NvTone.secondary,
                        onPressed: () => taps++,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NvActionCard(
                        title: 'Weigh in',
                        subtitle: '82.5 kg',
                        icon: Icons.monitor_weight,
                        shape: LockoutShape.pentagon,
                        tone: NvTone.tertiary,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final semantics = tester.ensureSemantics();
      semanticTap(tester, find.byType(NvActionCard).first);
      expect(taps, 1);
      semantics.dispose();
    },
  );
}
