import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_theme.dart';

void main() {
  group('the typefaces are bundled, not downloaded', () {
    test('every declared font file exists on disk', () {
      const files = [
        'assets/fonts/BricolageGrotesque-Medium.ttf',
        'assets/fonts/BricolageGrotesque-Bold.ttf',
        'assets/fonts/BricolageGrotesque-ExtraBold.ttf',
        'assets/fonts/Figtree-Regular.ttf',
        'assets/fonts/Figtree-Medium.ttf',
        'assets/fonts/Figtree-SemiBold.ttf',
        'assets/fonts/Figtree-Bold.ttf',
        'assets/fonts/JetBrainsMono-Regular.ttf',
        'assets/fonts/JetBrainsMono-Bold.ttf',
      ];
      for (final path in files) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path is missing');
        expect(file.lengthSync(), greaterThan(10000),
            reason: '$path is too small to be a real typeface');
      }
    });

    test('every bundled family ships its licence', () {
      for (final path in const [
        'assets/fonts/OFL-BricolageGrotesque.txt',
        'assets/fonts/OFL-Figtree.txt',
        'assets/fonts/OFL-JetBrainsMono.txt',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      }
    });

    test('Inter and Space Grotesk are gone', () {
      final strays = Directory('assets/fonts')
          .listSync()
          .map((e) => e.path)
          .where((p) => p.contains('Inter') || p.contains('SpaceGrotesk'));
      expect(strays, isEmpty);
    });

    test('no typeface is resolved over the network', () {
      // Comment lines are stripped first: both package names are named in
      // the comments that explain why they are absent, and matching those
      // would make this assertion unsatisfiable.
      final declarations = File('pubspec.yaml')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('#'))
          .join('\n');
      expect(declarations.contains('google_fonts:'), isFalse);
      expect(declarations.contains('dynamic_color:'), isFalse,
          reason: 'the house system forbids dynamic colour (section 2)');
    });

    test('pubspec declares each family at the weights the scale uses', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final line in const [
        'family: BricolageGrotesque',
        'family: Figtree',
        'family: JetBrainsMono',
      ]) {
        expect(pubspec.contains(line), isTrue, reason: '$line is missing');
      }
      for (final weight in const [400, 500, 600, 700, 800]) {
        expect(pubspec.contains('weight: $weight'), isTrue,
            reason: 'weight $weight is never declared');
      }
    });
  });

  group('the type scale follows the house document', () {
    final text = LockoutTheme.textThemeFor(const ColorScheme.light());

    test('display sizes resolve to Bricolage Grotesque', () {
      for (final style in [
        text.displayLarge,
        text.displayMedium,
        text.displaySmall,
        text.headlineLarge,
        text.headlineMedium,
        text.headlineSmall,
        text.titleLarge,
      ]) {
        expect(style!.fontFamily, LockoutTheme.fontDisplay);
      }
    });

    test('body sizes resolve to Figtree', () {
      for (final style in [
        text.titleMedium,
        text.titleSmall,
        text.bodyLarge,
        text.bodyMedium,
        text.bodySmall,
        text.labelLarge,
        text.labelMedium,
        text.labelSmall,
      ]) {
        expect(style!.fontFamily, LockoutTheme.fontBody);
      }
    });

    test('the house sizes and weights are exact', () {
      expect(text.displayLarge!.fontSize, 44);
      expect(text.displayLarge!.fontWeight, FontWeight.w800);
      expect(text.displayMedium!.fontSize, 36);
      expect(text.headlineLarge!.fontSize, 28);
      expect(text.headlineMedium!.fontSize, 22);
      expect(text.headlineMedium!.fontWeight, FontWeight.w700);
      expect(text.titleLarge!.fontSize, 19);
      expect(text.titleMedium!.fontSize, 16);
      expect(text.titleMedium!.fontWeight, FontWeight.w700);
      expect(text.titleSmall!.fontSize, 14);
      expect(text.bodyLarge!.fontSize, 17);
      expect(text.bodyMedium!.fontSize, 15);
      expect(text.bodySmall!.fontSize, 13);
      expect(text.labelLarge!.fontSize, 15);
      expect(text.labelMedium!.fontSize, 13);
      expect(text.labelSmall!.fontSize, 12);
    });

    test('display tracking is negative, body tracking is zero', () {
      expect(text.displayLarge!.letterSpacing, closeTo(-1.32, 0.001));
      expect(text.headlineLarge!.letterSpacing, closeTo(-0.70, 0.001));
      expect(text.bodyMedium!.letterSpacing, 0);
      expect(text.labelSmall!.letterSpacing, 0);
    });

    test('the countdown style is the 88px Bricolage numeral', () {
      final style = LockoutTheme.countdown(const ColorScheme.light());
      expect(style.fontFamily, LockoutTheme.fontDisplay);
      expect(style.fontSize, 88);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.height, closeTo(72 / 88, 0.001));
      expect(style.letterSpacing, closeTo(-4.40, 0.001));
    });

    test('no style is uppercase', () {
      // The house document forbids all-caps labels outright (section 4.2).
      final source = File('lib/theme/lockout_theme.dart').readAsStringSync();
      expect(source.contains('toUpperCase'), isFalse);
    });
  });
}
