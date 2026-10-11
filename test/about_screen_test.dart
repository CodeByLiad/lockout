import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/about_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('it names the maker, the version and the licence',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    // Corrected against the brief: Nuvetrix is the design system this app's
    // screens are built from, not Lockout's publisher. Jinatra Ltd. is named
    // in settings_screen.dart and theme_controller.dart, and that is the
    // attribution this screen must keep carrying.
    expect(find.textContaining('Published by Jinatra Ltd.'), findsOneWidget);
    expect(find.textContaining('GPL'), findsOneWidget);
  });

  testWidgets('it uses a simple top bar with a back button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('it renders policy references as text, not live links',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InkWell), findsNothing,
        reason: 'the app is zero-network at runtime; a dead link is worse '
            'than none');
  });

  // Moved from settings_restyle_test.dart: this content used to live inside
  // SettingsScreen's About card and is carried here intact by Task 10, not
  // rewritten. The Watch control's real on-screen label is 'Watch', in the
  // routine editor, and the house document forbids all-caps labels (section
  // 4.2, register entry D8).
  testWidgets('it names the Watch control as it is labelled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: const AboutScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('when you tap Watch'), findsOneWidget);
    expect(find.textContaining('WATCH'), findsNothing);
  });
}
