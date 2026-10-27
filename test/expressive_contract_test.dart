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

/// The files this branch rebuilds from the house component catalog.
///
/// Guards scoped to this list widen as screens land. They never weaken: a
/// guard that stops asserting something is a regression, not a scope change.
///
/// About has landed, so this is no longer `_branchOneFiles` under another
/// name: `about_screen.dart` is covered by the case rule here and by nothing
/// else. A screen absent from this list is a screen the next edit can walk a
/// pre-rebuild widget into unopposed, which is how the rebuild rots back.
///
/// `settings_screen.dart` is deliberately NOT repeated here. It has been in
/// `_branchOneFiles` since the restyle, so the spread above already hands it
/// to the case rule; naming it twice would read as two guards where there is
/// one. Checked by mutation, not by inspection — an all-caps literal in that
/// screen turns the case rule red through this list as it stands.
const List<String> _rebuiltFiles = [
  ..._branchOneFiles,
  'lib/screens/about_screen.dart',
  'lib/screens/profile_tab.dart',
];

/// The screens rebuilt so far. Appended to as screens land.
///
/// `settings_screen.dart` joins at branch end. It reaches for no pre-rebuild
/// widget today, so the entry catches no present bug — it is here so that the
/// next edit to a 1171-line screen cannot quietly re-import one.
///
/// `profile_tab.dart` joins for a blunter reason: it was in none of these
/// three lists at all, so every rule here skipped the only live host of
/// `SettingsBody` — the screen a user actually reaches Settings through.
const List<String> _rebuiltScreens = [
  'lib/screens/today_tab.dart',
  'lib/screens/about_screen.dart',
  'lib/screens/settings_screen.dart',
  'lib/screens/profile_tab.dart',
];

/// The pre-rebuild widgets a rebuilt screen must not reach for.
///
/// Each was written for the previous design. Adapting a screen to keep one
/// preserves that design's composition in a place no token can reach, which
/// is the failure this branch exists to end.
///
/// Two widgets `today_tab.dart` imports are deliberately NOT on this list, and
/// the distinction between them is the point:
///
///   * `sparkline.dart` is exempt, permanently. It is a `CustomPainter` that
///     draws a line from a list of numbers; it owns no layout, no spacing and
///     no surface, and takes its colour from the caller. There is no previous
///     design preserved inside it, so there is nothing for the rebuild to end.
///     A chart primitive is not a composition.
///   * `exercise_picker.dart` is a real breach, recorded rather than fixed.
///     It is an old-composition sheet, and `today_tab.dart` — a rebuilt
///     screen — imports it. Adding it here turns this suite red on shipping
///     code. It is owed to the branch that rebuilds `routines_tab.dart`, its
///     other consumer; see `docs/spine/orphaned-widgets.md`. Do not add it
///     here until that rebuild lands, and do not let its absence read as a
///     clean bill of health.
const List<String> _preRebuildWidgets = [
  'home_hub.dart',
  'lockout_card.dart',
  'hero_card.dart',
  'calm_row.dart',
  'action_grid.dart',
  'stat_tile.dart',
  'today_day_card.dart',
  'sheet_scaffold.dart',
];

/// True when [path] names a file inside the house component catalog.
///
/// Separators are normalised first. `Directory.listSync` yields `\`
/// separators on Windows and `/` on the ubuntu runner that gates the APK, so
/// a filter that compares against either one directly is a filter that runs
/// on one machine. This one ran on neither the right one: written as a
/// `widgets\house` fragment, it matched nothing on CI, the catalog stayed
/// inside its own consumer corpus, and every component counted as consumed
/// by a sibling. `no_legacy_theme_test.dart:40` and
/// `numeric_guard_test.dart:189` normalise for the same reason.
bool _inHouseCatalog(String path) =>
    _posixPath(path).contains('widgets/house/');

