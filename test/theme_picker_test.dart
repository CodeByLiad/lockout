import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/theme_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() {
    // Not sqfliteFfiInit()/databaseFactoryFfi: the isolate factory arms a
    // 10s sqflite timeout inside fake_async that a bounded `settle` never
    // cancels, and this suite previously hung for ten minutes on exactly
    // that. Every other suite in the repo uses the no-isolate factory
    // against an in-memory database for the same reason.
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
    ThemeController.instance.resetForTest();
    await ThemeController.instance.load();
  });

  // The serial runner reuses one process across every suite (see
  // `lockout_app_test.dart:44`), so whatever this suite last selected would
  // otherwise leak into the next one to run.
  tearDown(() => ThemeController.instance.resetForTest());

  testWidgets('offers one swatch per accent and no Material You entry',
      (tester) async {
    await tester.pumpWidget(hostedProfileTab());
    await settle(tester);

    for (final accent in LockoutAccent.all) {
      expect(find.text(accent.name), findsOneWidget, reason: accent.key);
    }
    // Material You went with the `dynamic_color` dependency: the house
    // system forbids wallpaper-derived colour.
    expect(find.text('Match my phone'), findsNothing);
  });

  testWidgets('choosing a swatch persists it and repaints', (tester) async {
    await tester.pumpWidget(hostedProfileTab());
    await settle(tester);

    await tester.tap(find.text(LockoutAccent.coral.name));
    await settle(tester);

    expect(ThemeController.instance.accent, LockoutAccent.coral);
    expect(
      await DatabaseService.instance.getSetting('theme_key', defaultValue: ''),
      'system|coral',
      reason: 'the accent moves without disturbing the brightness axis',
    );
  });

  testWidgets('no string in settings says LIAD', (tester) async {
    await tester.pumpWidget(hostedProfileTab());
    await settle(tester);
    expect(find.textContaining('LIAD'), findsNothing);
  });

  testWidgets(
      'a swatch tap that fails to persist warns instead of vanishing as an '
      'unhandled error', (tester) async {
    // Forces `ThemeController.selectAccent`'s `saveSetting` write to throw,
    // the
    // same aborting-trigger technique `database_service_test.dart` uses for
    // `set_logs`. Self-contained: created and dropped inside this test only,
    // so it cannot leak into the suites the serial runner reuses this
    // process for.
    final database = await DatabaseService.instance.database;
    Future<void> dropTrigger() =>
        database.execute('DROP TRIGGER IF EXISTS test_fail_theme_key');
    await dropTrigger();
    addTearDown(dropTrigger);
    await database.execute(
      "CREATE TRIGGER test_fail_theme_key BEFORE INSERT ON user_settings "
      "WHEN NEW.key = 'theme_key' "
      "BEGIN SELECT RAISE(ABORT, 'rejected by test trigger'); END;",
    );

    await tester.pumpWidget(hostedProfileTab());
    await settle(tester);

    await tester.tap(find.text(LockoutAccent.coral.name));
    await settle(tester);

    // Before the fix, `onTap: () async => await _applyTheme(key)` still
    // discarded the returned Future (`InkWell.onTap` is `void Function()`),
    // so this throw reached the test binding as an unhandled async error
    // rather than being caught anywhere.
    expect(tester.takeException(), isNull);
    expect(find.text('Could not apply theme.'), findsOneWidget);
  });
}
