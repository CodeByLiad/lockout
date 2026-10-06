import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/theme_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

Future<void> _loadWithSetting(String? value) async {
  await wipeDatabaseAndReseed(DatabaseService.instance);
  if (value != null) {
    await DatabaseService.instance.saveSetting('theme_key', value);
  }
  ThemeController.instance.resetForTest();
  await ThemeController.instance.load();
}

/// Makes every write to `theme_key` fail, and only that key.
///
/// The same aborting-trigger technique `theme_picker_test.dart` and
/// `database_service_test.dart` use: it is the one way to produce what a
/// locked, read-only or full database does without mocking
/// `DatabaseService`, which is a singleton with no injection seam. Scoped to
/// one key so the seeding each `setUp` does still works, and dropped in a
/// teardown so it cannot follow the process into another suite.
Future<void> _failEveryThemeWrite() async {
  final database = await DatabaseService.instance.database;
  Future<void> drop() =>
      database.execute('DROP TRIGGER IF EXISTS test_fail_theme_key');
  await drop();
  addTearDown(drop);
  await database.execute(
    "CREATE TRIGGER test_fail_theme_key BEFORE INSERT ON user_settings "
    "WHEN NEW.key = 'theme_key' "
    "BEGIN SELECT RAISE(ABORT, 'rejected by test trigger'); END;",
  );
}

/// Stops `getSetting` resolving, by moving the table it reads out from under
/// it. A read failure has to stay loud, and no trigger fires on a SELECT, so
/// the table itself is renamed aside and put back in a teardown.
Future<void> _failEverySettingRead() async {
  final database = await DatabaseService.instance.database;
  await database
      .execute('ALTER TABLE user_settings RENAME TO user_settings_hidden');
  addTearDown(() => database
      .execute('ALTER TABLE user_settings_hidden RENAME TO user_settings'));
}

