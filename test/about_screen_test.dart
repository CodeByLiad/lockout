import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/about_screen.dart';
import 'overhaul_test_support.dart';

void main() {
  testWidgets(
    'about states the publisher, license, installed version and offline policy',
    (t) async {
      await pumpPage(t, const AboutScreen());
      expect(find.text('About Lockout'), findsOneWidget);
      expect(find.textContaining('Published by Jinatra Ltd.'), findsOneWidget);
      expect(find.textContaining('GPL'), findsOneWidget);
      final version = RegExp(
        r'version: ([^+\s]+)',
      ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
      expect(find.text(version), findsOneWidget);
      expect(
        find.textContaining('No account, ads or analytics.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('the expressive back action returns to its origin', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.of(c).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
  test('source link names this repository', () {
    expect(
      File('lib/screens/about_screen.dart').readAsStringSync(),
      contains('https://github.com/CodeByLiad/lockout'),
    );
  });
}
