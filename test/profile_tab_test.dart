import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/profile_tab.dart';
import 'package:lockout/screens/settings_screen.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

ThemeData _theme() => LockoutTheme.build(
      colors: darkAppearance.colors,
      semantics: darkAppearance.semantics,
    );

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() => wipeDatabaseAndReseed(DatabaseService.instance));

  Future<void> pumpProfile(
    WidgetTester tester, {
    GlobalKey<ProfileTabState>? key,
    VoidCallback? onSettingsUpdated,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: _theme(),
      home: ProfileTab(
        key: key,
        onSettingsUpdated: onSettingsUpdated ?? () {},
      ),
    ));
    await settle(tester);
  }

  testWidgets('renders the settings body under its own title', (tester) async {
    await pumpProfile(tester);

    expect(find.byType(SettingsBody), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('the tab title is the house large title, the one Today uses',
      (tester) async {
    // House section 7.1: a tab screen opens with `displayMedium`.
    // `today_tab.dart:693` honours it at 36sp; Profile rendered the same
    // kind of title in `headlineMedium` at 22, so the two tab screens a
    // user swipes between opened at visibly different scales.
    await pumpProfile(tester);

    final title = tester.widget<Text>(find.text('Profile'));
    // Read back through the tree, not from `_theme()`: `MaterialApp`
    // localizes the text theme before any descendant sees it, so the style
    // the screen resolved carries a geometry the raw `ThemeData` does not.
    final text = Theme.of(tester.element(find.text('Profile'))).textTheme;
    expect(title.style, text.displayMedium);
    expect(title.style?.fontSize, isNot(text.headlineMedium?.fontSize),
        reason: 'the two styles have to actually differ, or this guard '
            'asserts nothing');
  });

  testWidgets('as a tab there is no app bar and nothing to pop back to',
      (tester) async {
    await pumpProfile(tester);

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the pushed SettingsScreen keeps its app bar and back button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: _theme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(onSettingsUpdated: () {}),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);

    expect(find.byType(SettingsBody), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('reload refreshes the hosted body without throwing',
      (tester) async {
    final key = GlobalKey<ProfileTabState>();
    await pumpProfile(tester, key: key);

    await key.currentState!.reload();
    await settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the body still reaches its own settings content',
      (tester) async {
    await pumpProfile(tester);

    // One representative control from the existing settings screen, so this
    // proves the extraction kept the body intact rather than rendering an
    // empty shell.
    expect(find.byType(SwitchListTile).evaluate().isNotEmpty ||
        find.byType(Switch).evaluate().isNotEmpty, isTrue);
  });
}
