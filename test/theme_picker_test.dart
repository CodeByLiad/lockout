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

  /// Pumps the picker with semantics switched on, and hands back the handle
  /// the test body has to dispose.
  ///
  /// An accent swatch is a colour and a shape with no visible text, so the
  /// accent half of this suite addresses it the only way a screen-reader
  /// user can — by its semantics label, and `find.bySemanticsLabel` throws
  /// unless a semantics handle is open.
  ///
  /// `addTearDown(handle.dispose)` does not work here: `WidgetTester`
  /// verifies that every handle was disposed *before* it runs tear-downs, so
  /// the disposal has to happen inside the body.
  Future<SemanticsHandle> pumpPicker(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(hostedProfileTab());
    await settle(tester);
    return handle;
  }

  testWidgets('the picker offers all three brightness choices',
      (tester) async {
    final semantics = await pumpPicker(tester);

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('the picker offers all five accents', (tester) async {
    final semantics = await pumpPicker(tester);

    for (final accent in LockoutAccent.all) {
      expect(find.bySemanticsLabel(accent.name), findsOneWidget,
          reason: '${accent.key} swatch is missing');
    }

    semantics.dispose();
  });

  testWidgets('gold is not offered, it belongs to another app',
      (tester) async {
    final semantics = await pumpPicker(tester);
    expect(find.text('Gold'), findsNothing);

    semantics.dispose();
  });

  testWidgets('choosing an accent persists it without touching brightness',
      (tester) async {
    await ThemeController.instance
        .selectBrightness(LockoutBrightnessChoice.dark);
    final semantics = await pumpPicker(tester);

    await tester.tap(find.bySemanticsLabel(LockoutAccent.teal.name));
    await settle(tester);

    expect(ThemeController.instance.accent, LockoutAccent.teal);
    expect(ThemeController.instance.brightnessChoice,
        LockoutBrightnessChoice.dark);
    expect(
      await DatabaseService.instance.getSetting('theme_key', defaultValue: ''),
      'dark|teal',
      reason: 'both axes land in the one setting the schema already has',
    );

    semantics.dispose();
  });

  testWidgets('choosing a brightness persists it without touching the accent',
      (tester) async {
    await ThemeController.instance.selectAccent(LockoutAccent.coral);
    final semantics = await pumpPicker(tester);

    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(ThemeController.instance.brightnessChoice,
        LockoutBrightnessChoice.dark);
    expect(ThemeController.instance.accent, LockoutAccent.coral);

    semantics.dispose();
  });

  testWidgets('the selected swatch announces itself as selected',
      (tester) async {
    await ThemeController.instance.selectAccent(LockoutAccent.violet);
    final semantics = await pumpPicker(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(LockoutAccent.violet.name)),
      matchesSemantics(
        label: LockoutAccent.violet.name,
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('an unselected swatch announces that it is not selected',
      (tester) async {
    await ThemeController.instance.selectAccent(LockoutAccent.violet);
    final semantics = await pumpPicker(tester);

    // `hasSelectedState` with `isSelected` false, not the absence of both: a
    // swatch that is merely available has to say so, or a screen reader
    // cannot tell "not chosen" from "not choosable".
    expect(
      tester.getSemantics(find.bySemanticsLabel(LockoutAccent.teal.name)),
      matchesSemantics(
        label: LockoutAccent.teal.name,
        isSelected: false,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('every swatch clears the 48dp touch target', (tester) async {
    final semantics = await pumpPicker(tester);

    for (final accent in LockoutAccent.all) {
      final size = tester.getSize(find.bySemanticsLabel(accent.name));
      expect(size.width, greaterThanOrEqualTo(48), reason: accent.key);
      expect(size.height, greaterThanOrEqualTo(48), reason: accent.key);
    }

    semantics.dispose();
  });

  testWidgets('there is no wallpaper-colours control', (tester) async {
    final semantics = await pumpPicker(tester);
    expect(find.textContaining('wallpaper'), findsNothing);
    expect(find.textContaining('Dynamic'), findsNothing);
    // Material You went with the `dynamic_color` dependency: the house
    // system forbids wallpaper-derived colour.
    expect(find.text('Match my phone'), findsNothing);

    semantics.dispose();
  });

  testWidgets('no string in settings says LIAD', (tester) async {
    final semantics = await pumpPicker(tester);
    expect(find.textContaining('LIAD'), findsNothing);

    semantics.dispose();
  });

  testWidgets(
      'a swatch tap that fails to persist warns instead of vanishing as an '
      'unhandled error', (tester) async {
    // Forces `ThemeController.selectAccent`'s `saveSetting` write to throw,
    // the same aborting-trigger technique `database_service_test.dart` uses
    // for `set_logs`. Self-contained: created and dropped inside this test
    // only, so it cannot leak into the suites the serial runner reuses this
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

    final semantics = await pumpPicker(tester);

    await tester.tap(find.bySemanticsLabel(LockoutAccent.coral.name));
    await settle(tester);

    // Before the fix, `onTap: () async => await _applyTheme(key)` still
    // discarded the returned Future (`InkWell.onTap` is `void Function()`),
    // so this throw reached the test binding as an unhandled async error
    // rather than being caught anywhere.
    expect(tester.takeException(), isNull);
    expect(find.text('Could not apply the accent.'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets(
      'a brightness tap that fails to persist warns rather than throwing',
      (tester) async {
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

    final semantics = await pumpPicker(tester);

    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Could not apply the theme.'), findsOneWidget);

    semantics.dispose();
  });
}
