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
}