/// [path] with POSIX separators, whatever platform produced it.
String _posixPath(String path) => path.replaceAll(r'\', '/');

List<File> _dartFilesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// Blanks every `SnackBar(...)` argument list.
///
/// `SnackBar.duration` is how long a message stays legible, not how long
/// something moves — `nv_sheet.dart:70`'s 3s is a dismissal timeout with no
/// animation behind it. The motion rule matches on the `duration:` argument,
/// so without this the widened rule reports a snackbar as an unmotioned
/// surface and the real violation is never reached.
String _withoutSnackBars(String source) {
  var out = source;
  while (true) {
    final start = out.indexOf('SnackBar(');
    if (start < 0) return out;
    var depth = 0;
    var end = start + 'SnackBar'.length;
    for (; end < out.length; end++) {
      if (out[end] == '(') depth++;
      if (out[end] == ')') {
        depth--;
        if (depth == 0) {
          end++;
          break;
        }
      }
    }
    out = out.substring(0, start) + out.substring(end);
  }
}

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

      for (final path in _rebuiltFiles) {
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
      expect(radiusOf(shapeNow()), LockoutTheme.radiusButtonActive,
          reason: 'the press morph must reach the painted Material, and it '
              'must land on the 12dp button pill. The 16dp large pill '
              'belongs to the 60dp hero control, which is '
              '`NvButton(large: true)`, not the 48dp FilledButton this '
              'theme styles');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(radiusOf(shapeNow()), LockoutTheme.radiusButtonRest);
    });
  });

  group('the house catalog', () {
    test('every catalog component resolves colour through the theme', () {
      for (final file in _dartFilesIn('lib/widgets/house')) {
        final source = _withoutComments(file.readAsStringSync());
        expect(RegExp(r'Color\(0x').hasMatch(source), isFalse,
            reason: '${file.path} hard-codes a colour; colour resolves '
                'through Theme.of(context) or LockoutSemantics.of(context)');
        expect(source.contains('JinatraTokens'), isFalse,
            reason: '${file.path} reaches for the retired token class');
      }
    });

    test('a rebuilt screen composes from the catalog, not the old widgets',
        () {
      for (final path in _rebuiltScreens) {
        final source = _withoutComments(File(path).readAsStringSync());
        for (final widget in _preRebuildWidgets) {
          // Matched on the import path, not the bare file name: `widgets/`
          // anchors it to `lib/widgets/<widget>` and keeps the catalog's own
          // `widgets/house/nv_hero_card.dart` from reading as a hit on
          // `hero_card.dart`.
          expect(source.contains('widgets/$widget'), isFalse,
              reason: '$path still reaches for $widget, a widget written '
                  'for the previous design');
        }
      }
    });

    test('a rebuilt screen does not reach for a framework button', () {
      // The hole the import rule above could not cover. It matches on an
      // import path, and a framework widget needs no import — so three
      // framework buttons sat on the rebuilt Today screen unopposed
      // (`OutlinedButton` "Add exercise", and the finish sheet's
      // `OutlinedButton`/`FilledButton` pair). They are not the same
      // control as the catalog's: `controlHeight` is 52 against
      // `NvButton`'s 48, and the theme's press morph cannot read
      // `MediaQuery.disableAnimations` at all (deviation D10, retired by
      // `NvButton` precisely because a context-free `ThemeData` cannot).
      //
      // `\b` either side is what keeps `NvIconButton` and
      // `NvSegmentedButton` out of the match: there is no word boundary
      // inside an identifier.
      //
      // The framework `IconButton` is deliberately NOT on this list yet.
      // `settings_screen.dart:950` and `:967` still use two of them for
      // the training-days stepper, and `NvIconButton` is the control they
      // owe; adding it here turns this suite red on shipping code, which
      // is the same bargain `exercise_picker.dart` is recorded under
      // above. It is owed, not absolved.
      const frameworkButtons = [
        'ElevatedButton',
        'FilledButton',
        'OutlinedButton',
        'TextButton',
        'MaterialButton',
        'CupertinoButton',
      ];

      for (final path in _rebuiltScreens) {
        final source = _withoutComments(File(path).readAsStringSync());
        for (final widget in frameworkButtons) {
          expect(RegExp('\\b$widget\\b').hasMatch(source), isFalse,
              reason: '$path builds a $widget; a rebuilt screen composes '
                  'from lib/widgets/house/ and the theme only, and '
                  'NvButton is the control that is the same size and '
                  'presses to the same radius as the rest of the screen');
        }
      }
    });

    test('every interactive catalog component carries a radius pair', () {
      // A single fixed radius on an interactive surface is a contract
      // violation. Each of these routes its press through MorphingSurface,
      // which takes a rest and an active radius by construction — asserting
      // the route is what makes the rule reachable rather than decorative.
      const interactive = [
        'lib/widgets/house/nv_button.dart',
        'lib/widgets/house/nv_grouped_list.dart',
      ];

      for (final path in interactive) {
        final source = _withoutComments(File(path).readAsStringSync());
        expect(source.contains('MorphingSurface('), isTrue,
            reason: '$path has a press state but does not morph');
        expect(source.contains('restRadius:'), isTrue, reason: path);
        expect(source.contains('activeRadius:'), isTrue, reason: path);
      }
    });

    test('the hero card wears the signature outline and does not morph', () {
      final source = _withoutComments(
        File('lib/widgets/house/nv_hero_card.dart').readAsStringSync(),
      );
      expect(source.contains('LockoutTheme.heroCardShape'), isTrue,
          reason: 'the hero card carries the family signature');
      expect(source.contains('MorphingSurface('), isFalse,
          reason: 'a card has no pressed state to shape-shift into');
    });

    test('every catalog component has a consumer outside the catalog', () {
      // The defect this branch exists to end: MorphingSurface and
      // ConnectedGroup shipped a review cycle built, tested, documented and
      // called by nothing. A component with no consumer is not a design
      // system, it is dead code with a doc comment.
      final consumers = _dartFilesIn('lib')
          .where((f) => !_inHouseCatalog(f.path))
          .map((f) => _withoutComments(f.readAsStringSync()))
          .join('\n');

      for (final file in _dartFilesIn('lib/widgets/house')) {
        final name = file.uri.pathSegments.last.replaceAll('.dart', '');
        expect(consumers.contains(name), isTrue,
            reason: '${file.path} is built but wired to nothing outside the '
                'catalog');
      }
    });
  });

  group('the path filters do not depend on the platform', () {
    // CI is `runs-on: ubuntu-latest` (`.github/workflows/build-apk.yml:16`)
    // and development is Windows, so every path filter in this file meets
    // both separator styles. A filter written against one of them runs on
    // one of the two machines, and the one it skips is the one that gates
    // integration.
    test('the catalog filter matches both separator styles', () {
      // Built by substitution rather than written as a literal: the
      // scan below forbids a backslash-separated path fragment
      // anywhere in this file, and an input is not an exception.
      String windows(String posix) => posix.replaceAll('/', r'\');

      expect(_inHouseCatalog(windows('lib/widgets/house/nv_button.dart')),
          isTrue,
          reason: 'Directory.listSync yields this shape on Windows');
      expect(_inHouseCatalog('lib/widgets/house/nv_button.dart'), isTrue,
          reason: 'and this shape on the ubuntu runner that gates the APK');
      expect(_inHouseCatalog(windows('lib/screens/today_tab.dart')), isFalse);
      expect(_inHouseCatalog('lib/widgets/morphing_surface.dart'), isFalse,
          reason: 'a widget outside the catalog is a real consumer');
    });

    test('no guard in this file hard-codes a Windows separator', () {
      // The failure this group exists to stop recurring: the orphan guard
      // filtered on a backslash-separated fragment, which matches nothing
      // on POSIX, so the catalog stayed inside its own consumer corpus and
      // every component read as consumed by a sibling. Comments are
      // stripped, so prose naming a Windows path does not trip the scan.
      final source = _withoutComments(
        File('test/expressive_contract_test.dart').readAsStringSync(),
      );
      final offenders =
          RegExp(r'(lib|test|widgets|screens|theme|house|dart)\\')
              .allMatches(source)
              .map((m) => m.group(0)!)
              .toList();
      expect(offenders, isEmpty,
          reason: 'a path fragment is separated with a backslash. Normalise '
              'the path first and compare against `/`, as '
              'no_legacy_theme_test.dart:40 and numeric_guard_test.dart:189 '
              'already do');
    });
  });

  group('motion', () {
    test('there are exactly three interaction tiers', () {
      expect(LockoutMotion.springFast.duration.inMilliseconds, 250);
      expect(LockoutMotion.springDefault.duration.inMilliseconds, 450);
      expect(LockoutMotion.effects.duration.inMilliseconds, 200);
    });

    test('the one ambient tier is named, and the vocabulary stays closed', () {
      // The wave is the only thing in the app that moves unprompted (house
      // section 6), so it gets a named tier rather than a literal at its
      // call site. Linear: an eased loop hesitates once per period.
      expect(LockoutMotion.ambientDrift.duration.inMilliseconds, 2400);
      expect(LockoutMotion.ambientDrift.curve, Curves.linear);

      // Counted from the source, because the point of a vocabulary is that
      // it is closed. A fifth tier is not forbidden — it is required to
      // come through this assertion and say what it is for.
      final declared = RegExp(r'static const LockoutMotionTier (\w+)')
          .allMatches(File('lib/theme/lockout_motion.dart').readAsStringSync())
          .map((m) => m.group(1))
          .toList();
      expect(declared,
          ['springFast', 'springDefault', 'effects', 'ambientDrift']);
    });

    test('no animated surface this branch owns hand-rolls a duration', () {
      // Matched on the animated widgets rather than on a bare duration
      // literal, because a debounce or a timer is a duration that is not
      // motion and must not be dragged into the motion system.
      // Matched on the duration argument itself. The previous form passed if
      // the file mentioned `LockoutMotion.` anywhere, so one correct call
      // site licensed every hand-rolled duration sitting beside it.
      // Scoped to the rebuilt files AND the house catalog. It used to run
      // over `_branchOneFiles`, which names no catalog file, so the branch's
      // signature rule never reached the branch's main artefact:
      // `nv_wavy_progress.dart` hand-rolled a 2400ms controller and the
      // suite stayed green.
      final handRolled = RegExp(r'duration:\s*(const\s+)?Duration\(');
      final scanned = <String>[
        ..._rebuiltFiles,
        ..._dartFilesIn('lib/widgets/house').map((f) => f.path),
      ];
      for (final path in scanned) {
        if (path.endsWith('lockout_motion.dart')) continue;
        final source =
            _withoutSnackBars(_withoutComments(File(path).readAsStringSync()));
        expect(handRolled.hasMatch(source), isFalse,
            reason: '${_posixPath(path)} passes a literal Duration to an '
                'animation; every '
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
