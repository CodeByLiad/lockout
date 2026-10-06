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
      // Per family, not against the whole file. Checking `weight: 500`
      // globally passed while JetBrains Mono had no 500 at all, which is how
      // `numeric()` came to request a weight that silently matched down to
      // Regular.
      final declared = <String, Set<int>>{};
      String? family;
      for (final line in File('pubspec.yaml').readAsLinesSync()) {
        final name = RegExp(r'- family:\s*(\S+)').firstMatch(line);
        if (name != null) {
          family = name.group(1);
          declared[family!] = <int>{};
          continue;
        }
        final weight = RegExp(r'weight:\s*(\d+)').firstMatch(line);
        if (weight != null && family != null) {
          declared[family]!.add(int.parse(weight.group(1)!));
        }
      }

      expect(declared['BricolageGrotesque'], containsAll(<int>[500, 700, 800]),
          reason: 'the display scale uses 500, 700 and 800');
      expect(declared['Figtree'], containsAll(<int>[400, 500, 600, 700]),
          reason: 'the body scale uses 400, 500, 600 and 700');
      expect(declared['JetBrainsMono'], containsAll(<int>[400, 700]),
          reason: 'the numeric style uses 400 and 700');
    });

    testWidgets('every weight the type scale asks for is bundled',
        (tester) async {
      // A font matcher does not fail on an unbundled weight; it quietly
      // matches to the nearest one, and the style stops meaning anything.
      final declared = <String, Set<int>>{};
      String? family;
      for (final line in File('pubspec.yaml').readAsLinesSync()) {
        final name = RegExp(r'- family:\s*(\S+)').firstMatch(line);
        if (name != null) {
          family = name.group(1);
          declared[family!] = <int>{};
          continue;
        }
        final weight = RegExp(r'weight:\s*(\d+)').firstMatch(line);
        if (weight != null && family != null) {
          declared[family]!.add(int.parse(weight.group(1)!));
        }
      }

      final text = LockoutTheme.textThemeFor(const ColorScheme.light());
      final styles = <TextStyle>[
        ...<TextStyle?>[
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ].whereType<TextStyle>(),
        LockoutTheme.countdown(const ColorScheme.light()),
      ];

      late TextStyle numericStyle;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          numericStyle = LockoutTheme.numeric(context);
          return const SizedBox();
        }),
      ));
      styles.add(numericStyle);

      for (final style in styles) {
        final weight = int.parse(style.fontWeight!.toString().split('.w').last);
        expect(declared[style.fontFamily], contains(weight),
            reason: '${style.fontFamily} has no weight $weight bundled, so '
                'this style matches down to the nearest one that is');
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
