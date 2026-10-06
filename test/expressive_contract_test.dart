import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/lockout_motion.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/theme/palette.dart';

/// The vendored house document.
///
/// Every value asserted below is read from it rather than restated here: a
/// second copy of the palette inside a test file is a second thing to keep
/// in step, and the one that drifts is always the copy.
final String _house =
    File('docs/design/nuvetrix-app-design-system.md').readAsStringSync();

/// The files branch 1 restyles.
///
/// Several guards are scoped to this list rather than to all of `lib`,
/// because the six remaining tabs and the copy sweep are branch 2. Branch 2
/// widens the list; it does not weaken the guards.
const List<String> _branchOneFiles = [
  'lib/main.dart',
  'lib/theme/accents.dart',
  'lib/theme/cookie_border.dart',
  'lib/theme/lockout_motion.dart',
  'lib/theme/lockout_semantics.dart',
  'lib/theme/lockout_theme.dart',
  'lib/theme/palette.dart',
  'lib/theme/theme_controller.dart',
  'lib/widgets/connected_group.dart',
  'lib/widgets/hero_card.dart',
  'lib/widgets/lockout_card.dart',
  'lib/widgets/morphing_surface.dart',
  'lib/widgets/home_hub.dart',
  'lib/widgets/stat_tile.dart',
  'lib/screens/settings_screen.dart',
  'lib/screens/today_tab.dart',
];

List<File> _dartFilesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// Blanks `//` comments so a guard does not trip over prose that names the
/// very thing it forbids.
String _withoutComments(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//') &&
        !line.trimLeft().startsWith('///'))
    .join('\n');

/// True when the house document mentions this colour's hex, in either case.
bool _houseDeclares(Color colour) {
  final hex = colour
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2)
      .toUpperCase();
  return _house.toUpperCase().contains('#$hex');
}

