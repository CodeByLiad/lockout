import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/about_screen.dart';
import 'package:lockout/screens/profile_tab.dart';
import 'package:lockout/screens/settings_screen.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/goal_service.dart';
import 'package:lockout/services/nutrition_planner.dart';
import 'package:lockout/services/schedule_service.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/theme/theme_controller.dart';
import 'package:lockout/widgets/house/nv_button.dart';
import 'package:lockout/widgets/house/nv_grouped_list.dart';
import 'package:lockout/widgets/house/nv_segmented_button.dart';
import 'package:lockout/widgets/house/nv_switch.dart';
import 'package:lockout/widgets/house/nv_text_field.dart';
import 'package:lockout/widgets/lockout_card.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  /// Structural guards rather than behavioural tests: the v2 sweep is only
  /// finished when no widget draws a square corner or a raw hex colour.
  group('v2 style sweep', () {
    test('no widget or screen uses BorderRadius.zero', () {
      final offenders = <String>[];
      for (final dir in ['lib/widgets', 'lib/screens']) {
        for (final f in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          if (f.readAsStringSync().contains('BorderRadius.zero')) {
            offenders.add(f.path);
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('screens do not hardcode palette colours', () {
      final offenders = <String>[];
      final hex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
      for (final f in Directory('lib/screens')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        if (hex.hasMatch(f.readAsStringSync())) offenders.add(f.path);
      }
      expect(offenders, isEmpty);
    });
  });

  group('settings target weight', () {
    /// Types [typed] into the Food card's target-weight field, presses
    /// CALCULATE MY TARGET and returns whatever reached `user_settings`.
    Future<String> saveTargetWeight(WidgetTester tester, String typed) async {
      // Settings is one long scroll; a surface tall enough to hold the food
      // card keeps the field and its button on screen, so the test drives the
      // save rather than the scroll physics.
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: SettingsScreen(onSettingsUpdated: () {}),
        ),
      );
      await settle(tester);

      final field = find.descendant(
        of: find.widgetWithText(NvTextField, 'Target weight (kg)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, typed);
      await tester.pump();

      await tester.tap(find.text('Calculate my target'));
      await settle(tester);

      final stored = await DatabaseService.instance
          .getSetting('target_weight_kg', defaultValue: '');

      // Flush the toast's auto-dismiss Timer so none is left pending when
      // the tree is torn down.
      await tester.pump(const Duration(seconds: 6));
      return stored;
    }

    testWidgets('a non-finite target weight never reaches the database',
        (tester) async {
      // `double.tryParse('Infinity')` succeeds, so an unguarded save let the
      // BODY screen's TARGET tile render "Infinity kg" and poisoned every
      // calculation downstream of the goal profile.
      final stored = await saveTargetWeight(tester, 'Infinity');

      final parsed = double.tryParse(stored);
      expect(parsed, isNotNull);
      expect(parsed!.isFinite, isTrue);

      final profile = await GoalService.instance.loadProfile();
      expect(profile.targetWeightKg.isFinite, isTrue);
    });

    testWidgets('a negative target weight never reaches the database',
        (tester) async {
      final stored = await saveTargetWeight(tester, '-72');

      final parsed = double.tryParse(stored);
      expect(parsed, isNotNull);
      expect(parsed, greaterThanOrEqualTo(0.0));

      final profile = await GoalService.instance.loadProfile();
      expect(profile.targetWeightKg, greaterThanOrEqualTo(0.0));
    });
  });

  // The whole-branch reviewer measured this on an edge-to-edge API 36
  // window: SettingsScreen has an AppBar but no bottomNavigationBar, so its
  // scroll view runs to the physical bottom of the screen and fixed padding
  // alone cannot clear a 48dp navigation bar. The tab screens escape this
  // because BottomNav carries its own SafeArea; a pushed route has nothing.
  testWidgets('the last settings card scrolls clear of the navigation bar',
      (tester) async {
    tester.view.physicalSize = const Size(640, 1000);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: SettingsScreen(onSettingsUpdated: () {}),
      ),
    );
    await settle(tester);

    // Scroll to the very end: the last line of the last card must then sit
    // above the navigation bar rather than under it.
    final scroller = find.byType(SingleChildScrollView).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scroller, const Offset(0, -800));
      await tester.pumpAndSettle();
    }

    // The About card's licence/version body moved onto its own route in
    // Task 10 (see about_screen_test.dart); what is left at the bottom of
    // this scroll is the row that pushes it.
    //
    // Measured on the ROW, not on its title. `find.text` probes the text's
    // own box, which sits about 25dp above the row's bottom edge —
    // NvListItem's 16dp bottom padding plus the slack its 72dp minimum
    // height leaves when one line of title is centred in it. That slack is
    // wider than the regression: with the inset dropped the title bottom
    // lands at 931 while the row's real bottom is 956, four dp under a nav
    // bar whose top is 952. Probing the title would report that as clear.
    final title = find.text('About Lockout');
    expect(title, findsOneWidget);
    final about = find.ancestor(of: title, matching: find.byType(NvListItem));
    expect(about, findsOneWidget);

    expect(tester.getBottomLeft(about).dy, lessThanOrEqualTo(1000.0 - 48.0));
  });

  /// Settings is one long scroll. A surface tall enough to hold every card
  /// keeps the field or button a test drives on screen, so the test
  /// exercises the screen rather than the scroll physics.
  Future<void> pumpSettings(WidgetTester tester, {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? lockoutTestTheme(),
        home: SettingsScreen(onSettingsUpdated: () {}),
      ),
    );
    await settle(tester);
  }

  /// The same body, but at a 360dp logical width (1080 / 3.0, matching the
  /// QA device `main_screen_test.dart` already renders at). Every other
  /// settings test here runs at 800dp, so the reminders-expanded branch —
  /// two `SwitchListTile`s, a `CalmRow` and an `OutlinedButton` all stacked
  /// under a fixed-width caption — had no overflow guard at all until this
  /// existed, which is exactly the width the 212px Training-days overflow
  /// was caught at.
  Future<void> pumpSettingsNarrow(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: SettingsScreen(onSettingsUpdated: () {}),
      ),
    );
    await settle(tester);
  }

  /// Seeds a profile complete enough for `GoalService.snapshot()` to return a
  /// plan, so Settings renders its calculated-plan block. The four-week
  /// timeframe against a 30kg cut is deliberate: it trips
  /// `NutritionPlanner`'s rate cap, so the warning container renders too.
  /// Both subtrees are invisible in the default state.
  Future<void> seedCalculablePlan({String heightCm = '175.0'}) async {
    final db = DatabaseService.instance;
    await db.saveSetting('height_cm', heightCm);
    await db.saveSetting('age', '30');
    await db.saveSetting('target_weight_kg', '70');
    await db.saveSetting('goal_weeks', '4');
    await db.insertBodyLog(BodyEntry(
      id: 'seed-plan',
      dateStr: '2026-09-10',
      weightKg: 100.0,
    ).toMap());
  }

  // Step 5 of the brief is the task's only new user-facing capability, and
  // replacing this row's `onTap` with `() {}` — About unreachable from the
  // whole app — left the full suite green. A row rendering with the right
  // title is not a route; this taps it and looks for the screen.
  testWidgets('the About row pushes the About screen', (tester) async {
    await pumpSettings(tester);

    expect(find.byType(AboutScreen), findsNothing,
        reason: 'About must arrive by the tap, not by already being there');

    await tester.tap(find.text('About Lockout'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget,
        reason: 'the About row is the only way into the About screen');
  });

  /// The text sitting in the field labelled [label].
  String fieldText(WidgetTester tester, String label) {
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(NvTextField, label),
        matching: find.byType(TextField),
      ),
    );
    return field.controller!.text;
  }

  group('settings height', () {
    /// Types [typed] into Height (cm), presses SAVE HEIGHT and returns
    /// whatever reached `user_settings`.
    Future<String> saveHeight(WidgetTester tester, String typed) async {
      await pumpSettings(tester);

      final field = find.descendant(
        of: find.widgetWithText(NvTextField, 'Height (cm)'),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, typed);
      await tester.pump();

      await tester.tap(find.text('Save height'));
      await settle(tester);

      final stored = await DatabaseService.instance
          .getSetting('height_cm', defaultValue: '');

      // Flush the toast's auto-dismiss Timer so none is left pending when
      // the tree is torn down.
      await tester.pump(const Duration(seconds: 6));
      return stored;
    }

    testWidgets('a non-finite height never reaches the database',
        (tester) async {
      // `double.tryParse('Infinity')` succeeds and `Infinity > 0` is true, so
      // an unguarded save stored the literal string 'Infinity'. Reading it
      // back threw `Unsupported operation: Infinity or NaN toInt` out of
      // `NutritionPlanner.build`, taking BODY, FOOD, TODAY and Settings down.
      final stored = await saveHeight(tester, 'Infinity');

      final parsed = double.tryParse(stored);
      expect(parsed, isNotNull);
      expect(parsed!.isFinite, isTrue);

      final profile = await GoalService.instance.loadProfile();
      expect(profile.heightCm.isFinite, isTrue);
      expect(profile.heightCm, greaterThan(0));
    });

    testWidgets('a NaN height never reaches the database', (tester) async {
      // Contract documentation rather than mutation coverage, and labelled
      // as such: NaN fails every comparison, so any guard that catches
      // Infinity catches NaN too — `_usableHeightCm` written as
      // `cm != double.infinity && cm > 0` leaves the whole suite green.
      // Kept because `double.tryParse('NaN')` succeeds and both values reach
      // this unformatted field by the same route (a paste, or a letters
      // keyboard), so the write side should name what it refuses.
      final stored = await saveHeight(tester, 'NaN');

      final parsed = double.tryParse(stored);
      expect(parsed, isNotNull);
      expect(parsed!.isFinite, isTrue);
      expect(parsed, greaterThan(0));

      final profile = await GoalService.instance.loadProfile();
      expect(profile.heightCm.isFinite, isTrue);
      expect(profile.heightCm, greaterThan(0));
    });
  });

  group('settings load survives a poisoned height row', () {
    /// `BackupService.importFromJson` writes `user_settings` rows verbatim,
    /// so a hand-edited or older-build backup restores `height_cm =
    /// 'Infinity'` untouched, as does any row a build predating the
    /// write-side guard already wrote. Settings used to parse that row itself
    /// rather than through `GoalService`'s clamp, and
    /// `Units.cmToFeetInches` throws `Unsupported operation: Infinity or NaN
    /// toInt` on it — inside `_loadSettings`, before its `setState`. The
    /// screen then rendered with every field empty and no plan, silently, and
    /// the same throw inside `_import` swallowed the reschedule, the
    /// `onSettingsUpdated` callback and the "Import complete" toast.
    for (final poison in ['Infinity', 'NaN']) {
      testWidgets('a stored height of $poison loads as the default',
          (tester) async {
        await seedCalculablePlan(heightCm: poison);
        await pumpSettings(tester);

        expect(fieldText(tester, 'Height (cm)'), '175');
        // The rest of the load must have completed, not been abandoned
        // half way: these are the fields and the block that came up empty.
        expect(fieldText(tester, 'Age'), '30');
        expect(fieldText(tester, 'Target weight (kg)'), '70.0');
        expect(find.text('Daily target'), findsOneWidget);
      });
    }
  });

  group('a notification service that will not start', () {
    // Declared ahead of the import group on purpose, and it has to stay
    // there. That group calls
    // `AndroidFlutterLocalNotificationsPlugin.registerWith()`, which
    // installs a platform instance for the rest of the process, and
    // `NotificationService` latches `_ready` on its own singleton once that
    // instance answers. After it has run, nothing in this file can still
    // reach the state these two tests are about: a notification plugin that
    // is simply not there, which is what `flutter test` gives by default
    // and what a device whose channel is unavailable gives in the field.
    //
    // `main.dart` guards its own boot call and reports the failure, on the
    // stated grounds that "the toggles in Settings already handle a service
    // that is not running". These are the two places that has to be true
    // of: the toggle that comment names, and the import tail, where the
    // throw landed between the restore and the user being told it had
    // happened.

    /// Lets `init()` get as far as the notification plugin.
    ///
    /// `init()` asks for the local timezone first, and an unmocked platform
    /// channel under `flutter test` never answers at all — that await never
    /// returns, which is a different failure from the one under test and
    /// would mask it. This mocks the one channel that is merely a
    /// dependency of the code under test. The notification plugin itself is
    /// left exactly as absent as it is on a device with no channel for it,
    /// where `_plugin.initialize` throws a `LateInitializationError`
    /// reaching for a platform instance nothing ever registered.
    void answerTheTimezoneChannel(WidgetTester tester) {
      const timezone = MethodChannel('flutter_timezone');
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(timezone, (call) async => 'UTC');
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(timezone, null));
    }

    testWidgets('switching reminders on refuses rather than throwing',
        (tester) async {
      answerTheTimezoneChannel(tester);
      await pumpSettings(tester);

      final toggle = find.widgetWithText(NvSwitchRow, 'Daily training nudge');
      await tester.tap(
        find.descendant(of: toggle, matching: find.byType(Switch)),
      );
      await settle(tester);

      expect(tester.takeException(), isNull,
          reason: 'the toggle awaits `requestPermission()`, which awaits an '
              '`init()` that throws here, with nothing between them');
      expect(tester.widget<NvSwitchRow>(toggle).value, isFalse,
          reason: 'a switch that goes on while the service is dead promises '
              'reminders that can never fire');
      expect(find.textContaining('Notification permission denied'),
          findsOneWidget,
          reason: 'a service that cannot start and a user who declines are '
              'the same outcome for this caller: no reminders, and a switch '
              'that stays off rather than lying');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('an import still finishes when the reminders it restores '
        'cannot be scheduled', (tester) async {
      // The same failure, in the place it costs the most: `rescheduleAll()`
      // sits between the restore and `onSettingsUpdated()` plus the "Import
      // complete" toast, so an unguarded one applied the import, left the OS
      // holding the pre-restore schedule, and told the user nothing at all.
      answerTheTimezoneChannel(tester);

      final realPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _StubFilePicker(jsonEncode({
        'app': 'lockout',
        'schemaVersion': 2,
        'data': {
          'user_settings': [
            {'key': 'reminders_enabled', 'value': 'true'},
            {'key': 'reminder_hour', 'value': '7'},
          ],
        },
      }));
      addTearDown(() => FilePickerPlatform.instance = realPicker);
      addTearDown(() => SettingsBody.importInFlight.value = false);

      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var callbacks = 0;
      await tester.pumpWidget(MaterialApp(
        theme: lockoutTestTheme(),
        home: SettingsScreen(onSettingsUpdated: () => callbacks++),
      ));
      await settle(tester);

      await tester.tap(find.text('Import backup JSON'));
      await settle(tester);
      await tester.tap(find.text('Choose file'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(callbacks, 1, reason: 'onSettingsUpdated must still fire');
      expect(find.textContaining('Import complete'), findsOneWidget,
          reason: 'the import applied, so the user must be told so even when '
              'the reminders inside it cannot be scheduled');

      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('a restore of a hand-edited backup still finishes', () {
    /// The two channels `NotificationService.rescheduleAll` touches. Both
    /// must be mocked: an unmocked platform channel under `flutter test`
    /// never answers at all, so the `await` inside `init()` hangs forever
    /// and nothing after it in `_import` runs. Mocking them also makes the
    /// reschedule observable — nothing registers a
    /// `FlutterLocalNotificationsPlatform` in a test, so
    /// `registerWith()` here stands in for the plugin registrant.
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    const timezone = MethodChannel('flutter_timezone');

    /// Drives the whole import tail through the UI — picker, restore,
    /// reschedule, callback, toast — over [raw], and hands back the three
    /// things the tail is pinned on.
    Future<
        ({
          List<String> notificationCalls,
          int callbacks,
          SnackBar toast,
          bool? lockWhilePicking,
        })> runImport(WidgetTester tester, String raw) async {
      final realPicker = FilePickerPlatform.instance;
      final picker = _StubFilePicker(raw);
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = realPicker);
      addTearDown(() => SettingsBody.importInFlight.value = false);

      AndroidFlutterLocalNotificationsPlugin.registerWith();
      final notificationCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notifications,
        (call) async {
          notificationCalls.add(call.method);
          // The Android impl declares initialize as Future<bool>; returning
          // null there throws a TypeError before anything is scheduled.
          return call.method == 'initialize' ? true : null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(notifications, null));
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(timezone, (call) async => 'UTC');
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(timezone, null));

      var callbacks = 0;
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: lockoutTestTheme(),
        home: SettingsScreen(onSettingsUpdated: () => callbacks++),
      ));
      await settle(tester);

      await tester.tap(find.text('Import backup JSON'));
      await settle(tester);
      await tester.tap(find.text('Choose file'));
      await settle(tester);

      // Flush the toast's auto-dismiss Timer before teardown.
      addTearDown(() => tester.pump(const Duration(seconds: 6)));

      return (
        notificationCalls: notificationCalls,
        callbacks: callbacks,
        toast: tester.widget<SnackBar>(find.byType(SnackBar)),
        lockWhilePicking: picker.lockWhilePicking,
      );
    }

    String backupJson(Object? weightKg) => jsonEncode({
          'app': 'lockout',
          'schemaVersion': 2,
          'data': {
            'body_logs': [
              {
                'id': '1',
                'date_str': '2026-01-01',
                'weight_kg': weightKg,
                'waist_cm': 0.0,
              },
            ],
            'user_settings': [
              {'key': 'reminders_enabled', 'value': 'true'},
              {'key': 'reminder_hour', 'value': '7'},
              {'key': 'reminder_minute', 'value': '30'},
            ],
          },
        });

    testWidgets(
        'a backup carrying a non-numeric weight_kg still reschedules, still '
        'calls back and still tells the user the import applied',
        (tester) async {
      // A hand-edited backup puts the string 'heavy' into
      // `body_logs.weight_kg` — a REAL-affinity column SQLite will happily
      // keep as TEXT. `_loadSettings` reads it back through
      // `GoalService.snapshot()`, whose `bodyRows.first['weight_kg'] as num`
      // threw a `TypeError` on the `await` that sits ahead of
      // `rescheduleAll()`, `onSettingsUpdated()` and the "Import complete"
      // toast: the import applied, the OS kept the pre-restore reminder
      // schedule forever and the user was told nothing.
      //
      // The coercion happens inside `BackupService.importFromJson`, so the
      // bad value never reaches the column at all and every caller is
      // covered at once. This test still drives the whole import tail — the
      // reschedule, the callback and the toast are what it was written to
      // pin — but the expected outcome is a clean read-back rather than a
      // reported failure.
      final imported = await runImport(tester, backupJson('heavy'));

      // The rows did land — this is a completed import, not a rejected one
      // — and the poisoned cell is a number by the time it is stored.
      final rows = await DatabaseService.instance.getBodyLogs();
      expect(rows.single['weight_kg'], isA<num>());

      expect(tester.takeException(), isNull);
      expect(imported.notificationCalls, contains('zonedSchedule'),
          reason: 'the imported reminder settings must reach the OS');
      expect(imported.callbacks, 1,
          reason: 'onSettingsUpdated must still fire');
      expect(find.textContaining('Import complete'), findsOneWidget);
    });

    testWidgets(
        'the user is told how many cells the import had to rewrite, and told '
        'it in the warning styling', (tester) async {
      final imported = await runImport(tester, backupJson('heavy'));

      expect(find.textContaining('Import complete'), findsOneWidget);
      expect(find.textContaining('could not be read'), findsOneWidget,
          reason: 'a rewritten cell must not be reported as a clean import');
      expect(find.textContaining('1 value'), findsOneWidget);

      final colors = lockoutTestTheme().colorScheme;
      expect(imported.toast.backgroundColor, colors.errorContainer,
          reason: 'it must look different from a clean import, not just '
              'read differently');
    });

    testWidgets('a clean backup gets no warning and no count', (tester) async {
      final imported = await runImport(tester, backupJson(81.25));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Import complete'), findsOneWidget);
      expect(find.textContaining('could not be read'), findsNothing,
          reason: 'nothing was rewritten, so there is nothing to warn about');

      final colors = lockoutTestTheme().colorScheme;
      expect(imported.toast.backgroundColor, colors.inverseSurface);
    });

    // The screen's own `AbsorbPointer` covers the body it owns and stops
    // there; `BottomNav` is that body's sibling one level up in
    // `MainScreen`, so a tab switch mid-import landed the user on a tab
    // reading a half-restored database. This is the half of the repair that
    // belongs to the screen — raising the lock for the destructive
    // operation only, and dropping it after. That `MainScreen` obeys it is
    // pinned in `main_screen_test.dart`.
    testWidgets('a destructive import raises the nav lock and drops it again',
        (tester) async {
      final imported = await runImport(tester, backupJson(81.25));

      expect(imported.lockWhilePicking, isTrue,
          reason: 'the lock must be up while the database is being '
              'replaced, not merely after');
      expect(SettingsBody.importInFlight.value, isFalse,
          reason: 'a lock that outlives its import leaves the nav bar dead '
              'for the rest of the session');
    });

    testWidgets(
        'a throw inside the reschedule still calls back and still tells the '
        'user the import applied', (tester) async {
      // The gap the previous guard could not see. `rescheduleAll()` returns
      // early whenever `_ensureReady()` is false, and the test above it in
      // this file leaves the plugin absent, so it never reaches anything
      // that can throw. `runImport` registers the plugin and answers both
      // channels, so this one gets all the way into `_workoutReminderBody`
      // -> `ScheduleService.resolveToday()` — the database read the import
      // has just replaced the contents of.
      //
      // The throw is injected through `ScheduleService.calendarDay`, the
      // seam that class documents for exactly this (restored below). The
      // honest reason it is a seam and not poisoned backup data: every
      // model read on this path now goes through `NumericGuard` or a
      // TEXT-affinity column, so no JSON a backup file can carry still
      // reaches a cast that throws. What is left is the unenumerable class
      // — a schema the running build does not know, a disk error — and the
      // consequence of leaving it unguarded is unchanged and is what this
      // pins: the import applies, `onSettingsUpdated()` never fires and the
      // user is told nothing.
      //
      // What the OS is left holding, checked rather than assumed:
      // `rescheduleAll()` calls `await cancelAll()`
      // (`notification_service.dart:143`) BEFORE it builds any body, so by
      // the time the injected throw lands both reminder ids are already
      // cancelled. Reminders are OFF — not stale — until the next settings
      // change calls `rescheduleAll()` again. That is worse than keeping
      // the pre-restore schedule, and it is what the toast has to be judged
      // against.
      final realCalendar = ScheduleService.calendarDay;
      addTearDown(() => ScheduleService.calendarDay = realCalendar);
      ScheduleService.calendarDay =
          (_) => throw StateError('the schedule read failed');

      final imported = await runImport(
        tester,
        jsonEncode({
          'app': 'lockout',
          'schemaVersion': 2,
          'data': {
            // ROTATING, so resolution runs through `matchByRotation` and
            // therefore through the calendar above.
            'routines': [
              {
                'id': 'r1',
                'name': 'Push pull legs',
                'scheduling_mode': 'ROTATING',
                'is_active': 1,
                'created_at': '2026-01-01',
              },
            ],
            'training_days': [
              {
                'id': 'd1',
                'routine_id': 'r1',
                'name': 'Push',
                'tag': 'A',
                'order_index': 0,
              },
            ],
            'user_settings': [
              {'key': 'reminders_enabled', 'value': 'true'},
              {'key': 'active_routine_id', 'value': 'r1'},
            ],
          },
        }),
      );

      expect(tester.takeException(), isNull,
          reason: 'an unguarded await here is an unhandled async error');
      expect(imported.notificationCalls, contains('cancel'),
          reason: 'the first half of the premise: the throw lands after '
              '`cancelAll()`, so the OS has already been emptied');
      expect(imported.notificationCalls, isNot(contains('zonedSchedule')),
          reason: 'the second half: nothing was put back, so reminders are '
              'off entirely until the next settings change');
      expect(imported.callbacks, 1,
          reason: 'the import applied, so the host has to re-read it '
              'whatever the reminder schedule did');
      expect(find.textContaining('Import complete'), findsOneWidget,
          reason: 'the toast is the part that must survive — a restore the '
              'user is never told about is the worst outcome here');
      expect(find.textContaining('Reminders could not be rescheduled'),
          findsOneWidget,
          reason: 'and it must not report an unqualified success while the '
              'OS holds no reminder at all');
      expect(find.textContaining('Open Notifications to set them again'),
          findsOneWidget,
          reason: 'reminders are off, so the message has to name the repair '
              'rather than leave the user assuming the old schedule '
              'survived');
      expect(imported.toast.backgroundColor,
          lockoutTestTheme().colorScheme.errorContainer,
          reason: 'it must look different from a clean import');
    });

    // The test below replaces the seam; this one proves production holds the
    // real read, the way `widget_test.dart` pins `calendarDay`.
    test('the theme read production uses is the stored one', () {
      expect(ThemeController.readStoredChoice,
          same(ThemeController.defaultReadStoredChoice));
    });

    testWidgets(
        'a throw in the theme re-read says the fields could not be read back',
        (tester) async {
      // `reloaded` started `true` and was falsified only by the INNER catch
      // around `_loadSettings()`. `ThemeController.load()` runs AHEAD of it
      // and is the tail's first await, so a throw there jumped straight to
      // the outer catch with `_loadSettings()` never called at all: the
      // toast read "Import complete. N rows restored." while every field on
      // screen — height, age, target weight, the calorie target, the
      // reminder switches — still held its pre-import value. The one
      // sentence that would have warned the user is the one the flag
      // suppressed.
      //
      // `ThemeController.readStoredChoice` is the seam that class documents
      // for exactly this (restored below).
      final realRead = ThemeController.readStoredChoice;
      addTearDown(() => ThemeController.readStoredChoice = realRead);
      ThemeController.readStoredChoice =
          () => throw StateError('the theme read failed');

      // A clean payload, so "could not be read back" can only have come
      // from the failed re-read and not from a coerced cell.
      final imported = await runImport(tester, backupJson(81.25));

      expect(tester.takeException(), isNull,
          reason: 'an unguarded await here is an unhandled async error');
      expect(imported.callbacks, 1,
          reason: 'the rows did land, so the host still has to re-read');
      expect(find.textContaining('Import complete'), findsOneWidget,
          reason: 'the restore applied and the user must be told so');
      expect(find.textContaining('could not be read back'), findsOneWidget,
          reason: 'the screen is showing pre-import values, so reporting a '
              'clean read-back is a false report of what is on screen');
      expect(imported.toast.backgroundColor,
          lockoutTestTheme().colorScheme.errorContainer,
          reason: 'it must look different from a clean import');
    });

    // The same lock, and the one way it can still be left up: a throw out
    // of `pickAndImport()`. It guards every path it authors except the bare
    // `await DatabaseService.instance.columnTypes(table)` in
    // `importFromJson`, and its own doc comment says so — "a database that
    // will not open at all is outside that structure and **throws**".
    // Unguarded, that strands `importInFlight` (and `_busy`) true for the
    // life of the process, which is a bottom nav bar that never works
    // again: the one outcome the comment above the clear is reasoning
    // about.
    //
    // Structural, reluctantly, and the only test in this group that is.
    // Making that call throw from a test needs a seam that does not exist:
    // the throw is two singletons down (`BackupService.instance` ->
    // `DatabaseService.instance`), neither takes an injected collaborator,
    // and the one lever that would do it — an unopenable database — is out
    // of reach because `DatabaseService` caches its `Database` in a private
    // static with nothing that closes or resets it. Every other way in is
    // already guarded: the picker, the file read and the restore each come
    // back as an `ImportResult`, which is a normal return. So this pins the
    // shape instead, and the shape is the whole fix — the clear has to be
    // in a `finally` that wraps the call, not after it.
    test('the nav lock is cleared in a finally, not after the call', () {
      final source = blankComments(
        File('lib/screens/settings_screen.dart').readAsStringSync(),
      );
      final start = source.indexOf('Future<void> _import() async {');
      expect(start, isNonNegative, reason: '_import has been renamed');
      final body = source.substring(start, source.indexOf('\n  }', start));

      final raise = body.indexOf('importInFlight.value = true');
      final opened = body.indexOf('try {', raise);
      final call = body.indexOf('pickAndImport()', opened);
      final closed = body.indexOf('} finally {', call);
      final clear = body.indexOf('importInFlight.value = false', closed);

      expect(raise, isNonNegative);
      expect(opened, greaterThan(raise),
          reason: 'the lock is raised, then the call that can throw must be '
              'entered through a try');
      expect(call, greaterThan(opened),
          reason: 'the import call must be inside that try, not before it');
      expect(closed, greaterThan(call));
      expect(clear, greaterThan(closed),
          reason: 'a clear that sits after the call instead of in a finally '
              'is skipped by a throw, and the nav bar stays locked for the '
              'rest of the session');
    });
  });

  group('grouped settings sections', () {
    // Supersedes the retired "every settings group is a Card" guard: the
    // house rebuild replaces the uniform `Card` stack with `_section`'s
    // heading + grouped-list frame, so there is no longer one bounding
    // container per section to count. What the old guard actually protected
    // — that all seven groups are visually distinguishable from one another
    // — is what this asserts instead, against the heading each now carries.
    testWidgets('every settings section has its own heading', (tester) async {
      await pumpSettings(tester);

      for (final heading in [
        'Look and feel',
        'Units',
        'Training',
        'Food',
        'Notifications',
        'Data',
        'About',
      ]) {
        expect(find.text(heading), findsOneWidget, reason: heading);
      }
    });

    testWidgets('a section heading sits at 20 and its grouped list at 16',
        (tester) async {
      // House section 7, restated in `.spine/config.md`: screen margins are
      // 20 for text and headings and 16 for grouped lists and cards. The
      // scroll view used to pad itself by `screenPadding` and then let
      // `_section` pad again, so every heading landed at 40 and every group
      // at 36 — a whole screen indented past the one `today_tab.dart` sets.
      // Visible in the branch's own `docs/spine/qa/2026-10-11/02-profile.png`
      // and asserted by nothing: the device pass looked straight at it.
      await pumpSettings(tester);

      expect(
        tester.getTopLeft(find.text('Notifications')).dx,
        LockoutTheme.screenPadding,
        reason: 'a section heading is text, so it takes the 20dp margin',
      );

      final rows = find.ancestor(
        of: find.text('Daily training nudge'),
        matching: find.byType(NvGroupedList),
      );
      expect(
        tester.getTopLeft(rows).dx,
        LockoutTheme.cardPadding,
        reason: 'a grouped list takes the 16dp margin, so it sits slightly '
            'wider than its own heading rather than inside a second copy of '
            'the screen margin',
      );
    });

    testWidgets('a section extra takes the margin its own kind asks for',
        (tester) async {
      // The half the assertion above could not reach. It pins the heading
      // and the `rows` group — the two children that were already right —
      // while `_section` handed everything in `extras` the grouped-list
      // margin regardless of what it was. A paragraph, a text field and a
      // save button are text and controls, not cards, so house line 226
      // puts them on the same 20dp margin as the heading above them rather
      // than 4dp inside it.
      await pumpSettings(tester);

      expect(
        tester.getTopLeft(find.text('Applies instantly.')).dx,
        LockoutTheme.screenPadding,
        reason: 'a line of body text in a section is text',
      );
      expect(
        tester.getTopLeft(find.widgetWithText(NvTextField, 'Height (cm)')).dx,
        LockoutTheme.screenPadding,
        reason: 'and so is a field the user types into',
      );
      expect(
        tester.getTopLeft(find.widgetWithText(NvButton, 'Save height')).dx,
        LockoutTheme.screenPadding,
        reason: 'and a save button, which is neither a card nor a grouped '
            'list',
      );

      // The other half, and the reason this cannot be "move extras to 20":
      // a grouped list keeps the 16dp margin wherever it is passed in, so
      // the split is by what the child IS, not by which slot it arrived in.
      // Activity level is a real grouped list that reaches `_section`
      // through `extras`, and it has to stay flush with the "Days per week"
      // group three lines above it.
      expect(
        tester
            .getTopLeft(find.ancestor(
              of: find.text(ActivityLevel.sedentary.label),
              matching: find.byType(NvGroupedList),
            ))
            .dx,
        LockoutTheme.cardPadding,
        reason: 'an extra that is a grouped list keeps the grouped-list '
            'margin',
      );
      expect(
        tester.getTopLeft(find.text('Activity level')).dx,
        LockoutTheme.screenPadding,
        reason: 'while the caption above it is text, exactly as the section '
            'heading above the first group is',
      );
    });

    testWidgets('a tappable row clears the 48dp touch target', (tester) async {
      // An accent swatch draws no text, so the only handle on it is the
      // semantics label that makes it usable in the first place; enabled
      // before the pump so the first semantics tree already carries it.
      final semantics = tester.ensureSemantics();
      await pumpSettings(tester);

      final switchTile = tester.getSize(find.widgetWithText(
        NvSwitchRow,
        'Enable nutrition tab',
      ));
      expect(switchTile.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));

      final importButton =
          tester.getSize(find.byKey(const Key('importBackupButton')));
      expect(importButton.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));

      // The training-days stepper now lives behind a sheet (section 8
      // prefers a sheet to a dialog for a choice); open it to reach its two
      // buttons, which are sized by `NvIconButton` rather than by the
      // component theme the two checks above already pin — so they need
      // their own assertion.
      await tester.tap(find.text('Days per week'));
      await settle(tester);

      final decrementButton = tester.getSize(
        find.widgetWithIcon(NvIconButton, Icons.remove_circle_outline),
      );
      expect(decrementButton.width, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
      expect(decrementButton.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));

      final incrementButton = tester.getSize(
        find.widgetWithIcon(NvIconButton, Icons.add_circle_outline),
      );
      expect(incrementButton.width, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
      expect(incrementButton.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));

      // Both ends announce what they do. The framework `IconButton` pair
      // these replaced carried no tooltip and no label at all, so TalkBack
      // reached a stepper of two unnamed buttons; `NvIconButton` makes the
      // description a required parameter.
      expect(find.bySemanticsLabel('One day fewer'), findsOneWidget);
      expect(find.bySemanticsLabel('One day more'), findsOneWidget);

      // Dismiss the sheet by tapping its scrim before checking what sits
      // behind it.
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);

      for (final accent in LockoutAccent.all) {
        final size = tester.getSize(find.bySemanticsLabel(accent.name));
        expect(size.width, greaterThanOrEqualTo(LockoutTheme.minTouchTarget),
            reason: accent.key);
        expect(size.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget),
            reason: accent.key);
      }

      semantics.dispose();
    });

    testWidgets(
        'the destructive ink sits on the confirmation, not the trigger that '
        'only offers it',
        (tester) async {
      // Every shipped appearance happens to set `danger` to the same value as
      // `ColorScheme.error`, so a test against the shipped theme could not
      // tell the two roles apart. This one overrides `danger` to a sentinel
      // that no other role holds.
      const sentinel = Color(0xFF00FF00);
      final theme = LockoutTheme.build(
        colors: darkAppearance.colors,
        semantics:
            darkAppearance.semantics.copyWith(danger: sentinel),
      );
      await pumpSettings(tester, theme: theme);
      final colors = theme.colorScheme;

      // The Import row only offers to replace every row on the device — it
      // does not do it — so it carries `NvButtonVariant.outlined`'s neutral
      // label, not `danger`. Per the design doc's button table, `outlined`
      // is for "neutral alternatives" and `danger` is reserved for the
      // control that actually fires ("Remove, Delete"): here, the dialog's
      // confirm button.
      final importLabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('importBackupButton')),
          matching: find.text('Import backup JSON'),
        ),
      );
      expect(
        importLabel.style?.color,
        isNot(sentinel),
        reason: 'the trigger is a neutral alternative, not the destructive '
            'action itself',
      );

      await tester.tap(find.byKey(const Key('importBackupButton')));
      await settle(tester);

      expect(find.text('Replace all data?'), findsOneWidget,
          reason: 'the destructive action stays behind its confirmation');

      // `semantics.danger`, not `colorScheme.error`: this is a destructive
      // confirmation, which is the role `LockoutSemantics` reserves `danger`
      // for (today_tab's discard dialog and log_tab's DELETE ENTRY already
      // read it that way).
      final confirmLabel = tester.widget<Text>(find.text('Choose file'));
      expect(confirmLabel.style?.color, sentinel);
      expect(sentinel, isNot(colors.error));
    });

    testWidgets('both appearance axes sit under a Look and feel caption',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSettings(tester);
      expect(find.text('Look and feel'), findsOneWidget);

      // This would still pass with the whole picker deleted, unless it also
      // asserts the controls its own name promises are actually there —
      // both axes, since the caption covers the brightness segments as well
      // as the swatches.
      for (final label in ['System', 'Light', 'Dark']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Accent'), findsOneWidget);
      for (final accent in LockoutAccent.all) {
        expect(find.bySemanticsLabel(accent.name), findsOneWidget,
            reason: accent.key);
      }

      semantics.dispose();
    });
  });

  group('settings sections as grouped lists', () {
    testWidgets('every settings section is a grouped list, not a card',
        (tester) async {
      await tester.pumpWidget(hostedProfileTab());
      await settle(tester);

      expect(find.byType(NvGroupedList), findsWidgets);
      expect(find.byType(LockoutCard), findsNothing,
          reason: 'grouped lists replace the stack of uniform cards');
    });

    testWidgets('a section caption is sentence case', (tester) async {
      await tester.pumpWidget(hostedProfileTab());
      await settle(tester);

      expect(find.text('Look and feel'), findsOneWidget);
      expect(find.text('LOOK AND FEEL'), findsNothing);
    });
  });

  group('training card commits what it owns', () {
    /// Before this fix, `training_days_per_week` and `activity_level` had no
    /// writer of their own: only `_saveGoalAndRecalculate`, behind the Food
    /// card's "Calculate my target" button, persisted them.
    /// `MainScreen._refreshVisibleTab` calls `ProfileTabState.reload()` on
    /// every tab switch, and `reload()` re-reads every field from the
    /// database — so adjusting the stepper or the activity radio and then
    /// switching tabs silently reverted the change with no feedback.
    testWidgets(
        'the training-days stepper and activity radio survive the reload '
        'MainScreen triggers on every tab switch', (tester) async {
      final key = GlobalKey<ProfileTabState>();
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: ProfileTab(key: key, onSettingsUpdated: () {}),
        ),
      );
      await settle(tester);

      // Default is 4; the stepper now lives behind a sheet (section 8
      // prefers a sheet to a dialog for a choice).
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.text('Days per week'));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await settle(tester);

      // Dismiss the sheet by tapping its scrim.
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      expect(find.text('5'), findsOneWidget);

      // Default activity is Moderately Active; choose a different one.
      await tester.tap(find.text(ActivityLevel.high.label));
      await settle(tester);

      // The tab switch itself: MainScreen calls this on every tab change.
      await key.currentState!.reload();
      await settle(tester);

      expect(find.text('5'), findsOneWidget,
          reason: 'the stepper reverted to the database value on reload');
      expect(
        await DatabaseService.instance
            .getSetting('training_days_per_week', defaultValue: ''),
        '5',
      );
      expect(
        await DatabaseService.instance
            .getSetting('activity_level', defaultValue: ''),
        ActivityLevel.high.name,
      );
    });
  });

  group('activity radio refreshes the displayed plan without a reload', () {
    /// `_setActivity` used to persist `activity_level` and stop there.
    /// `_plan` was only ever assigned in `_loadSettings` and
    /// `_saveGoalAndRecalculate`, so `GoalSnapshot.calorieTarget` — and every
    /// tab that reads it — recomputed against the new multiplier the instant
    /// the radio was tapped, while this screen's own "Daily target" block
    /// kept showing the pre-tap figure until something reloaded it: a
    /// same-screen contradiction.
    testWidgets(
        'tapping a different activity radio updates "Daily target" in place',
        (tester) async {
      await seedCalculablePlan();
      var updated = false;
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: SettingsScreen(onSettingsUpdated: () => updated = true),
        ),
      );
      await settle(tester);

      // The one Text in the tree of the shape "<int> kcal" is the headline
      // figure inside the "Daily target" container; `_calorieCtrl`'s field
      // is labelled "Daily calorie target (kcal)" and never matches this.
      final kcalFinder = find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^\d+ kcal$').hasMatch(w.data ?? ''),
      );
      expect(kcalFinder, findsOneWidget);
      final before = tester.widget<Text>(kcalFinder).data!;

      // Default activity is Moderately Active; choose a different one.
      await tester.tap(find.text(ActivityLevel.high.label));
      await settle(tester);

      final after = tester.widget<Text>(kcalFinder).data!;
      expect(
        after,
        isNot(before),
        reason: 'the "Daily target" figure did not follow the new activity '
            'multiplier without a reload',
      );
      expect(
        updated,
        isFalse,
        reason: '_setActivity must not call onSettingsUpdated: that chain '
            'reloads every text controller from the database and would '
            'clobber unsaved typing in another card',
      );
    });
  });

  group('a save in one card does not discard typing in another', () {
    /// The loop the review traced: a card's save calls
    /// `widget.onSettingsUpdated()`, which is `MainScreen._loadSettings` ->
    /// `_refreshVisibleTab()` -> `ProfileTabState.reload()` ->
    /// `SettingsBodyState.reload()` -> `_loadSettings()`. The screen asks the
    /// app to refresh and the app refreshes the screen that asked, over the
    /// top of whatever the user was typing. Wired here exactly as
    /// `MainScreen` wires it, because the defect is in the wiring.
    Future<GlobalKey<ProfileTabState>> pumpHostedProfile(
        WidgetTester tester) async {
      final key = GlobalKey<ProfileTabState>();
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: ProfileTab(
            key: key,
            onSettingsUpdated: () => key.currentState?.reload(),
          ),
        ),
      );
      await settle(tester);
      return key;
    }

    Future<void> type(
        WidgetTester tester, String label, String text) async {
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(NvTextField, label),
          matching: find.byType(TextField),
        ),
        text,
      );
      await tester.pump();
    }

    testWidgets('unsaved typing survives the save of another card',
        (tester) async {
      await pumpHostedProfile(tester);

      await type(tester, 'Age', '41');
      await type(tester, 'Timeframe (weeks)', '9');

      // A different card entirely, with its own writer and its own button.
      await tester.tap(find.text('Save height'));
      await settle(tester);

      expect(fieldText(tester, 'Age'), '41',
          reason: 'saving the height card re-read every field from the '
              'database and dropped what the user was typing');
      expect(fieldText(tester, 'Timeframe (weeks)'), '9');

      // Flush the toast's auto-dismiss Timer before teardown.
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a field the user has not touched still takes the value the '
        'database now holds', (tester) async {
      final key = await pumpHostedProfile(tester);

      // The other half of the contract, and the reason the fix compares
      // against the last loaded value rather than simply refusing to write:
      // an import replaces every row, and every field the user is not in
      // the middle of editing must follow it.
      await DatabaseService.instance.saveSetting('calorie_target', '2345');
      await key.currentState!.reload();
      await settle(tester);

      expect(fieldText(tester, 'Daily calorie target (kcal)'), '2345');
    });

    // The same clobber, on the state that is not text. A controller is only
    // one way a card holds an unsaved choice: the nutrition switch, the
    // height unit and the sex control are all set by one widget and written
    // by a button somewhere else, so until that button is pressed a reload
    // overwrites them exactly the way it used to overwrite typing. The
    // reminder toggles, the activity radio and the days stepper are safe for
    // a different reason — each persists the instant it changes — so they
    // are deliberately not in this list.
    testWidgets('an unsaved switch survives the save of another card',
        (tester) async {
      await pumpHostedProfile(tester);

      final toggle = find.widgetWithText(NvSwitchRow, 'Enable nutrition tab');
      expect(tester.widget<NvSwitchRow>(toggle).value, isTrue);

      await tester.tap(find.descendant(of: toggle, matching: find.byType(Switch)));
      await settle(tester);
      expect(tester.widget<NvSwitchRow>(toggle).value, isFalse);

      await tester.tap(find.text('Save height'));
      await settle(tester);

      expect(tester.widget<NvSwitchRow>(toggle).value, isFalse,
          reason: 'saving the height card re-read food_tab_enabled and threw '
              'away a toggle the user had not saved yet');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a switch the user has not touched still follows the database',
        (tester) async {
      final key = await pumpHostedProfile(tester);

      await DatabaseService.instance.saveSetting('food_tab_enabled', 'false');
      await key.currentState!.reload();
      await settle(tester);

      expect(
        tester
            .widget<NvSwitchRow>(
                find.widgetWithText(NvSwitchRow, 'Enable nutrition tab'))
            .value,
        isFalse,
      );
    });

    /// The sex control's current selection, read off the widget it was
    /// handed to rather than off whichever label looks highlighted.
    Sex selectedSex(WidgetTester tester) => tester
        .widget<NvSegmentedButton<Sex>>(find.byType(NvSegmentedButton<Sex>))
        .selected;

    // --- the other half of the dirty check: advancing the baseline ---
    //
    // `_loadInto` refuses to overwrite a field whose text has moved away
    // from what was last loaded into it. That is only half a rule: unless
    // every path that *persists* a field also moves that field's baseline
    // onto what it has just written, the field counts as edited for the
    // rest of the session. It then stops following the database — an
    // import lands and the field keeps showing the old value — and the
    // next save writes that stale value straight back over the imported
    // row. The three tests below pin the two triggers (a save, and a unit
    // switch that re-renders the same height through `_resolveHeightCm`)
    // and the data loss at the end of them.

    testWidgets('a height field that has been saved still follows a later '
        'import', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await type(tester, 'Height (cm)', '180');
      await tester.tap(find.text('Save height'));
      await settle(tester);

      // What an import does: the row changes under a field the user is no
      // longer editing, because the edit was committed.
      await DatabaseService.instance.saveSetting('height_cm', '150.00');
      await tab.currentState!.reload();
      await settle(tester);

      expect(fieldText(tester, 'Height (cm)'), '150',
          reason: 'the save left the baseline on the value loaded before '
              'it, so the field read as unsaved typing forever after and '
              'stopped following the database');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a unit round trip does not stop the height field following '
        'the database', (tester) async {
      final tab = await pumpHostedProfile(tester);

      // No typing at all, which is what makes this the case a user reaches
      // by accident. The round trip re-renders 175 as "175.0" —
      // `Units.feetInchesToCm(5, 8.9)` is 175.006 — and that one character
      // of difference was enough to mark all three height controllers as
      // edited for the rest of the session.
      await tester.tap(find.text('Feet / inches'));
      await settle(tester);
      await tester.tap(find.text('Centimetres'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('height_cm', '150.00');
      await tab.currentState!.reload();
      await settle(tester);

      expect(fieldText(tester, 'Height (cm)'), '150',
          reason: 'two taps on the unit control, with nothing typed, left '
              'the height field pinned to its old value');
    });

    testWidgets('a height left over from a unit switch is not written back '
        'over an import', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await tester.tap(find.text('Feet / inches'));
      await settle(tester);
      await tester.tap(find.text('Centimetres'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('height_cm', '150.00');
      await tab.currentState!.reload();
      await settle(tester);

      await tester.tap(find.text('Save height'));
      await settle(tester);

      expect(
        await DatabaseService.instance
            .getSetting('height_cm', defaultValue: ''),
        '150.00',
        reason: 'a field nobody edited overwrote the imported height with '
            'the value it was still showing',
      );

      await tester.pump(const Duration(seconds: 6));
    });

    // The same rule on the other two save paths. Each is its own test
    // because each advances its own set of baselines: a fix that remembers
    // the card it was reported against and forgets the other two leaves the
    // defect exactly where it was.

    testWidgets('a calorie target that has been saved still follows a later '
        'import', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await type(tester, 'Daily calorie target (kcal)', '1800');
      await tester.tap(find.text('Save food settings'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('calorie_target', '2345');
      await tab.currentState!.reload();
      await settle(tester);

      expect(fieldText(tester, 'Daily calorie target (kcal)'), '2345');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('an age saved by Calculate my target still follows a later '
        'import', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await type(tester, 'Age', '41');
      await tester.tap(find.text('Calculate my target'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('age', '30');
      await tab.currentState!.reload();
      await settle(tester);

      expect(fieldText(tester, 'Age'), '30');

      await tester.pump(const Duration(seconds: 12));
    });

    // --- the two `_loadValue` slots that are not the nutrition switch ---
    //
    // Neutering `_loadValue` reddened only the `food_tab_enabled` switch:
    // the sex control and the height unit are held exactly the same way —
    // set by one widget, written by a button somewhere else — and had no
    // test at all, in either direction.

    testWidgets('an unsaved sex choice survives the save of another card',
        (tester) async {
      await pumpHostedProfile(tester);
      expect(selectedSex(tester), Sex.male);

      await tester.tap(find.text('Female'));
      await settle(tester);
      expect(selectedSex(tester), Sex.female);

      await tester.tap(find.text('Save height'));
      await settle(tester);

      expect(selectedSex(tester), Sex.female,
          reason: 'saving the height card re-read sex and threw away a '
              'choice the user had not saved yet');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a sex the user has not touched still follows the database',
        (tester) async {
      final tab = await pumpHostedProfile(tester);

      await DatabaseService.instance.saveSetting('sex', 'female');
      await tab.currentState!.reload();
      await settle(tester);

      expect(selectedSex(tester), Sex.female);
    });

    testWidgets('an unsaved height unit survives the save of another card',
        (tester) async {
      await pumpHostedProfile(tester);

      await tester.tap(find.text('Feet / inches'));
      await settle(tester);

      // A different card entirely — the unit is only persisted by this
      // card's own save button and by "Calculate my target".
      await tester.tap(find.text('Save food settings'));
      await settle(tester);

      expect(find.widgetWithText(NvTextField, 'Height (ft)'), findsOneWidget,
          reason: 'saving the food card re-read height_unit and dropped the '
              'unit the user had just chosen');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a height unit the user has not touched still follows the '
        'database', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await DatabaseService.instance.saveSetting('height_unit', 'ft');
      await tab.currentState!.reload();
      await settle(tester);

      expect(find.widgetWithText(NvTextField, 'Height (ft)'), findsOneWidget);
    });

    // --- and the `_markSaved` call on each of the two paths that persist
    // one of those slots ---

    testWidgets('a height unit saved from the units card follows a later '
        'import', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await tester.tap(find.text('Feet / inches'));
      await settle(tester);
      await tester.tap(find.text('Save height'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('height_unit', 'cm');
      await tab.currentState!.reload();
      await settle(tester);

      expect(find.widgetWithText(NvTextField, 'Height (cm)'), findsOneWidget,
          reason: 'the unit was saved, so it is no longer an unsaved choice '
              'and must follow an import like every other field');

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('a height unit saved by Calculate my target follows a later '
        'import', (tester) async {
      final tab = await pumpHostedProfile(tester);

      await tester.tap(find.text('Feet / inches'));
      await settle(tester);
      await tester.tap(find.text('Calculate my target'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('height_unit', 'cm');
      await tab.currentState!.reload();
      await settle(tester);

      expect(find.widgetWithText(NvTextField, 'Height (cm)'), findsOneWidget);

      await tester.pump(const Duration(seconds: 12));
    });

    testWidgets('a sex saved by Calculate my target follows a later import',
        (tester) async {
      final tab = await pumpHostedProfile(tester);

      await tester.tap(find.text('Female'));
      await settle(tester);
      await tester.tap(find.text('Calculate my target'));
      await settle(tester);

      await DatabaseService.instance.saveSetting('sex', 'male');
      await tab.currentState!.reload();
      await settle(tester);

      expect(selectedSex(tester), Sex.male);

      await tester.pump(const Duration(seconds: 12));
    });
  });

  group('every control says what it is', () {
    // Five rows reading Sedentary..Athlete sat directly under "Days per
    // week" inside the Training group with nothing naming the choice — in
    // docs/spine/qa/2026-10-11/03-profile-scroll1.png they read as peers of
    // that row, separated only by a "Selected" badge. The sex control was
    // two buttons with no subject at all.
    testWidgets('the activity choice and the sex choice are both named',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('Activity level'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);

      // A caption is only a caption if it sits with what it names: above the
      // control, and below whatever it does not name.
      final activityCaption =
          tester.getBottomLeft(find.text('Activity level')).dy;
      expect(
        activityCaption,
        greaterThan(tester.getBottomLeft(find.text('Days per week')).dy),
        reason: 'the caption must not read as part of the stepper row above '
            'it',
      );
      expect(
        activityCaption,
        lessThanOrEqualTo(
            tester.getTopLeft(find.text(ActivityLevel.values.first.label)).dy),
        reason: 'the caption must sit above the options it names',
      );

      final sexCaption = tester.getBottomLeft(find.text('Sex')).dy;
      expect(
        sexCaption,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Male')).dy),
      );
      expect(
        sexCaption,
        greaterThan(tester.getBottomLeft(find.text('Target weight (kg)')).dy),
      );
    });
  });

  group('reminders-expanded branch', () {
    /// The removed neubrutalist suite seeded `reminders_enabled=true` plus a
    /// rate-capped plan and asserted the reminder time row, the streak
    /// switch, the test-notification button and the clamp warning all
    /// rendered. The M3 rewrite dropped every one of those assertions, so
    /// none of that newly-rewritten subtree — the `_remindersEnabled == true`
    /// branch of `_buildNotificationsCard`, and `plan.warning`'s container in
    /// `_buildFoodCard` — was ever built by any test. Rendered at 360dp so
    /// this also stands in for finding 5's overflow guard on that branch.
    testWidgets(
        'reminder time, streak warning, test notification and the rate-cap '
        'warning all render together', (tester) async {
      await seedCalculablePlan();
      await DatabaseService.instance.saveSetting('reminders_enabled', 'true');

      await pumpSettingsNarrow(tester);

      expect(find.text('Reminder time'), findsOneWidget);
      expect(find.text('Send test notification'), findsOneWidget);
      expect(find.text('Streak warning at 21:00'), findsOneWidget);
      expect(find.text('Daily target'), findsOneWidget);
      expect(find.textContaining('Target eased to a safe rate'), findsOneWidget);

      expect(tester.takeException(), isNull,
          reason: 'no widget in this branch may overflow at 360dp');
    });
  });
}

/// A picked file whose bytes the test supplies. `PlatformFile` is
/// `abstract base`, so a subclass outside its own library must be `final`.
final class _StubBackupFile extends PlatformFile {
  _StubBackupFile(String json) : _bytes = Uint8List.fromList(utf8.encode(json));

  final Uint8List _bytes;

  @override
  String get name => 'lockout-backup.json';

  @override
  Uri get uri => Uri.parse('file:///lockout-backup.json');

  // `Never` is a subtype of `XFile`, so this satisfies the override without
  // importing cross_file. `pickAndImport` reads bytes, never the XFile.
  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream<Uint8List>.value(_bytes);
}

/// Stands in for the OS file picker, which cannot open under `flutter test`.
/// Extending `FilePickerPlatform` passes its own token, so no mock mixin is
/// needed; the test restores the real instance in a tear-down.
class _StubFilePicker extends FilePickerPlatform {
  _StubFilePicker(this.json);

  final String json;

  /// The state of [SettingsBody.importInFlight] at the one moment the lock
  /// is meant to be up: inside `pickAndImport`, with the database about to
  /// be replaced. Null until the picker is asked for a file.
  bool? lockWhilePicking;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    lockWhilePicking = SettingsBody.importInFlight.value;
    return _StubBackupFile(json);
  }
}