void main() {
  // The no-isolate factory against an in-memory path, matching every other
  // suite here. The isolate-backed factory arms a 10s transaction timeout
  // inside fake_async that a bounded pump never lives long enough to cancel.
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
    ThemeController.instance.resetForTest();
  });

  // The shared serial runner reuses one process, so a selection left applied
  // here would follow every later suite into its own setUp.
  tearDown(() => ThemeController.instance.resetForTest());

  group('migration from the six retired schemes', () {
    const cases = <String, (LockoutBrightnessChoice, LockoutAccent)>{
      'graphite': (LockoutBrightnessChoice.dark, LockoutAccent.steel),
      'paper': (LockoutBrightnessChoice.light, LockoutAccent.steel),
      'ember': (LockoutBrightnessChoice.dark, LockoutAccent.coral),
      'linen': (LockoutBrightnessChoice.light, LockoutAccent.coral),
      'indigo': (LockoutBrightnessChoice.dark, LockoutAccent.violet),
      'frost': (LockoutBrightnessChoice.light, LockoutAccent.teal),
      'dynamic': (LockoutBrightnessChoice.system, LockoutAccent.lime),
    };

    cases.forEach((key, expected) {
      test('$key migrates to ${expected.$1} + ${expected.$2.key}', () async {
        await _loadWithSetting(key);
        expect(ThemeController.instance.brightnessChoice, expected.$1);
        expect(ThemeController.instance.accent, expected.$2);
      });
    });

    /// The pre-Jinatra keys migrated in two hops: `schemes.dart` mapped them
    /// onto one of the six, and the six are mapped here. Deleting
    /// `schemes.dart` deleted the first hop, so these have to land in one.
    /// Without them every install still carrying one silently loses its
    /// choice on upgrade — the exact outcome `no_legacy_theme_test.dart`'s
    /// allowlist comment was written to prevent.
    const ancient = <String, (LockoutBrightnessChoice, LockoutAccent)>{
      'carbon_lime': (LockoutBrightnessChoice.dark, LockoutAccent.steel),
      'midnight_cyan': (LockoutBrightnessChoice.dark, LockoutAccent.violet),
      'ash_amber': (LockoutBrightnessChoice.dark, LockoutAccent.coral),
      'void_magenta': (LockoutBrightnessChoice.dark, LockoutAccent.steel),
      'jinatra_cream': (LockoutBrightnessChoice.light, LockoutAccent.steel),
      'paper_press': (LockoutBrightnessChoice.light, LockoutAccent.steel),
      'mint_lab': (LockoutBrightnessChoice.light, LockoutAccent.teal),
      'sunblock': (LockoutBrightnessChoice.light, LockoutAccent.coral),
    };

    ancient.forEach((key, expected) {
      test('the pre-Jinatra key $key still migrates in one hop', () async {
        await _loadWithSetting(key);
        expect(ThemeController.instance.brightnessChoice, expected.$1,
            reason: key);
        expect(ThemeController.instance.accent, expected.$2, reason: key);
      });
    });

    test('a junk value falls back without clearing the setting', () async {
      await _loadWithSetting('not-a-theme');
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.system);
      expect(ThemeController.instance.accent, LockoutAccent.lime);

      final stored = await DatabaseService.instance
          .getSetting('theme_key', defaultValue: '');
      expect(stored, isNotEmpty,
          reason: 'migration must rewrite the setting, never clear it');
    });

    test('an absent setting lands on the fresh-install default', () async {
      await _loadWithSetting(null);
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.system);
      expect(ThemeController.instance.accent, LockoutAccent.lime);
    });

    test('a migrated value is written back in the new format', () async {
      await _loadWithSetting('indigo');
      final stored = await DatabaseService.instance
          .getSetting('theme_key', defaultValue: '');
      expect(stored, 'dark|violet');
    });

    test('the new format round-trips', () async {
      await _loadWithSetting('light|teal');
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.light);
      expect(ThemeController.instance.accent, LockoutAccent.teal);
    });
  });

  group('the two axes move independently', () {
    test('changing the accent leaves the brightness alone', () async {
      await _loadWithSetting('dark|lime');
      await ThemeController.instance.selectAccent(LockoutAccent.coral);
      expect(ThemeController.instance.accent, LockoutAccent.coral);
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.dark);
    });

    test('changing the brightness leaves the accent alone', () async {
      await _loadWithSetting('dark|coral');
      await ThemeController.instance
          .selectBrightness(LockoutBrightnessChoice.light);
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.light);
      expect(ThemeController.instance.accent, LockoutAccent.coral);
    });

    test('selecting the value already in force does not notify', () async {
      await _loadWithSetting('dark|coral');
      var notifications = 0;
      void listener() => notifications++;
      ThemeController.instance.addListener(listener);
      await ThemeController.instance.selectAccent(LockoutAccent.coral);
      ThemeController.instance.removeListener(listener);
      expect(notifications, 0);
    });

    test('both axes persist in one setting', () async {
      await _loadWithSetting('system|lime');
      await ThemeController.instance
          .selectBrightness(LockoutBrightnessChoice.dark);
      await ThemeController.instance.selectAccent(LockoutAccent.violet);

      expect(
        await DatabaseService.instance
            .getSetting('theme_key', defaultValue: ''),
        'dark|violet',
      );
    });
  });

  group('two selections in flight', () {
    test('the last tap wins when a user changes their mind mid-write',
        () async {
      await _loadWithSetting('light|lime');

      // No await on the first: it is still writing when the second lands,
      // which is exactly the "tapped the wrong one, tap back" gesture.
      final first = ThemeController.instance.selectAccent(LockoutAccent.teal);
      final second = ThemeController.instance.selectAccent(LockoutAccent.coral);
      await Future.wait([first, second]);

      expect(ThemeController.instance.accent, LockoutAccent.coral);
      final stored = await DatabaseService.instance
          .getSetting('theme_key', defaultValue: '');
      expect(stored, 'light|coral',
          reason: 'the second selection must not be swallowed by the guard');
    });

    test('tapping back to the current value mid-write is not a no-op',
        () async {
      await _loadWithSetting('light|lime');

      final away = ThemeController.instance.selectAccent(LockoutAccent.teal);
      final back = ThemeController.instance.selectAccent(LockoutAccent.lime);
      await Future.wait([away, back]);

      expect(ThemeController.instance.accent, LockoutAccent.lime);
      final stored = await DatabaseService.instance
          .getSetting('theme_key', defaultValue: '');
      expect(stored, 'light|lime');
    });

    test('the axes do not clobber each other when interleaved', () async {
      await _loadWithSetting('light|lime');

      final a = ThemeController.instance.selectAccent(LockoutAccent.violet);
      final b = ThemeController.instance
          .selectBrightness(LockoutBrightnessChoice.dark);
      await Future.wait([a, b]);

      expect(ThemeController.instance.accent, LockoutAccent.violet);
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.dark);
      final stored = await DatabaseService.instance
          .getSetting('theme_key', defaultValue: '');
      expect(stored, 'dark|violet');
    });
  });

  group('themes', () {
    test('both light and dark themes are always offered', () async {
      await _loadWithSetting('system|lime');
      expect(ThemeController.instance.lightTheme, isA<ThemeData>());
      expect(ThemeController.instance.darkTheme, isA<ThemeData>());
      expect(ThemeController.instance.themeMode, ThemeMode.system);
    });

    test('an explicit brightness pins themeMode', () async {
      await _loadWithSetting('dark|lime');
      expect(ThemeController.instance.themeMode, ThemeMode.dark);
      await ThemeController.instance
          .selectBrightness(LockoutBrightnessChoice.light);
      expect(ThemeController.instance.themeMode, ThemeMode.light);
    });

    test('the accent reaches the built theme', () async {
      await _loadWithSetting('dark|teal');
      expect(ThemeController.instance.darkTheme.colorScheme.primary,
          LockoutAccent.teal.accent);
    });

    test('each theme carries its own brightness', () async {
      await _loadWithSetting('system|lime');
      expect(ThemeController.instance.lightTheme.brightness, Brightness.light);
      expect(ThemeController.instance.darkTheme.brightness, Brightness.dark);
    });
  });

  // `main.dart` awaits `load()` before `runApp`, so anything that escapes it
  // happens with no widget tree to report it in: a blank screen on every
  // launch and no way back from inside the app. The write-back is only an
  // optimisation — the choice is already in memory by the time it runs — so
  // losing it costs one re-migration next launch, not the app.
  group('load() survives a write it cannot make', () {
    test('a migration whose write-back fails still applies the choice',
        () async {
      await wipeDatabaseAndReseed(DatabaseService.instance);
      await DatabaseService.instance.saveSetting('theme_key', 'indigo');
      await _failEveryThemeWrite();
      ThemeController.instance.resetForTest();

      await expectLater(ThemeController.instance.load(), completes);
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.dark);
      expect(ThemeController.instance.accent, LockoutAccent.violet);
    });

    test('a fresh install whose first write fails still boots', () async {
      await wipeDatabaseAndReseed(DatabaseService.instance);
      await _failEveryThemeWrite();
      ThemeController.instance.resetForTest();

      await expectLater(ThemeController.instance.load(), completes);
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.system);
      expect(ThemeController.instance.accent, LockoutAccent.lime);
    });

    test('the un-written migration simply runs again on the next launch',
        () async {
      await wipeDatabaseAndReseed(DatabaseService.instance);
      await DatabaseService.instance.saveSetting('theme_key', 'indigo');
      final database = await DatabaseService.instance.database;
      await _failEveryThemeWrite();
      ThemeController.instance.resetForTest();
      await ThemeController.instance.load();

      // The old value is left intact rather than cleared, so the next launch
      // migrates it again — this time against a writable database.
      expect(await DatabaseService.instance.getSetting('theme_key'), 'indigo');

      await database.execute('DROP TRIGGER IF EXISTS test_fail_theme_key');
      ThemeController.instance.resetForTest();
      await ThemeController.instance.load();
      expect(
        await DatabaseService.instance.getSetting('theme_key'),
        'dark|violet',
      );
    });

    test('a failed read still escapes, because nothing can be resolved '
        'without it', () async {
      await wipeDatabaseAndReseed(DatabaseService.instance);
      await _failEverySettingRead();
      ThemeController.instance.resetForTest();

      await expectLater(ThemeController.instance.load(), throwsA(anything));
    });
  });

  // Committing the field before the write leaves the controller claiming a
  // choice the database refused, with no `notifyListeners` to repaint the app
  // to match — and the equality guard then swallows the retry.
  group('a selection that cannot be persisted changes nothing', () {
    test('selectAccent leaves the accent as stored when the write fails',
        () async {
      await _loadWithSetting('dark|lime');
      await _failEveryThemeWrite();

      await expectLater(
        ThemeController.instance.selectAccent(LockoutAccent.teal),
        throwsA(anything),
      );
      expect(ThemeController.instance.accent, LockoutAccent.lime);
      expect(
          await DatabaseService.instance.getSetting('theme_key'), 'dark|lime');
    });

    test('selectBrightness leaves the brightness as stored when the write '
        'fails', () async {
      await _loadWithSetting('dark|lime');
      await _failEveryThemeWrite();

      await expectLater(
        ThemeController.instance
            .selectBrightness(LockoutBrightnessChoice.light),
        throwsA(anything),
      );
      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.dark);
      expect(
          await DatabaseService.instance.getSetting('theme_key'), 'dark|lime');
    });

    test('a failed selection does not notify, so nothing repaints a choice '
        'the database refused', () async {
      await _loadWithSetting('dark|lime');
      await _failEveryThemeWrite();

      var notifications = 0;
      void listener() => notifications++;
      ThemeController.instance.addListener(listener);
      await expectLater(
        ThemeController.instance.selectAccent(LockoutAccent.teal),
        throwsA(anything),
      );
      ThemeController.instance.removeListener(listener);
      expect(notifications, 0);
    });

    test('tapping the same accent again retries rather than no-opping',
        () async {
      await _loadWithSetting('dark|lime');
      final database = await DatabaseService.instance.database;
      await _failEveryThemeWrite();

      await expectLater(
        ThemeController.instance.selectAccent(LockoutAccent.teal),
        throwsA(anything),
      );

      // The second tap, against a writable database. Had the first tap
      // committed the field, the equality guard would return early here and
      // the user would be stuck with a theme that never applies and a toast
      // that never comes back.
      await database.execute('DROP TRIGGER IF EXISTS test_fail_theme_key');
      var notifications = 0;
      void listener() => notifications++;
      ThemeController.instance.addListener(listener);
      await ThemeController.instance.selectAccent(LockoutAccent.teal);
      ThemeController.instance.removeListener(listener);

      expect(notifications, 1);
      expect(ThemeController.instance.accent, LockoutAccent.teal);
      expect(
          await DatabaseService.instance.getSetting('theme_key'), 'dark|teal');
    });

    test('tapping the same brightness again retries rather than no-opping',
        () async {
      await _loadWithSetting('dark|lime');
      final database = await DatabaseService.instance.database;
      await _failEveryThemeWrite();

      await expectLater(
        ThemeController.instance
            .selectBrightness(LockoutBrightnessChoice.light),
        throwsA(anything),
      );

      await database.execute('DROP TRIGGER IF EXISTS test_fail_theme_key');
      await ThemeController.instance
          .selectBrightness(LockoutBrightnessChoice.light);

      expect(ThemeController.instance.brightnessChoice,
          LockoutBrightnessChoice.light);
      expect(
          await DatabaseService.instance.getSetting('theme_key'), 'light|lime');
    });
  });
}