void main() {
  group('the house document is present and is the one we tested against', () {
    test('the vendored copy exists and carries a version', () {
      expect(_house, isNotEmpty);
      expect(_house.contains('Version 1.'), isTrue);
    });

    test('Lockout is registered in the accents table', () {
      expect(_house.contains('#C2EE7B'), isTrue,
          reason: "Lockout's accent must be registered upstream before use");
    });
  });

  group('colour', () {
    test('every palette colour is one the house document declares', () {
      for (final brightness in Brightness.values) {
        final scheme = LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        final roles = <String, Color>{
          'surface': scheme.surface,
          'surfaceContainer': scheme.surfaceContainer,
          'surfaceContainerHigh': scheme.surfaceContainerHigh,
          'surfaceContainerHighest': scheme.surfaceContainerHighest,
          'onSurface': scheme.onSurface,
          'onSurfaceVariant': scheme.onSurfaceVariant,
          'outline': scheme.outline,
          'outlineVariant': scheme.outlineVariant,
          'secondaryContainer': scheme.secondaryContainer,
          'tertiary': scheme.tertiary,
          'error': scheme.error,
        };
        roles.forEach((name, colour) {
          expect(_houseDeclares(colour), isTrue,
              reason: '$brightness $name ($colour) is not a house colour');
        });
      }
    });

    test('every accent and its ink appear in the house document', () {
      for (final accent in LockoutAccent.all) {
        // `steel` is Lockout's own, deviation register D6.
        if (accent == LockoutAccent.steel) continue;
        expect(_houseDeclares(accent.accent), isTrue,
            reason: '${accent.key} is not a house accent');
        expect(_houseDeclares(accent.ink), isTrue,
            reason: "${accent.key}'s ink is not a house value");
      }
    });

    test('WishPlay gold appears nowhere in the app', () {
      final offenders = _dartFilesIn('lib')
          .where((f) => f.readAsStringSync().toUpperCase().contains('FFB938'))
          .map((f) => f.path);
      expect(offenders, isEmpty,
          reason: 'gold is WishPlay\'s identity accent (house section 3.3)');
    });
  });

  group('type', () {
    test('only the three bundled families are named', () {
      for (final file in _dartFilesIn('lib')) {
        final source = _withoutComments(file.readAsStringSync());
        for (final banned in const ['Inter', 'SpaceGrotesk', 'Roboto']) {
          expect(source.contains("'$banned'"), isFalse,
              reason: '${file.path} names the unbundled family $banned');
        }
      }
    });

    test('the house declares every size the scale uses', () {
      final text = LockoutTheme.textThemeFor(const ColorScheme.light());
      for (final size in <double>[
        text.displayLarge!.fontSize!,
        text.displayMedium!.fontSize!,
        text.headlineLarge!.fontSize!,
        text.headlineMedium!.fontSize!,
        text.titleLarge!.fontSize!,
        text.titleMedium!.fontSize!,
        text.bodyMedium!.fontSize!,
        text.labelSmall!.fontSize!,
      ]) {
        expect(_house.contains('| ${size.toInt()} /'), isTrue,
            reason: '${size.toInt()}sp is not a house size');
      }
    });

    test('nothing this branch owns uppercases display copy', () {
      // Scoped deliberately. The six remaining tabs still carry all-caps
      // copy and `toUpperCase()` on tag comparisons; the copy sweep is
      // branch 2, and widening this list is that branch's job. Data
      // normalisation — scheduling-mode names, tag matching — is not display
      // copy and never belongs in this list.
      // Two separate failures: calling `toUpperCase` on display copy, and
      // writing the copy in capitals to begin with. This guard caught only
      // the first, so `'SESSION SAVED - ...'` sailed straight through it.
      final shouty = RegExp("'[^']*\\b[A-Z]{3,}\\b[^']*'");
      // Proper nouns, licence identifiers and domain acronyms are not
      // shouting. Everything else in capitals is copy that should be
      // sentence case.
      const allowed = {
        'LOCKOUT', // the app's own name
        'GPL', 'OFL', // licence identifiers
        'BMI', 'BMR', 'TDEE', 'KCAL', 'SQL', 'JSON', 'CSV', 'URL', 'API',
      };

      for (final path in _branchOneFiles) {
        final source = File(path).readAsStringSync();
        expect(source.contains('toUpperCase'), isFalse,
            reason: '$path uppercases copy; the house document forbids '
                'all-caps labels (section 4.2)');

        for (final match in shouty.allMatches(_withoutComments(source))) {
          final literal = match.group(0)!;
          final words = RegExp('\\b[A-Z]{3,}\\b')
              .allMatches(literal)
              .map((m) => m.group(0)!)
              .where((w) => !allowed.contains(w))
              .toList();
          expect(words, isEmpty, reason: '$path has all-caps copy: $literal');
        }
      }
    });
  });

  group('shape', () {
    test('the hero card is 36 on three corners and 12 bottom-left', () {
      final radius = LockoutTheme.heroCardShape.borderRadius as BorderRadius;
      expect(radius.topLeft.x, 36);
      expect(radius.topRight.x, 36);
      expect(radius.bottomRight.x, 36);
      expect(radius.bottomLeft.x, 12);
    });

    test('every interactive radius is a pair, not a constant', () {
      expect(LockoutTheme.radiusButtonRest,
          isNot(LockoutTheme.radiusButtonActive));
      expect(LockoutTheme.radiusRowRest, isNot(LockoutTheme.radiusRowActive));
      expect(LockoutTheme.radiusChipRest, isNot(LockoutTheme.radiusChipActive));
    });

    test('the button themes resolve a different shape when pressed', () {
      // The constants differing proves nothing on its own: this branch was
      // reviewed once with all of them defined and none of them reaching a
      // component theme, and this assertion passed. It now checks the
      // resolver rather than the token.
      final theme = LockoutTheme.build(
        colors: LockoutPalette.schemeFor(Brightness.dark, LockoutAccent.lime),
        semantics:
            LockoutPalette.semanticsFor(Brightness.dark, LockoutAccent.lime),
      );

      double radiusOf(OutlinedBorder? shape) =>
          ((shape! as RoundedRectangleBorder).borderRadius as BorderRadius)
              .topLeft
              .x;

      final resolvers = <String, WidgetStateProperty<OutlinedBorder?>>{
        'filled': theme.filledButtonTheme.style!.shape!,
        'outlined': theme.outlinedButtonTheme.style!.shape!,
        'text': theme.textButtonTheme.style!.shape!,
      };

      // Deliberately not the segmented control: `SegmentedButton` hardcodes
      // each segment's shape and resolves the style with `selected`
      // permanently set, so resolving it here against `{}` and `{pressed}`
      // would assert a shape the framework never paints. Asserting something
      // inert is the exact mistake this test exists to stop.
      resolvers.forEach((name, resolver) {
        final rest = radiusOf(resolver.resolve(<WidgetState>{}));
        final pressed =
            radiusOf(resolver.resolve(<WidgetState>{WidgetState.pressed}));
        expect(pressed, isNot(rest),
            reason: '$name keeps one radius through a press, which the '
                'contract calls a violation');
      });
    });

    test('the shape-as-state primitives have production consumers', () {
      // This branch shipped a review cycle with `MorphingSurface` and
      // `ConnectedGroup` built, tested, documented and called by nothing
      // outside their own test files. A primitive with no consumer is not a
      // design system, it is dead code with a doc comment.
      for (final widget in const ['MorphingSurface', 'ConnectedGroup']) {
        final consumers = _dartFilesIn('lib')
            .where((f) => !f.path.endsWith(
                '${widget == 'MorphingSurface' ? 'morphing_surface' : 'connected_group'}.dart'))
            // Comments stripped: every other guard in this file does, and
            // without it a doc comment naming the widget keeps this green
            // forever while nothing actually builds one.
            .where((f) =>
                _withoutComments(f.readAsStringSync()).contains('$widget('))
            .map((f) => f.path)
            .toList();
        expect(consumers, isNotEmpty,
            reason: '$widget is built but wired to nothing in lib/');
      }
    });

    test('the house declares each corner value the app uses', () {
      for (final value in const [8, 12, 16, 22, 26, 28, 32, 36]) {
        expect(_house.contains('$value dp'), isTrue,
            reason: '${value}dp is not a house corner value');
      }
    });
  });

  group('the shapes reach real widgets, not just the theme', () {
    // Resolving a WidgetStateProperty by hand proves the theme agrees with
    // itself. These pump the actual widget and read what it paints, which is
    // the only way to catch a framework default overriding the theme — the
    // way SegmentedButton discards the segment shape it is given.
    Widget host(Widget child) => MaterialApp(
          theme: LockoutTheme.build(
            colors:
                LockoutPalette.schemeFor(Brightness.dark, LockoutAccent.lime),
            semantics: LockoutPalette.semanticsFor(
                Brightness.dark, LockoutAccent.lime),
          ),
          home: Scaffold(body: Center(child: child)),
        );

    double radiusOf(ShapeBorder? shape) =>
        ((shape! as RoundedRectangleBorder).borderRadius as BorderRadius)
            .topLeft
            .x;

    testWidgets('a chip is 12dp unselected and a pill once chosen',
        (tester) async {
      for (final selected in const [false, true]) {
        await tester.pumpWidget(host(ChoiceChip(
          label: const Text('Push'),
          selected: selected,
          onSelected: (_) {},
        )));
        await tester.pumpAndSettle();

        final shape = tester
            .widgetList<Material>(find.descendant(
              of: find.byType(ChoiceChip),
              matching: find.byType(Material),
            ))
            .map((m) => m.shape)
            .whereType<RoundedRectangleBorder>()
            .first;

        expect(radiusOf(shape),
            selected ? LockoutTheme.radiusChipActive : LockoutTheme.radiusChipRest,
            reason: 'chip selected=$selected');
      }
    });

    testWidgets('a filled button morphs from pill to 12dp under the finger',
        (tester) async {
      await tester.pumpWidget(host(
        FilledButton(onPressed: () {}, child: const Text('Save')),
      ));
      await tester.pumpAndSettle();

      ShapeBorder? shapeNow() => tester
          .widgetList<Material>(find.descendant(
            of: find.byType(FilledButton),
            matching: find.byType(Material),
          ))
          .map((m) => m.shape)
          .whereType<RoundedRectangleBorder>()
          .first;

      expect(radiusOf(shapeNow()), LockoutTheme.radiusButtonRest);

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(FilledButton)));
      await tester.pumpAndSettle();
      expect(radiusOf(shapeNow()), LockoutTheme.radiusButtonLargeActive,
          reason: 'the press morph must reach the painted Material');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(radiusOf(shapeNow()), LockoutTheme.radiusButtonRest);
    });
  });

  group('motion', () {
    test('there are exactly three tiers', () {
      expect(LockoutMotion.springFast.duration.inMilliseconds, 250);
      expect(LockoutMotion.springDefault.duration.inMilliseconds, 450);
      expect(LockoutMotion.effects.duration.inMilliseconds, 200);
    });

    test('no animated surface this branch owns hand-rolls a duration', () {
      // Matched on the animated widgets rather than on a bare duration
      // literal, because a debounce or a timer is a duration that is not
      // motion and must not be dragged into the motion system.
      // Matched on the duration argument itself. The previous form passed if
      // the file mentioned `LockoutMotion.` anywhere, so one correct call
      // site licensed every hand-rolled duration sitting beside it.
      final handRolled = RegExp(r'duration:\s*(const\s+)?Duration\(');
      for (final path in _branchOneFiles) {
        if (path.endsWith('lockout_motion.dart')) continue;
        final source = _withoutComments(File(path).readAsStringSync());
        expect(handRolled.hasMatch(source), isFalse,
            reason: '$path passes a literal Duration to an animation; every '
                'animated surface reads a LockoutMotion tier');
      }
    });

    test('framework easing tokens are gone', () {
      // Scoped to all of `lib`, not just the theme layer: the one surviving
      // `Durations.medium1` was in `today_tab.dart`, a restyled file this
      // guard was not looking at.
      for (final file in _dartFilesIn('lib')) {
        final source = _withoutComments(file.readAsStringSync());
        expect(source.contains('Easing.'), isFalse, reason: file.path);
        expect(source.contains('Durations.'), isFalse, reason: file.path);
      }
    });
  });

  group('dependencies', () {
    test('no new package arrived, and dynamic_color left', () {
      // Comment lines are stripped: both package names are named in the
      // comments that explain why they are absent.
      final declarations = File('pubspec.yaml')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('#'))
          .join('\n');
      expect(declarations.contains('dynamic_color:'), isFalse);
      expect(declarations.contains('google_fonts:'), isFalse);
    });

    test('nothing reaches for a wallpaper-derived scheme', () {
      for (final file in _dartFilesIn('lib')) {
        final source = _withoutComments(file.readAsStringSync());
        expect(source.contains('DynamicColorBuilder'), isFalse,
            reason: '${file.path} still uses dynamic colour');
      }
    });
  });
}
