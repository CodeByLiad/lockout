# Lockout Expressive Restyle — Branch 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-dev (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Lockout's baseline Material 3 theme system with the Nuvetrix house design system — the house palette and type scale, shape-as-state, lobed subject shapes, three motion tiers and a two-axis theme model — and prove it on the settings picker and the Today tab.

**Architecture:** The theme layer is rebuilt behind the seam the app already uses: every widget keeps reading colour, type and shape through `Theme.of(context)`. Six authored `LockoutScheme`s collapse into one neutral palette per brightness plus a selectable accent, composed into a `ColorScheme` at build time. Four new theme-layer modules (`LockoutMotion`, `CookieBorder`, `LockoutAccent`, `LockoutPalette`) and two new widget primitives (`MorphingSurface`, `ConnectedGroup`) are the only new public surface; screens consume them.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, `flutter_test`, `sqflite` (settings persistence only). The `dynamic_color` dependency is removed and nothing replaces it.

## Global Constraints

- Flutter SDK is NOT on PATH. Every command uses the absolute path: `C:\src\flutter\bin\flutter.bat`.
- Tests MUST run serial: `C:\src\flutter\bin\flutter.bat test --concurrency=1`. Suites share one sqflite database file; the default parallel run produces ~10 spurious failures.
- Baseline to hold or beat: **586 passing** at `0a2ae73`.
- **The governing document is `docs/design/nuvetrix-app-design-system.md`** (Nuvetrix App Design System v1.1), vendored into this repo. It is authoritative for colour, type, shape, motion and spacing. Lockout may depart from it ONLY through a numbered entry in the deviation register at `docs/spine/specs/2026-10-01-expressive-restyle-design.md` §3.
- **No new package dependencies.** `dynamic_color` is REMOVED. Shape morphing and the lobed shapes are framework-only.
- Zero-network at runtime. Every typeface ships bundled under `assets/fonts/`; static instances only, because Flutter collapses a variable font to one instance and `fontWeight` stops working.
- No database schema change. Schema stays at version 4. Only the stored *setting* changes.
- Colour, type and shape resolve through `Theme.of(context)` / `ColorScheme` — never a static token class, never a compile-time colour constant.
- **Sentence case everywhere. There is no uppercase text style** (house §4.2; deviation register D8).
- Motion uses exactly three tiers — `springFast` 250ms, `springDefault` 450ms, `effects` 200ms with no overshoot. Framework `Durations` / `Easing` tokens are not used.
- Out of scope for this branch: `routines_tab`, `body_tab`, `food_tab`, `log_tab`, `progress_tab`, `profile_tab`, the house component catalog, the house icon set, the copy sweep, and bottom-nav tab consolidation.
- Commit after every task. Conventional commit prefixes, matching existing history (`feat(ui):`, `fix(theme,test):`).

---

## File structure and seams

| Module | Seam (the interface callers depend on) |
| --- | --- |
| `lib/theme/palette.dart` | `LockoutPalette.light` / `.dark` — two `ColorScheme` bases with no accent applied, plus `LockoutPalette.semanticsFor(Brightness)`. |
| `lib/theme/accents.dart` | `LockoutAccent` — `key`, `name`, `accent`, `ink`; `LockoutAccent.all`, `.byKey(String)`, `.fallback`. |
| `lib/theme/lockout_motion.dart` | `LockoutMotion.springFast` / `.springDefault` / `.effects`, each a `LockoutMotionTier` carrying `.curve`, `.duration` and `.durationFor(BuildContext)`. |
| `lib/theme/cookie_border.dart` | `CookieBorder({int lobes, double amplitude})` — a `ShapeBorder`. |
| `lib/theme/lockout_theme.dart` | `LockoutTheme.build({ColorScheme, LockoutSemantics})` — unchanged signature; the radius pairs and type scale behind it change. |
| `lib/theme/theme_controller.dart` | `ThemeController.brightnessChoice` / `.accent` / `.selectBrightness()` / `.selectAccent()`, plus the existing `lightTheme` / `darkTheme` / `themeMode`. |
| `lib/widgets/morphing_surface.dart` | `MorphingSurface({double restRadius, double activeRadius, bool active, double activeScale, Widget child})`. |
| `lib/widgets/connected_group.dart` | `ConnectedGroup({List<Widget> children})`. |

The `LockoutTheme.build` signature is deliberately unchanged, so every existing call site keeps compiling while the values behind it are replaced.

---

### Task 1: Bundle Bricolage Grotesque and Figtree, and adopt the house type scale

**Files:**
- Create: `assets/fonts/BricolageGrotesque-Medium.ttf`, `BricolageGrotesque-Bold.ttf`, `BricolageGrotesque-ExtraBold.ttf`
- Create: `assets/fonts/Figtree-Regular.ttf`, `Figtree-Medium.ttf`, `Figtree-SemiBold.ttf`, `Figtree-Bold.ttf`
- Create: `assets/fonts/OFL-BricolageGrotesque.txt`, `assets/fonts/OFL-Figtree.txt`
- Delete: `assets/fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`, `OFL-Inter.txt`
- Modify: `pubspec.yaml` — the `fonts:` block
- Modify: `lib/theme/lockout_theme.dart:63-127` — `fontSans`, `textThemeFor`, `numeric`
- Test: `test/fonts_bundled_test.dart` (rewrite), `test/lockout_theme_test.dart` (extend)

**Interfaces:**
- Consumes: nothing.
- Produces: `LockoutTheme.fontDisplay = 'BricolageGrotesque'`, `LockoutTheme.fontBody = 'Figtree'`, `LockoutTheme.fontMono = 'JetBrainsMono'`; `LockoutTheme.textThemeFor(ColorScheme)` returning the house scale; `LockoutTheme.countdown(ColorScheme, {Color? color})` returning the 88px hero numeral style; `LockoutTheme.numeric(BuildContext, {double size, FontWeight weight, Color? color})` unchanged in signature, retargeted to the `numericTable` metrics.

- [ ] **Step 1: Fetch the typefaces and their licences**

These are the only network calls in the branch, and they happen at build time, not runtime.

```bash
B=https://raw.githubusercontent.com/ateliertriay/bricolage/main
F=https://raw.githubusercontent.com/erikdkennedy/figtree/master

curl -fL "$B/fonts/ttf/BricolageGrotesque-Medium.ttf"    -o assets/fonts/BricolageGrotesque-Medium.ttf
curl -fL "$B/fonts/ttf/BricolageGrotesque-Bold.ttf"      -o assets/fonts/BricolageGrotesque-Bold.ttf
curl -fL "$B/fonts/ttf/BricolageGrotesque-ExtraBold.ttf" -o assets/fonts/BricolageGrotesque-ExtraBold.ttf
curl -fL "$B/OFL.txt" -o assets/fonts/OFL-BricolageGrotesque.txt

curl -fL "$F/fonts/ttf/Figtree-Regular.ttf"  -o assets/fonts/Figtree-Regular.ttf
curl -fL "$F/fonts/ttf/Figtree-Medium.ttf"   -o assets/fonts/Figtree-Medium.ttf
curl -fL "$F/fonts/ttf/Figtree-SemiBold.ttf" -o assets/fonts/Figtree-SemiBold.ttf
curl -fL "$F/fonts/ttf/Figtree-Bold.ttf"     -o assets/fonts/Figtree-Bold.ttf
curl -fL "$F/OFL.txt" -o assets/fonts/OFL-Figtree.txt

git rm assets/fonts/Inter-Regular.ttf assets/fonts/Inter-Medium.ttf \
       assets/fonts/Inter-SemiBold.ttf assets/fonts/Inter-Bold.ttf \
       assets/fonts/OFL-Inter.txt
```

Verify every file is a real TTF and not an HTML error page:

```bash
ls -l assets/fonts/
file assets/fonts/BricolageGrotesque-ExtraBold.ttf assets/fonts/Figtree-Regular.ttf
```

Expected: each `.ttf` is tens of kilobytes and `file` reports "TrueType Font data". A file under 1KB means the fetch returned an error page — stop and re-fetch rather than continuing.

- [ ] **Step 2: Write the failing test**

Replace `test/fonts_bundled_test.dart` entirely:

```dart
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
      expect(Directory('assets/fonts')
          .listSync()
          .map((e) => e.path)
          .where((p) => p.contains('Inter') || p.contains('SpaceGrotesk')),
          isEmpty);
    });

    test('no typeface is resolved over the network', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('google_fonts:'), isFalse);
      expect(pubspec.contains('dynamic_color:'), isFalse,
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
      for (final weight in const [500, 700, 800]) {
        expect(pubspec.contains('BricolageGrotesque-'), isTrue);
        expect(pubspec.contains('weight: $weight'), isTrue);
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
      final source =
          File('lib/theme/lockout_theme.dart').readAsStringSync();
      expect(source.contains('toUpperCase'), isFalse);
    });
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/fonts_bundled_test.dart`
Expected: FAIL — `LockoutTheme.fontDisplay` and `LockoutTheme.countdown` are not defined, and `pubspec.yaml` still declares Inter and `dynamic_color`.

- [ ] **Step 4: Declare the families in `pubspec.yaml`**

Replace the whole `fonts:` block under `flutter:` with:

```yaml
  # Static weights rather than the variable font: Flutter resolves a
  # variable face to a single default instance, so `fontWeight` would stop
  # doing anything across the type scale. Bricolage Grotesque and Figtree
  # both publish statics upstream; the Google Fonts API serves only the
  # variable build, which is why these come from the projects themselves.
  fonts:
    - family: BricolageGrotesque
      fonts:
        - asset: assets/fonts/BricolageGrotesque-Medium.ttf
          weight: 500
        - asset: assets/fonts/BricolageGrotesque-Bold.ttf
          weight: 700
        - asset: assets/fonts/BricolageGrotesque-ExtraBold.ttf
          weight: 800
    - family: Figtree
      fonts:
        - asset: assets/fonts/Figtree-Regular.ttf
          weight: 400
        - asset: assets/fonts/Figtree-Medium.ttf
          weight: 500
        - asset: assets/fonts/Figtree-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Figtree-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
```

In the `dependencies:` block, delete the `dynamic_color: ^1.7.0` line and rewrite the comment above it:

```yaml
  # Bricolage Grotesque, Figtree and JetBrains Mono are bundled under
  # assets/fonts instead of resolved through google_fonts: that package
  # downloads typefaces over HTTP at first paint, which never completes on a
  # zero-network device, so every chosen face silently fell back to Roboto in
  # the shipped APK. `dynamic_color` is likewise absent — the Nuvetrix house
  # system forbids wallpaper-derived colour (section 2).
```

- [ ] **Step 5: Replace the family constants and the type scale**

In `lib/theme/lockout_theme.dart`, replace lines 63-64:

```dart
  static const String fontSans = 'Inter';
  static const String fontMono = 'JetBrainsMono';
```

with:

```dart
  static const String fontDisplay = 'BricolageGrotesque';
  static const String fontBody = 'Figtree';
  static const String fontMono = 'JetBrainsMono';
```

Then replace the whole of `textThemeFor` (lines 66-110) with:

```dart
  /// The house type scale, stated rather than derived.
  ///
  /// Sizes, weights, line heights and tracking come from
  /// `docs/design/nuvetrix-app-design-system.md` section 4.1. They are
  /// written out instead of scaled from one base size so that changing
  /// `titleMedium` cannot silently move `bodySmall` with it.
  ///
  /// Flutter's `letterSpacing` is in logical pixels, not em, so each em
  /// figure from the house document is multiplied by its own size here.
  ///
  /// `displaySmall` and `headlineSmall` have no house entry: the document's
  /// scale has thirteen styles and Flutter's `TextTheme` has fifteen. They
  /// are interpolated between their neighbours at the same family, weight
  /// and tracking ratio, and are the only two styles in this method not
  /// copied from the document.
  static TextTheme textThemeFor(ColorScheme colors) {
    TextStyle display(
      double size,
      FontWeight weight,
      double lineHeight,
      double em, {
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontDisplay,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        letterSpacing: size * em,
        color: color ?? colors.onSurface,
      );
    }

    TextStyle body(
      double size,
      FontWeight weight,
      double lineHeight, {
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontBody,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        letterSpacing: 0,
        color: color ?? colors.onSurface,
      );
    }

    return TextTheme(
      displayLarge: display(44, FontWeight.w800, 46, -0.03),
      displayMedium: display(36, FontWeight.w800, 38, -0.03),
      displaySmall: display(32, FontWeight.w800, 34, -0.03),
      headlineLarge: display(28, FontWeight.w800, 31, -0.025),
      headlineMedium: display(22, FontWeight.w700, 26, -0.02),
      headlineSmall: display(20, FontWeight.w700, 24, -0.02),
      titleLarge: display(19, FontWeight.w700, 23, -0.01),
      titleMedium: body(16, FontWeight.w700, 22),
      titleSmall: body(14, FontWeight.w600, 20),
      bodyLarge: body(17, FontWeight.w400, 25),
      bodyMedium: body(15, FontWeight.w400, 22),
      bodySmall: body(13, FontWeight.w400, 18,
          color: colors.onSurfaceVariant),
      labelLarge: body(15, FontWeight.w600, 20),
      labelMedium: body(13, FontWeight.w700, 18),
      labelSmall: body(12, FontWeight.w600, 16,
          color: colors.onSurfaceVariant),
    );
  }

  /// The one big number on a hero card — the house `countdown` style.
  ///
  /// Not part of `TextTheme` because Flutter has no slot for it. At most one
  /// per screen; the house document is explicit about that.
  static TextStyle countdown(ColorScheme colors, {Color? color}) {
    return TextStyle(
      fontFamily: fontDisplay,
      fontSize: 88,
      fontWeight: FontWeight.w800,
      height: 72 / 88,
      letterSpacing: 88 * -0.05,
      color: color ?? colors.onSurface,
    );
  }
```

Finally, retarget `numeric` (lines 113-127) to the house `numericTable` metrics:

```dart
  /// Style for anything that must align in a column — set/rep/weight tables,
  /// the rest timer, log rows. The house `numericTable` style.
  ///
  /// Mono, so a digit does not change width between 1 and 8 and a column of
  /// numbers does not shimmer as it counts down. The house document defines
  /// no monospace face of its own; this is deviation register entry D1, and
  /// the role was filed upstream before use.
  static TextStyle numeric(
    BuildContext context, {
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontMono,
      fontSize: size,
      fontWeight: weight,
      height: 22 / 15,
      letterSpacing: 0,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
```

- [ ] **Step 6: Fix every `fontSans` reference**

Run: `C:\src\flutter\bin\flutter.bat analyze`
Expected: errors naming each remaining `LockoutTheme.fontSans` call site. Replace each with `fontBody` if it styles running text, `fontDisplay` if it styles a heading. Re-run until clean.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/fonts_bundled_test.dart test/lockout_theme_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add assets/fonts pubspec.yaml lib/theme/lockout_theme.dart test/fonts_bundled_test.dart
git commit -m "feat(ui): bundle Bricolage Grotesque and Figtree and adopt the house type scale"
```

---

### Task 2: Re-derive the measured layout constants under Figtree

Swapping the body face off Inter invalidates every layout constant that was measured against Inter's metrics. The spec names this as the branch's largest source of churn; it is scoped here rather than discovered during a later task.

**Files:**
- Modify: `lib/theme/lockout_theme.dart:38-60` — the measured constants and their comments
- Test: `test/body_tab_test.dart` (the `statTileHeight` pin), `test/widget_kit_test.dart`

**Interfaces:**
- Consumes: `LockoutTheme.textThemeFor` from Task 1.
- Produces: re-measured values for `statTileHeight`, `controlHeight`, `navBarHeight`, `swatchPreviewHeight`. Names and types are unchanged, so no call site moves.

- [ ] **Step 1: Write the failing measurement test**

Create `test/measured_constants_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_theme.dart';

/// Lays out the real content of a stat tile at a given text scale and
/// returns the height it needs.
double _statTileContentHeight(WidgetTester tester, double scale) {
  final box = tester.renderObject<RenderBox>(find.byKey(const Key('probe')));
  return box.size.height;
}

void main() {
  for (final scale in const [1.0, 1.05, 1.10, 1.15]) {
    testWidgets('a stat tile fits its content at text scale $scale',
        (tester) async {
      final colors = const ColorScheme.light();
      final text = LockoutTheme.textThemeFor(colors);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: IntrinsicHeight(
                  child: Padding(
                    key: const Key('probe'),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weight', style: text.labelSmall),
                        const SizedBox(height: 4),
                        Text('82.5',
                            style: TextStyle(
                              fontFamily: LockoutTheme.fontMono,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final needed = _statTileContentHeight(tester, scale);
      expect(
        LockoutTheme.statTileHeight,
        greaterThanOrEqualTo(needed),
        reason: 'a stat tile clips at text scale $scale: content needs '
            '$needed but statTileHeight is ${LockoutTheme.statTileHeight}',
      );
    });
  }

  testWidgets('a control fits a labelLarge line at text scale 1.15',
      (tester) async {
    final text = LockoutTheme.textThemeFor(const ColorScheme.light());
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.15)),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                key: const Key('probe'),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('Save to routine', style: text.labelLarge),
              ),
            ),
          ),
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(find.byKey(const Key('probe')));
    expect(LockoutTheme.controlHeight, greaterThanOrEqualTo(box.size.height));
    expect(LockoutTheme.controlHeight,
        greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
  });
}
```

- [ ] **Step 2: Run it and read the real numbers**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/measured_constants_test.dart`
Expected: either PASS (Figtree happens to fit inside the Inter-derived values) or FAIL with a message naming the exact height needed, e.g. `a stat tile clips at text scale 1.15: content needs 74.0 but statTileHeight is 72.0`.

- [ ] **Step 3: Raise each constant to the next 8dp step above the measured need**

Only touch a constant the test actually failed on. For each one, set it to the smallest multiple of 8 at or above the reported height, and rewrite its doc comment with the new measurements. For `statTileHeight` the comment becomes:

```dart
  /// The fixed height of a `StatTile` in a stat grid.
  ///
  /// Stated here rather than derived from tile width by a `childAspectRatio`,
  /// because a tile's content height has nothing to do with how wide the
  /// screen is: a ratio makes every narrower column a shorter tile, so the
  /// same grid that fits on a 430dp phone clips on a 360dp one.
  ///
  /// The number is set by text scale, not by design taste. Re-measured
  /// against Figtree when the body face replaced Inter — the label line, the
  /// 4dp gap, the 16pt mono value and the tile's own 12dp padding come to
  /// <measured> at scale 1.0 and <measured> at 1.15. The value below is the
  /// smallest 8dp step that survives Android's "Large" font setting, which
  /// is the largest step a user reaches without opening accessibility
  /// settings. `measured_constants_test.dart` and `body_tab_test.dart` pin
  /// that.
  static const double statTileHeight = <value>;
```

Replace each `<measured>` and `<value>` with the numbers the test printed. Do not leave the angle brackets in the file.

- [ ] **Step 4: Run the test and the two suites that pin these constants**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/measured_constants_test.dart test/body_tab_test.dart test/widget_kit_test.dart`
Expected: PASS. If `body_tab_test.dart` asserts the old literal `72`, update that assertion to read `LockoutTheme.statTileHeight` rather than a hard-coded number, so there is one place the value lives.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/lockout_theme.dart test/measured_constants_test.dart test/body_tab_test.dart test/widget_kit_test.dart
git commit -m "fix(ui,test): re-derive the measured layout constants under Figtree"
```

---

### Task 3: `LockoutMotion` — three tiers and the reduced-motion collapse

**Files:**
- Create: `lib/theme/lockout_motion.dart`
- Test: `test/lockout_motion_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `LockoutMotion.springFast`, `LockoutMotion.springDefault`, `LockoutMotion.effects` — each a `LockoutMotionTier` with `.curve` and `.duration`; `LockoutMotionTier.durationFor(BuildContext)` returning `Duration.zero` when animations are disabled; `LockoutMotion.spring` as the shared `Cubic` constant.

- [ ] **Step 1: Write the failing test**

Create `test/lockout_motion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_motion.dart';

void main() {
  group('the three tiers match the house document', () {
    test('springFast settles in 250ms and overshoots', () {
      expect(LockoutMotion.springFast.duration,
          const Duration(milliseconds: 250));
      expect(LockoutMotion.springFast.curve, LockoutMotion.spring);
    });

    test('springDefault settles in 450ms and overshoots', () {
      expect(LockoutMotion.springDefault.duration,
          const Duration(milliseconds: 450));
      expect(LockoutMotion.springDefault.curve, LockoutMotion.spring);
    });

    test('effects runs 200ms and never overshoots', () {
      expect(LockoutMotion.effects.duration,
          const Duration(milliseconds: 200));

      // The house document states that colour and opacity must not bounce.
      for (var t = 0.0; t <= 1.0; t += 0.01) {
        final v = LockoutMotion.effects.curve.transform(t);
        expect(v, lessThanOrEqualTo(1.0),
            reason: 'effects overshot at t=$t with $v');
        expect(v, greaterThanOrEqualTo(0.0));
      }
    });

    test('the spring curve passes its target and settles back', () {
      var peak = 0.0;
      for (var t = 0.0; t <= 1.0; t += 0.005) {
        final v = LockoutMotion.spring.transform(t);
        if (v > peak) peak = v;
      }
      expect(peak, greaterThan(1.0),
          reason: 'the spring must overshoot, not ease');
      expect(LockoutMotion.spring.transform(1.0), closeTo(1.0, 0.0001));
    });
  });

  group('reduced motion collapses every tier', () {
    testWidgets('each tier reports zero when animations are disabled',
        (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      );

      expect(LockoutMotion.springFast.durationFor(captured), Duration.zero);
      expect(LockoutMotion.springDefault.durationFor(captured), Duration.zero);
      expect(LockoutMotion.effects.durationFor(captured), Duration.zero);
    });

    testWidgets('each tier reports its real duration otherwise',
        (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      );

      expect(LockoutMotion.springFast.durationFor(captured),
          const Duration(milliseconds: 250));
      expect(LockoutMotion.springDefault.durationFor(captured),
          const Duration(milliseconds: 450));
      expect(LockoutMotion.effects.durationFor(captured),
          const Duration(milliseconds: 200));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/lockout_motion_test.dart`
Expected: FAIL — `lib/theme/lockout_motion.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/theme/lockout_motion.dart`:

```dart
import 'package:flutter/material.dart';

/// One named motion tier: a curve and the duration it runs for.
///
/// A value rather than two loose constants, so a call site cannot pair the
/// fast curve with the slow duration.
@immutable
class LockoutMotionTier {
  final Curve curve;
  final Duration duration;

  const LockoutMotionTier({required this.curve, required this.duration});

  /// [duration], or `Duration.zero` when the user has asked the OS to remove
  /// animations.
  ///
  /// Every animated surface in the app reads its duration through this
  /// rather than from [duration] directly. A spring that still overshoots
  /// under "remove animations" is an accessibility regression, not a flourish.
  Duration durationFor(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : duration;
  }
}

/// The app's motion vocabulary — exactly three tiers, no more.
///
/// These map onto the three kinds in
/// `docs/design/nuvetrix-app-design-system.md` section 6. That document
/// specifies Compose springs, which Flutter has no equivalent token for;
/// these match them by settle time instead, and that substitution is entry
/// D3 in the deviation register.
///
/// Framework `Durations` / `Easing` tokens are not used anywhere in the app.
/// Three named tiers that every surface shares is the point: a one-off
/// duration at a call site is how a motion system stops being a system.
class LockoutMotion {
  LockoutMotion._();

  /// Passes its target and settles back. Flutter does not clamp a `Cubic`
  /// above 1.0, so the overshoot is real rather than an eased approximation.
  static const Cubic spring = Cubic(0.2, 1.35, 0.3, 1);

  /// Press morphs, chip selection, the switch thumb.
  static const LockoutMotionTier springFast = LockoutMotionTier(
    curve: spring,
    duration: Duration(milliseconds: 250),
  );

  /// Sheets, screen transitions, card expands.
  static const LockoutMotionTier springDefault = LockoutMotionTier(
    curve: spring,
    duration: Duration(milliseconds: 450),
  );

  /// Colour and opacity. No overshoot: a colour that passes its target
  /// lands on a hue nobody authored.
  static const LockoutMotionTier effects = LockoutMotionTier(
    curve: Curves.easeOut,
    duration: Duration(milliseconds: 200),
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/lockout_motion_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/lockout_motion.dart test/lockout_motion_test.dart
git commit -m "feat(ui): add the three-tier LockoutMotion vocabulary"
```

---

### Task 4: `CookieBorder` — the lobed shape

**Files:**
- Create: `lib/theme/cookie_border.dart`
- Test: `test/cookie_border_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `CookieBorder({required int lobes, required double amplitude, BorderSide side})`, a `ShapeBorder`; the named constants `CookieBorder.rest` (4 lobes, 0.10), `.training` (6, 0.07), `.streak` (9, 0.06), `.achievement` (12, 0.04).

- [ ] **Step 1: Write the failing test**

Create `test/cookie_border_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/cookie_border.dart';

/// Samples the outline's radius at [steps] angles around its centre.
List<double> _radiiOf(CookieBorder border, Rect rect, {int steps = 720}) {
  final path = border.getOuterPath(rect);
  final metrics = path.computeMetrics().toList();
  expect(metrics.length, 1, reason: 'the outline must be one closed contour');
  final metric = metrics.single;

  final centre = rect.center;
  final radii = <double>[];
  for (var i = 0; i < steps; i++) {
    final tangent = metric.getTangentForOffset(metric.length * i / steps)!;
    radii.add((tangent.position - centre).distance);
  }
  return radii;
}

/// Counts how many times the sampled radius turns from rising to falling.
int _lobeCount(List<double> radii) {
  var maxima = 0;
  for (var i = 0; i < radii.length; i++) {
    final prev = radii[(i - 1 + radii.length) % radii.length];
    final next = radii[(i + 1) % radii.length];
    if (radii[i] > prev && radii[i] >= next) maxima++;
  }
  return maxima;
}

void main() {
  const rect = Rect.fromLTWH(0, 0, 100, 100);

  group('geometry', () {
    test('the outline is closed', () {
      final path = const CookieBorder(lobes: 6, amplitude: 0.07)
          .getOuterPath(rect);
      final metric = path.computeMetrics().single;
      expect(metric.isClosed, isTrue);
    });

    for (final border in const [
      CookieBorder.rest,
      CookieBorder.training,
      CookieBorder.streak,
      CookieBorder.achievement,
    ]) {
      test('${border.lobes} lobes produce ${border.lobes} maxima', () {
        expect(_lobeCount(_radiiOf(border, rect)), border.lobes);
      });
    }

    test('amplitude bounds the radius around the base circle', () {
      const border = CookieBorder(lobes: 6, amplitude: 0.07);
      final radii = _radiiOf(border, rect);
      final base = rect.shortestSide / 2;
      expect(radii.reduce(math.max),
          closeTo(base * (1 + 0.07), base * 0.02));
      expect(radii.reduce(math.min),
          closeTo(base * (1 - 0.07), base * 0.02));
    });

    test('an oblong rect still yields a bounded outline', () {
      const border = CookieBorder(lobes: 9, amplitude: 0.06);
      final path = border.getOuterPath(const Rect.fromLTWH(0, 0, 200, 80));
      expect(path.getBounds().width, lessThanOrEqualTo(200));
      expect(path.getBounds().height, lessThanOrEqualTo(80));
    });
  });

  group('lerp', () {
    test('two borders of the same lobe count interpolate their amplitude', () {
      const a = CookieBorder(lobes: 6, amplitude: 0.00);
      const b = CookieBorder(lobes: 6, amplitude: 0.10);
      final mid = ShapeBorder.lerp(a, b, 0.5)! as CookieBorder;
      expect(mid.lobes, 6);
      expect(mid.amplitude, closeTo(0.05, 0.0001));
    });

    test('a lobe-count mismatch asserts rather than drawing a wrong path', () {
      const a = CookieBorder(lobes: 6, amplitude: 0.07);
      const b = CookieBorder(lobes: 9, amplitude: 0.06);
      expect(() => ShapeBorder.lerp(a, b, 0.5), throwsAssertionError);
    });
  });

  group('equality', () {
    test('two borders with the same parameters are equal', () {
      expect(const CookieBorder(lobes: 4, amplitude: 0.1),
          const CookieBorder(lobes: 4, amplitude: 0.1));
    });

    test('the named registers carry the documented parameters', () {
      expect(CookieBorder.rest.lobes, 4);
      expect(CookieBorder.rest.amplitude, 0.10);
      expect(CookieBorder.training.lobes, 6);
      expect(CookieBorder.training.amplitude, 0.07);
      expect(CookieBorder.streak.lobes, 9);
      expect(CookieBorder.streak.amplitude, 0.06);
      expect(CookieBorder.achievement.lobes, 12);
      expect(CookieBorder.achievement.amplitude, 0.04);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/cookie_border_test.dart`
Expected: FAIL — `lib/theme/cookie_border.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/theme/cookie_border.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A polar-rose outline — a circle whose radius rises and falls a fixed
/// number of times around its sweep.
///
/// A `ShapeBorder` rather than a `CustomPainter` so it composes with
/// everything that already takes a shape: `Material`, `ShapeDecoration`,
/// `Card`, `FilledButton`. Pure geometry, which is why
/// `cookie_border_test.dart` can assert it without pumping a widget.
///
/// Lobe count is a *register*, not decoration: 4 rest, 6 training, 9 streak,
/// 12 achievement. That mapping is Lockout's extension of the house system
/// (deviation register D5), and it is why [lerpFrom] refuses to interpolate
/// between two different counts — a shape halfway between "rest" and
/// "streak" means nothing.
@immutable
class CookieBorder extends ShapeBorder {
  /// How many times the radius peaks around the sweep.
  final int lobes;

  /// How far the radius departs from the base circle, as a fraction of it.
  /// 0.07 means the outline runs between 93% and 107% of the base radius.
  final double amplitude;

  final BorderSide side;

  const CookieBorder({
    required this.lobes,
    required this.amplitude,
    this.side = BorderSide.none,
  })  : assert(lobes >= 3, 'fewer than three lobes is not a rose'),
        assert(amplitude >= 0 && amplitude < 1,
            'amplitude is a fraction of the base radius');

  /// A rest day.
  static const CookieBorder rest = CookieBorder(lobes: 4, amplitude: 0.10);

  /// A training day.
  static const CookieBorder training =
      CookieBorder(lobes: 6, amplitude: 0.07);

  /// A streak.
  static const CookieBorder streak = CookieBorder(lobes: 9, amplitude: 0.06);

  /// A completed session.
  static const CookieBorder achievement =
      CookieBorder(lobes: 12, amplitude: 0.04);

  /// Enough samples that a 12-lobed outline still reads as smooth; below
  /// about 12 points per lobe the straight segments become visible at hero
  /// sizes.
  static const int _samplesPerLobe = 24;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final centre = rect.center;

    // The base radius is half the SHORTEST side, so an oblong rect yields a
    // shape that still fits inside it rather than one that spills along the
    // long axis.
    final base = rect.shortestSide / 2;
    final steps = lobes * _samplesPerLobe;
    final path = Path();

    for (var i = 0; i < steps; i++) {
      final angle = 2 * math.pi * i / steps;
      final radius = base * (1 + amplitude * math.cos(lobes * angle));
      final point = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width),
        textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) => CookieBorder(
        lobes: lobes,
        amplitude: amplitude,
        side: side.scale(t),
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is! CookieBorder) return super.lerpFrom(a, t);
    assert(
      a.lobes == lobes,
      'CookieBorder cannot interpolate between ${a.lobes} and $lobes lobes: '
      'lobe count is a register, not a value. Cross-fade the two shapes '
      'instead of morphing one into the other.',
    );
    return CookieBorder(
      lobes: lobes,
      amplitude: lerpDouble(a.amplitude, amplitude, t)!,
      side: BorderSide.lerp(a.side, side, t),
    );
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is! CookieBorder) return super.lerpTo(b, t);
    assert(
      b.lobes == lobes,
      'CookieBorder cannot interpolate between $lobes and ${b.lobes} lobes: '
      'lobe count is a register, not a value. Cross-fade the two shapes '
      'instead of morphing one into the other.',
    );
    return CookieBorder(
      lobes: lobes,
      amplitude: lerpDouble(amplitude, b.amplitude, t)!,
      side: BorderSide.lerp(side, b.side, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CookieBorder &&
      other.lobes == lobes &&
      other.amplitude == amplitude &&
      other.side == side;

  @override
  int get hashCode => Object.hash(lobes, amplitude, side);

  @override
  String toString() => 'CookieBorder(lobes: $lobes, amplitude: $amplitude)';
}
```

`lerpDouble` comes from `dart:ui`, which `package:flutter/material.dart` already re-exports.

- [ ] **Step 4: Run the test to verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/cookie_border_test.dart`
Expected: PASS. If the lobe-count assertions fail by exactly one, the maxima counter has wrapped at the seam — check the `>=` on the `next` comparison in the test helper rather than changing the geometry.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/cookie_border.dart test/cookie_border_test.dart
git commit -m "feat(ui): add CookieBorder, the lobed subject shape"
```

---

### Task 5: The house palette and the accent set

**Files:**
- Create: `lib/theme/accents.dart`
- Create: `lib/theme/palette.dart`
- Test: `test/accents_test.dart`, `test/palette_test.dart`

**Interfaces:**
- Consumes: `LockoutSemantics` (existing, unchanged).
- Produces:
  - `LockoutAccent` — `final String key; final String name; final Color accent; final Color ink;` with `LockoutAccent.lime/.violet/.teal/.coral/.steel`, `LockoutAccent.all`, `LockoutAccent.fallback` (lime), `LockoutAccent.byKey(String)`.
  - `LockoutPalette.schemeFor(Brightness, LockoutAccent)` returning a composed `ColorScheme`.
  - `LockoutPalette.semanticsFor(Brightness, LockoutAccent)` returning a `LockoutSemantics`.

- [ ] **Step 1: Write the failing accent test**

Create `test/accents_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('there are five accents and lime is the default', () {
    expect(LockoutAccent.all.length, 5);
    expect(LockoutAccent.fallback, LockoutAccent.lime);
    expect(LockoutAccent.fallback.key, 'lime');
  });

  test('gold is gone — it belongs to another app in the family', () {
    expect(LockoutAccent.all.map((a) => a.key), isNot(contains('gold')));
    for (final accent in LockoutAccent.all) {
      expect(accent.accent, isNot(const Color(0xFFFFB938)));
    }
  });

  test('every accent carries its ink at 4.5:1 or better', () {
    for (final accent in LockoutAccent.all) {
      expect(_contrast(accent.accent, accent.ink), greaterThanOrEqualTo(4.5),
          reason: '${accent.key} fails the house contrast rule');
    }
  });

  test('the identity accent is Rep lime', () {
    expect(LockoutAccent.lime.accent, const Color(0xFFC2EE7B));
    expect(LockoutAccent.lime.ink, const Color(0xFF1F2E00));
    expect(LockoutAccent.lime.name, 'Rep lime');
  });

  test('byKey maps every legacy scheme key onto an accent', () {
    expect(LockoutAccent.byKey('graphite'), LockoutAccent.steel);
    expect(LockoutAccent.byKey('paper'), LockoutAccent.steel);
    expect(LockoutAccent.byKey('ember'), LockoutAccent.coral);
    expect(LockoutAccent.byKey('linen'), LockoutAccent.coral);
    expect(LockoutAccent.byKey('indigo'), LockoutAccent.violet);
    expect(LockoutAccent.byKey('frost'), LockoutAccent.teal);
    expect(LockoutAccent.byKey('dynamic'), LockoutAccent.lime);
  });

  test('byKey falls back on junk and on an empty string', () {
    expect(LockoutAccent.byKey('not-an-accent'), LockoutAccent.lime);
    expect(LockoutAccent.byKey(''), LockoutAccent.lime);
  });

  test('every accent name is sentence case', () {
    for (final accent in LockoutAccent.all) {
      expect(accent.name, isNot(accent.name.toUpperCase()),
          reason: 'the house document forbids all-caps (section 4.2)');
    }
  });
}
```

- [ ] **Step 2: Write the failing palette test**

Create `test/palette_test.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/theme/palette.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('the neutrals come from the house document', () {
    test('light surfaces and ink are exact', () {
      final s = LockoutPalette.schemeFor(
          Brightness.light, LockoutAccent.lime);
      expect(s.surface, const Color(0xFFFBF9FF));
      expect(s.surfaceContainer, const Color(0xFFF1EEF8));
      expect(s.surfaceContainerHigh, const Color(0xFFE8E4F2));
      expect(s.surfaceContainerHighest, const Color(0xFFDDD8EC));
      expect(s.onSurface, const Color(0xFF16132E));
      expect(s.onSurfaceVariant, const Color(0xFF4A4663));
      expect(s.outline, const Color(0xFF77728F));
      expect(s.outlineVariant, const Color(0xFFCAC5DA));
      expect(s.secondaryContainer, const Color(0xFFE4DFFF));
      expect(s.tertiary, const Color(0xFF5B3FE0));
      expect(s.error, const Color(0xFFB3261E));
    });

    test('dark surfaces and ink are exact', () {
      final s = LockoutPalette.schemeFor(
          Brightness.dark, LockoutAccent.lime);
      expect(s.surface, const Color(0xFF131124));
      expect(s.surfaceContainer, const Color(0xFF1C1A33));
      expect(s.surfaceContainerHigh, const Color(0xFF25223F));
      expect(s.surfaceContainerHighest, const Color(0xFF302D4C));
      expect(s.onSurface, const Color(0xFFEDEAF7));
      expect(s.onSurfaceVariant, const Color(0xFFC3BED7));
      expect(s.outline, const Color(0xFF938EAB));
      expect(s.outlineVariant, const Color(0xFF46425F));
      expect(s.secondaryContainer, const Color(0xFF342D6B));
      expect(s.tertiary, const Color(0xFFB9A8FF));
      expect(s.error, const Color(0xFFF2B8B5));
    });
  });

  group('the accent occupies the roles the house document gives it', () {
    test('in light, the accent is the container and primary is fixed', () {
      for (final accent in LockoutAccent.all) {
        final s = LockoutPalette.schemeFor(Brightness.light, accent);
        expect(s.primaryContainer, accent.accent);
        expect(s.onPrimaryContainer, accent.ink);
        expect(s.primary, const Color(0xFF2E2766),
            reason: 'light primary is the same for every accent');
        expect(s.onPrimary, const Color(0xFFFFFFFF));
      }
    });

    test('in dark, the accent is both primary and the container', () {
      for (final accent in LockoutAccent.all) {
        final s = LockoutPalette.schemeFor(Brightness.dark, accent);
        expect(s.primary, accent.accent);
        expect(s.onPrimary, accent.ink);
        expect(s.primaryContainer, accent.accent);
        expect(s.onPrimaryContainer, accent.ink);
      }
    });

    test('brightness is carried through', () {
      expect(LockoutPalette.schemeFor(Brightness.dark, LockoutAccent.teal)
          .brightness, Brightness.dark);
      expect(LockoutPalette.schemeFor(Brightness.light, LockoutAccent.teal)
          .brightness, Brightness.light);
    });
  });

  group('semantics', () {
    test('success is the house success pair in both brightnesses', () {
      final light = LockoutPalette.semanticsFor(
          Brightness.light, LockoutAccent.lime);
      final dark = LockoutPalette.semanticsFor(
          Brightness.dark, LockoutAccent.lime);
      expect(light.success, const Color(0xFF1E6E47));
      expect(dark.success, const Color(0xFF7ED3A4));
    });

    test('the chart line follows the accent', () {
      for (final accent in LockoutAccent.all) {
        final semantics =
            LockoutPalette.semanticsFor(Brightness.dark, accent);
        expect(semantics.chartLine, accent.accent);
      }
    });

    test('there are two ramps, one per brightness, not one per accent', () {
      final a = LockoutPalette.semanticsFor(
          Brightness.dark, LockoutAccent.lime).categoryRamp;
      final b = LockoutPalette.semanticsFor(
          Brightness.dark, LockoutAccent.coral).categoryRamp;
      expect(a, b);
    });

    test('every ramp entry clears 3.0 against its own surface', () {
      for (final brightness in Brightness.values) {
        final scheme =
            LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        final semantics =
            LockoutPalette.semanticsFor(brightness, LockoutAccent.lime);
        for (final colour in semantics.categoryRamp) {
          expect(_contrast(colour, scheme.surface),
              greaterThanOrEqualTo(3.0),
              reason: '$colour is unreadable on $brightness surface');
        }
      }
    });

    test('the ramp has eight entries, as categoryAt assumes', () {
      expect(
        LockoutPalette.semanticsFor(Brightness.dark, LockoutAccent.lime)
            .categoryRamp.length,
        8,
      );
    });

    test('danger and error stay distinguishable from success', () {
      for (final brightness in Brightness.values) {
        final scheme =
            LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        final semantics =
            LockoutPalette.semanticsFor(brightness, LockoutAccent.lime);
        expect(semantics.danger, isNot(semantics.success));
        expect(scheme.error, isNot(semantics.success));
      }
    });

    test('semantics is a LockoutSemantics, not a bare record', () {
      expect(
        LockoutPalette.semanticsFor(Brightness.light, LockoutAccent.lime),
        isA<LockoutSemantics>(),
      );
    });
  });

  // These two groups carry over the guarantees `schemes_test.dart` held
  // across six schemes. That file is deleted in Task 6, so they live here
  // now, widened from six schemes to the ten brightness-and-accent
  // combinations that replace them.
  group('contrast across all ten combinations', () {
    test('primary and its foreground clear 4.5:1 everywhere', () {
      for (final brightness in Brightness.values) {
        for (final accent in LockoutAccent.all) {
          final s = LockoutPalette.schemeFor(brightness, accent);
          expect(_contrast(s.primary, s.onPrimary),
              greaterThanOrEqualTo(4.5),
              reason: '$brightness + ${accent.key} primary pairing');
          expect(_contrast(s.primaryContainer, s.onPrimaryContainer),
              greaterThanOrEqualTo(4.5),
              reason: '$brightness + ${accent.key} container pairing');
        }
      }
    });

    test('body text clears 4.5:1 on every surface step', () {
      for (final brightness in Brightness.values) {
        final s = LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        for (final surface in [
          s.surface,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ]) {
          expect(_contrast(s.onSurface, surface),
              greaterThanOrEqualTo(4.5));
          expect(_contrast(s.onSurfaceVariant, surface),
              greaterThanOrEqualTo(4.5));
        }
      }
    });
  });

  group('the snackbar pairing', () {
    // The house document's section 8 specifies an `onSurface` background
    // with `surface` text, which is exactly what the inverse pair means.
    // The old assertion targeted `inversePrimary`; this is the retarget.
    test('inverseSurface is onSurface and onInverseSurface is surface', () {
      for (final brightness in Brightness.values) {
        final s = LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        expect(s.inverseSurface, s.onSurface);
        expect(s.onInverseSurface, s.surface);
      }
    });

    test('the snackbar pairing clears 4.5:1 for every accent', () {
      for (final brightness in Brightness.values) {
        for (final accent in LockoutAccent.all) {
          final s = LockoutPalette.schemeFor(brightness, accent);
          expect(_contrast(s.inverseSurface, s.onInverseSurface),
              greaterThanOrEqualTo(4.5));
          expect(_contrast(s.inverseSurface, s.inversePrimary),
              greaterThanOrEqualTo(4.5),
              reason: 'a SnackBarAction label must be readable');
        }
      }
    });
  });
}
```

- [ ] **Step 3: Run both tests to verify they fail**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/accents_test.dart test/palette_test.dart`
Expected: FAIL — neither `lib/theme/accents.dart` nor `lib/theme/palette.dart` exists.

- [ ] **Step 4: Write `lib/theme/accents.dart`**

```dart
import 'package:flutter/material.dart';

/// One selectable accent: a colour and the ink that is legible on it.
///
/// A pair rather than a single hex, because the house system uses the accent
/// as a *container* tone — a filled surface with dark text on it — not as a
/// text colour. `docs/design/nuvetrix-app-design-system.md` section 3.3.
@immutable
class LockoutAccent {
  /// The value persisted in the `theme_key` setting.
  final String key;

  /// What the picker calls it. Sentence case; the house document forbids
  /// all-caps labels.
  final String name;

  /// The fill. In light it is `primaryContainer`; in dark it is both
  /// `primary` and `primaryContainer`.
  final Color accent;

  /// The foreground painted on [accent]. A very dark shade of the accent's
  /// own hue rather than pure black, per the house rules.
  final Color ink;

  const LockoutAccent({
    required this.key,
    required this.name,
    required this.accent,
    required this.ink,
  });

  /// Lockout's identity accent, registered in the house accents table.
  ///
  /// Hue 81 degrees — the widest gap open in the family — at a lightness
  /// inside the house's 75-85% band, and far from both Google Play green and
  /// the reserved Nuvetrix ultramarine.
  static const LockoutAccent lime = LockoutAccent(
    key: 'lime',
    name: 'Rep lime',
    accent: Color(0xFFC2EE7B),
    ink: Color(0xFF1F2E00),
  );

  static const LockoutAccent violet = LockoutAccent(
    key: 'violet',
    name: 'Violet',
    accent: Color(0xFFB9A8FF),
    ink: Color(0xFF21105E),
  );

  static const LockoutAccent teal = LockoutAccent(
    key: 'teal',
    name: 'Teal',
    accent: Color(0xFF6ED6C4),
    ink: Color(0xFF00382F),
  );

  static const LockoutAccent coral = LockoutAccent(
    key: 'coral',
    name: 'Coral',
    accent: Color(0xFFFF9E8A),
    ink: Color(0xFF4A0E00),
  );

  /// The neutral. Not in the house's optional set — deviation register D6.
  /// Without it, every `graphite` and `paper` user would migrate onto a hue
  /// they never chose.
  static const LockoutAccent steel = LockoutAccent(
    key: 'steel',
    name: 'Steel',
    accent: Color(0xFFA9B4C6),
    ink: Color(0xFF1B2430),
  );

  static const List<LockoutAccent> all = [lime, violet, teal, coral, steel];

  /// The accent on a fresh install, and the destination for anything
  /// unrecognised.
  static const LockoutAccent fallback = lime;

  /// The six retired scheme keys, each mapped to the accent closest to the
  /// hue the user actually chose.
  ///
  /// `linen` lands on coral because coral is the only warm accent available;
  /// mapping it to steel instead would collapse two distinct old choices
  /// onto one new one. `dynamic` lands on the default, because Material You
  /// is gone and there is no hue to preserve.
  static const Map<String, String> _legacyKeys = {
    'graphite': 'steel',
    'paper': 'steel',
    'ember': 'coral',
    'linen': 'coral',
    'indigo': 'violet',
    'frost': 'teal',
    'dynamic': 'lime',
  };

  /// Resolves a stored or legacy key. Never throws; junk becomes [fallback].
  static LockoutAccent byKey(String key) {
    final resolved = _legacyKeys[key] ?? key;
    for (final accent in all) {
      if (accent.key == resolved) return accent;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      other is LockoutAccent && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'LockoutAccent($key)';
}
```

- [ ] **Step 5: Write `lib/theme/palette.dart`**

```dart
import 'package:flutter/material.dart';

import 'accents.dart';
import 'lockout_semantics.dart';

/// The house neutral palette, composed with a selectable accent.
///
/// Every colour below is copied from
/// `docs/design/nuvetrix-app-design-system.md` section 3. The four roles the
/// house document does not name — `surfaceContainerLow`,
/// `surfaceContainerLowest`, `secondary` and the inverse trio — are
/// interpolated from the ones it does, and are marked where they appear.
class LockoutPalette {
  LockoutPalette._();

  // House section 3.1 — light.
  static const Color _lightSurface = Color(0xFFFBF9FF);
  static const Color _lightContainer = Color(0xFFF1EEF8);
  static const Color _lightContainerHigh = Color(0xFFE8E4F2);
  static const Color _lightContainerHighest = Color(0xFFDDD8EC);
  static const Color _ink = Color(0xFF16132E);
  static const Color _lightOnSurfaceVariant = Color(0xFF4A4663);
  static const Color _lightOutline = Color(0xFF77728F);
  static const Color _lightOutlineVariant = Color(0xFFCAC5DA);
  static const Color _lightPrimary = Color(0xFF2E2766);
  static const Color _lightSecondaryContainer = Color(0xFFE4DFFF);
  static const Color _lightOnSecondaryContainer = Color(0xFF231A5C);
  static const Color _lightTertiary = Color(0xFF5B3FE0);
  static const Color _lightTertiaryContainer = Color(0xFFE6DEFF);
  static const Color _lightOnTertiaryContainer = Color(0xFF21105E);
  static const Color _lightError = Color(0xFFB3261E);
  static const Color _lightErrorContainer = Color(0xFFF9DEDC);
  static const Color _lightOnErrorContainer = Color(0xFF410E0B);

  // House section 3.2 — dark.
  static const Color _darkSurface = Color(0xFF131124);
  static const Color _darkContainer = Color(0xFF1C1A33);
  static const Color _darkContainerHigh = Color(0xFF25223F);
  static const Color _darkContainerHighest = Color(0xFF302D4C);
  static const Color _darkOnSurface = Color(0xFFEDEAF7);
  static const Color _darkOnSurfaceVariant = Color(0xFFC3BED7);
  static const Color _darkOutline = Color(0xFF938EAB);
  static const Color _darkOutlineVariant = Color(0xFF46425F);
  static const Color _darkSecondaryContainer = Color(0xFF342D6B);
  static const Color _darkOnSecondaryContainer = Color(0xFFE4DFFF);
  static const Color _darkTertiary = Color(0xFFB9A8FF);
  static const Color _darkTertiaryContainer = Color(0xFF3C2C8F);
  static const Color _darkOnTertiaryContainer = Color(0xFFE6DEFF);
  static const Color _darkError = Color(0xFFF2B8B5);
  static const Color _darkErrorContainer = Color(0xFF601410);
  static const Color _darkOnErrorContainer = Color(0xFFF9DEDC);

  // Interpolated: the house document stops at `surfaceContainer`, but
  // Flutter's ColorScheme has two steps below it and the bottom-sheet theme
  // already reads `surfaceContainerLow`.
  static const Color _lightContainerLow = Color(0xFFF6F3FC);
  static const Color _lightContainerLowest = Color(0xFFFFFFFF);
  static const Color _darkContainerLow = Color(0xFF181630);
  static const Color _darkContainerLowest = Color(0xFF0E0C1C);

  // Interpolated: `secondary` has no house entry; it is the solid tone of
  // the secondary container pair the house does define.
  static const Color _lightSecondary = Color(0xFF4C4680);
  static const Color _darkSecondary = Color(0xFFC7C0F5);

  // House section 8 states the snackbar is `onSurface` behind `surface`
  // text, which is exactly what the inverse pair means.
  static const Color _lightInverseSurface = _ink;
  static const Color _lightOnInverseSurface = _lightSurface;
  static const Color _darkInverseSurface = _darkOnSurface;
  static const Color _darkOnInverseSurface = _darkSurface;

  // House section 3.1 custom roles.
  static const Color _lightSuccess = Color(0xFF1E6E47);
  static const Color _lightSuccessContainer = Color(0xFFCDEFD9);
  static const Color _darkSuccess = Color(0xFF7ED3A4);
  static const Color _darkSuccessContainer = Color(0xFF0F3D27);

  /// Eight colours for telling many categories apart at a glance.
  ///
  /// Authored per brightness rather than derived from the accent. Rotating
  /// one hue through HSL collided two same-category days onto a single
  /// colour and produced muddy mid-tones; that finding predates this
  /// redesign and still holds. Two ramps now, not six.
  static const List<Color> _lightRamp = [
    Color(0xFF3F6B2E),
    Color(0xFF1D5C78),
    Color(0xFF6B3F8C),
    Color(0xFF8C4A1F),
    Color(0xFF0F6B5C),
    Color(0xFF7A2F55),
    Color(0xFF3E4A6B),
    Color(0xFF6B5C0F),
  ];

  static const List<Color> _darkRamp = [
    Color(0xFFB5DE94),
    Color(0xFF8FD0EC),
    Color(0xFFD3B2F0),
    Color(0xFFF0B48C),
    Color(0xFF7FD9C8),
    Color(0xFFF0A3C4),
    Color(0xFFAEB8DE),
    Color(0xFFDECE8F),
  ];

  /// The `ColorScheme` for a brightness and accent.
  ///
  /// In light the accent fills the container pair and `primary` is the fixed
  /// house indigo for every accent — the accent is for emphasis on two or
  /// three elements per screen, not for every filled button. In dark the
  /// accent fills `primary` as well, because a dark surface needs the
  /// brighter tone to carry.
  static ColorScheme schemeFor(Brightness brightness, LockoutAccent accent) {
    if (brightness == Brightness.light) {
      return ColorScheme(
        brightness: Brightness.light,
        primary: _lightPrimary,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: accent.accent,
        onPrimaryContainer: accent.ink,
        secondary: _lightSecondary,
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: _lightSecondaryContainer,
        onSecondaryContainer: _lightOnSecondaryContainer,
        tertiary: _lightTertiary,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: _lightTertiaryContainer,
        onTertiaryContainer: _lightOnTertiaryContainer,
        error: _lightError,
        onError: const Color(0xFFFFFFFF),
        errorContainer: _lightErrorContainer,
        onErrorContainer: _lightOnErrorContainer,
        surface: _lightSurface,
        onSurface: _ink,
        onSurfaceVariant: _lightOnSurfaceVariant,
        surfaceContainerLowest: _lightContainerLowest,
        surfaceContainerLow: _lightContainerLow,
        surfaceContainer: _lightContainer,
        surfaceContainerHigh: _lightContainerHigh,
        surfaceContainerHighest: _lightContainerHighest,
        outline: _lightOutline,
        outlineVariant: _lightOutlineVariant,
        inverseSurface: _lightInverseSurface,
        onInverseSurface: _lightOnInverseSurface,
        inversePrimary: accent.accent,
        scrim: _ink,
        shadow: _ink,
        surfaceTint: Colors.transparent,
      );
    }

    return ColorScheme(
      brightness: Brightness.dark,
      primary: accent.accent,
      onPrimary: accent.ink,
      primaryContainer: accent.accent,
      onPrimaryContainer: accent.ink,
      secondary: _darkSecondary,
      onSecondary: _darkSecondaryContainer,
      secondaryContainer: _darkSecondaryContainer,
      onSecondaryContainer: _darkOnSecondaryContainer,
      tertiary: _darkTertiary,
      onTertiary: _lightOnTertiaryContainer,
      tertiaryContainer: _darkTertiaryContainer,
      onTertiaryContainer: _darkOnTertiaryContainer,
      error: _darkError,
      onError: _darkErrorContainer,
      errorContainer: _darkErrorContainer,
      onErrorContainer: _darkOnErrorContainer,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      surfaceContainerLowest: _darkContainerLowest,
      surfaceContainerLow: _darkContainerLow,
      surfaceContainer: _darkContainer,
      surfaceContainerHigh: _darkContainerHigh,
      surfaceContainerHighest: _darkContainerHighest,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      inverseSurface: _darkInverseSurface,
      onInverseSurface: _darkOnInverseSurface,
      inversePrimary: _lightPrimary,
      scrim: const Color(0xFF000000),
      shadow: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
    );
  }

  /// The roles Material 3 has none for.
  ///
  /// `chartLine` follows the accent so the one chart on screen reads as the
  /// user's colour; everything else is fixed per brightness.
  static LockoutSemantics semanticsFor(
    Brightness brightness,
    LockoutAccent accent,
  ) {
    final light = brightness == Brightness.light;
    final success = light ? _lightSuccess : _darkSuccess;
    return LockoutSemantics(
      success: success,
      onSuccess: light ? const Color(0xFFFFFFFF) : const Color(0xFF0F3D27),
      warning: light ? const Color(0xFF8A5A00) : const Color(0xFFE8C06A),
      danger: light ? _lightError : _darkError,
      restDay: light ? _lightOnSurfaceVariant : _darkOnSurfaceVariant,
      chartLine: accent.accent,
      chartFill: light
          ? _lightSuccessContainer
          : _darkSuccessContainer,
      categoryRamp: light ? _lightRamp : _darkRamp,
    );
  }
}
```

- [ ] **Step 6: Run both tests to verify they pass**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/accents_test.dart test/palette_test.dart`
Expected: PASS. If a ramp entry fails the 3.0 contrast check, darken it (light ramp) or lighten it (dark ramp) by one step and re-run; do not lower the threshold.

- [ ] **Step 7: Commit**

```bash
git add lib/theme/accents.dart lib/theme/palette.dart test/accents_test.dart test/palette_test.dart
git commit -m "feat(ui): add the house palette and the five-accent set"
```

---

### Task 6: `ThemeController` — two axes, the migration, and removing `dynamic_color`

**Files:**
- Modify: `lib/theme/theme_controller.dart` (rewrite)
- Modify: `lib/main.dart:1,25-58` — drop `DynamicColorBuilder`
- Delete: `lib/theme/schemes.dart`, `test/schemes_test.dart`
- Test: `test/theme_controller_test.dart` (rewrite), `test/no_legacy_theme_test.dart` (extend)

**Interfaces:**
- Consumes: `LockoutAccent`, `LockoutPalette` (Task 5); `LockoutTheme.build` (unchanged).
- Produces: `ThemeController.brightnessChoice` (`LockoutBrightnessChoice`), `.accent` (`LockoutAccent`), `.selectBrightness(LockoutBrightnessChoice)`, `.selectAccent(LockoutAccent)`, and the existing `.lightTheme` / `.darkTheme` / `.themeMode` / `.load()` / `.resetForTest()`. `.selectedKey`, `.pickerKeys`, `.dynamicAvailable` and `.setDynamicSchemes` are REMOVED.

- [ ] **Step 1: Write the failing migration test**

Replace `test/theme_controller_test.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/theme_controller.dart';

import 'test_helpers.dart';

Future<void> _loadWithSetting(String? value) async {
  await resetTestDatabase();
  if (value != null) {
    await DatabaseService.instance.saveSetting('theme_key', value);
  }
  ThemeController.instance.resetForTest();
  await ThemeController.instance.load();
}

void main() {
  setUp(() async {
    await resetTestDatabase();
    ThemeController.instance.resetForTest();
  });

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
      expect(ThemeController.instance.darkTheme!.colorScheme.primary,
          LockoutAccent.teal.accent);
    });
  });

  test('Material You is gone', () {
    // These four members defined the removed third axis. Their absence is
    // what makes the house document's section 2 true of this app.
    expect(ThemeController.instance.toString(), isNotEmpty);
    // ignore: unnecessary_type_check
    expect(ThemeController.instance is ChangeNotifier, isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/theme_controller_test.dart`
Expected: FAIL — `LockoutBrightnessChoice` is undefined and `ThemeController` has no `accent`.

- [ ] **Step 3: Rewrite `ThemeController`**

Replace `lib/theme/theme_controller.dart` entirely:

```dart
import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'accents.dart';
import 'lockout_theme.dart';
import 'palette.dart';

/// The brightness axis: what the user asked for, not what is on screen.
///
/// `system` is a real choice rather than the absence of one, which is why it
/// is a value here instead of a null brightness.
enum LockoutBrightnessChoice {
  system('system'),
  light('light'),
  dark('dark');

  const LockoutBrightnessChoice(this.key);

  final String key;

  static LockoutBrightnessChoice byKey(String key) {
    for (final choice in values) {
      if (choice.key == key) return choice;
    }
    return system;
  }
}

/// Owns which appearance is active and turns it into `ThemeData`.
///
/// A `ChangeNotifier` rather than an `InheritedWidget` of its own: the app
/// root listens once and rebuilds `MaterialApp`, which is all the framework
/// needs to repaint every `Theme.of(context)` reader beneath it.
///
/// Two axes, not three. Material You was removed with the `dynamic_color`
/// dependency because the house system forbids wallpaper-derived colour
/// (section 2): an app whose surfaces come from the phone stops looking like
/// the family it belongs to.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _settingKey = 'theme_key';

  /// The two axes are stored in one setting as `brightness|accent`, so the
  /// schema does not change. A single separator rather than JSON: there are
  /// exactly two fields and there always will be.
  static const String _separator = '|';

  LockoutBrightnessChoice _brightness = LockoutBrightnessChoice.system;
  LockoutAccent _accent = LockoutAccent.fallback;

  LockoutBrightnessChoice get brightnessChoice => _brightness;
  LockoutAccent get accent => _accent;

  ThemeData get lightTheme => LockoutTheme.build(
        colors: LockoutPalette.schemeFor(Brightness.light, _accent),
        semantics: LockoutPalette.semanticsFor(Brightness.light, _accent),
      );

  /// Always non-null now.
  ///
  /// The old controller returned null unless a dynamic scheme was in force,
  /// because an authored scheme carried its own brightness and offering a
  /// second one would let the system override an explicit choice. With
  /// brightness as its own axis that problem is gone: `themeMode` says which
  /// of the two to use, so both can always be supplied.
  ThemeData get darkTheme => LockoutTheme.build(
        colors: LockoutPalette.schemeFor(Brightness.dark, _accent),
        semantics: LockoutPalette.semanticsFor(Brightness.dark, _accent),
      );

  ThemeMode get themeMode => switch (_brightness) {
        LockoutBrightnessChoice.system => ThemeMode.system,
        LockoutBrightnessChoice.light => ThemeMode.light,
        LockoutBrightnessChoice.dark => ThemeMode.dark,
      };

  /// Reads the saved choice. Call before the first frame so the app never
  /// flashes the default theme on top of the chosen one.
  ///
  /// Writes back whenever the stored value was in the old format, so the
  /// migration happens once rather than on every launch.
  Future<void> load() async {
    final saved = await DatabaseService.instance
        .getSetting(_settingKey, defaultValue: '');
    final (brightness, accent) = _resolve(saved);
    _brightness = brightness;
    _accent = accent;

    final canonical = _encode(brightness, accent);
    if (saved != canonical) {
      await DatabaseService.instance.saveSetting(_settingKey, canonical);
    }
    notifyListeners();
  }

  Future<void> selectBrightness(LockoutBrightnessChoice choice) async {
    if (choice == _brightness) return;
    _brightness = choice;
    await _persist();
    notifyListeners();
  }

  Future<void> selectAccent(LockoutAccent accent) async {
    if (accent == _accent) return;
    _accent = accent;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => DatabaseService.instance
      .saveSetting(_settingKey, _encode(_brightness, _accent));

  static String _encode(
    LockoutBrightnessChoice brightness,
    LockoutAccent accent,
  ) =>
      '${brightness.key}$_separator${accent.key}';

  /// Reads either format.
  ///
  /// A stored value with no separator is one of the six retired scheme keys
  /// (or junk). Each maps to the brightness it was authored at and the
  /// accent closest to its hue; `dynamic` maps to the fresh-install default,
  /// because Material You no longer exists and there is no hue to preserve.
  /// Junk falls back rather than throwing, and the caller rewrites the
  /// setting — it is never cleared.
  static (LockoutBrightnessChoice, LockoutAccent) _resolve(String saved) {
    if (saved.contains(_separator)) {
      final parts = saved.split(_separator);
      return (
        LockoutBrightnessChoice.byKey(parts.first),
        LockoutAccent.byKey(parts.length > 1 ? parts[1] : ''),
      );
    }

    const legacyBrightness = <String, LockoutBrightnessChoice>{
      'graphite': LockoutBrightnessChoice.dark,
      'ember': LockoutBrightnessChoice.dark,
      'indigo': LockoutBrightnessChoice.dark,
      'paper': LockoutBrightnessChoice.light,
      'linen': LockoutBrightnessChoice.light,
      'frost': LockoutBrightnessChoice.light,
      'dynamic': LockoutBrightnessChoice.system,
    };

    return (
      legacyBrightness[saved] ?? LockoutBrightnessChoice.system,
      LockoutAccent.byKey(saved),
    );
  }

  /// Returns the controller to its fresh-install state.
  ///
  /// The singleton outlives an individual test, so without this a suite that
  /// selected `coral` would leak that choice into the next one.
  @visibleForTesting
  void resetForTest() {
    _brightness = LockoutBrightnessChoice.system;
    _accent = LockoutAccent.fallback;
  }
}
```

- [ ] **Step 4: Strip `DynamicColorBuilder` out of `lib/main.dart`**

Delete line 1 (`import 'package:dynamic_color/dynamic_color.dart';`) and replace the whole `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      // MainScreen is written without `const` only because its constructor
      // is not const. It is not a theme requirement: see the note at the top
      // of `widgets/day_block.dart`, which works through why a const child
      // cannot be stranded in the old theme (anything reading
      // `Theme.of(context)` is rebuilt through its `InheritedWidget`
      // dependency, not through its parent) and names this call site as one
      // that could be const today. No key either: a changing key would
      // remount the tabs and discard an in-progress live session.
      builder: (_, _) => MaterialApp(
        title: 'LOCKOUT',
        debugShowCheckedModeBanner: false,
        theme: ThemeController.instance.lightTheme,
        darkTheme: ThemeController.instance.darkTheme,
        themeMode: ThemeController.instance.themeMode,
        home: MainScreen(),
      ),
    );
  }
```

- [ ] **Step 5: Remove `schemes.dart` and its test**

```bash
git rm lib/theme/schemes.dart test/schemes_test.dart
```

Run: `C:\src\flutter\bin\flutter.bat analyze`
Expected: errors at every remaining `LockoutScheme` import. Replace each: a reference to `LockoutScheme.fallback.key` becomes `LockoutAccent.fallback.key`; a reference to `scheme.colors` becomes `LockoutPalette.schemeFor(...)`. Re-run until clean.

- [ ] **Step 6: Extend the legacy guard**

In `test/no_legacy_theme_test.dart`, add:

```dart
  test('no source file imports the retired scheme module', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('schemes.dart'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });

  test('no source file reaches for dynamic colour', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) =>
            f.readAsStringSync().contains('dynamic_color') ||
            f.readAsStringSync().contains('DynamicColorBuilder'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'the house document forbids dynamic colour (section 2)');
  });
```

- [ ] **Step 7: Run the full suite**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1`
Expected: PASS. Suites that pumped a scheme name into the picker will fail here; fix each to drive `selectAccent` / `selectBrightness` instead.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat(ui): rebuild ThemeController on two axes and drop dynamic_color"
```

---

### Task 7: Shape-as-state primitives and the house corner scale

**Files:**
- Modify: `lib/theme/lockout_theme.dart:16-22` — the radius constants become rest/active pairs
- Create: `lib/widgets/morphing_surface.dart`
- Create: `lib/widgets/connected_group.dart`
- Test: `test/morphing_surface_test.dart`, `test/connected_group_test.dart`, `test/lockout_theme_test.dart` (extend)

**Interfaces:**
- Consumes: `LockoutMotion` (Task 3).
- Produces:
  - `LockoutTheme.radiusButtonRest = 999`, `radiusButtonActive = 12`, `radiusButtonLargeActive = 16`, `radiusRowRest = 8`, `radiusRowActive = 20`, `radiusChipRest = 12`, `radiusChipActive = 999`, `radiusSegmentInner = 8`, `radiusSegmentEnd = 22`, `radiusSwatchRest = 18`, `radiusSwatchActive = 26`, `radiusGroupEnd = 26`, `radiusDialog = 32`, `radiusSheet = 32`, `radiusField = 16`, `radiusPill = 999`, `pressScale = 0.97`, `groupGap = 3`, `sectionGap = 28`.
  - `LockoutTheme.heroCardShape` — a `RoundedRectangleBorder` with 36dp on three corners and 12dp bottom-left.
  - `MorphingSurface({Key?, required double restRadius, required double activeRadius, required bool active, double activeScale = 1.0, Color? color, required Widget child})`.
  - `ConnectedGroup({Key?, required List<Widget> children})`.

- [ ] **Step 1: Write the failing `MorphingSurface` test**

Create `test/morphing_surface_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_motion.dart';
import 'package:lockout/widgets/morphing_surface.dart';

double _radiusOf(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first);
  final decoration = container.decoration! as BoxDecoration;
  return (decoration.borderRadius! as BorderRadius).topLeft.x;
}

Widget _host({required bool active, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      home: Scaffold(
        body: MorphingSurface(
          restRadius: 24,
          activeRadius: 12,
          active: active,
          child: const SizedBox(width: 120, height: 48),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('it paints the rest radius when inactive', (tester) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 24);
  });

  testWidgets('it morphs to the active radius', (tester) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(active: true));
    await tester.pump(const Duration(milliseconds: 60));
    final midway = _radiusOf(tester);
    expect(midway, lessThan(24),
        reason: 'the radius must be in motion, not snapped');

    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 12);
  });

  testWidgets('it uses the fast tier, not a one-off duration',
      (tester) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();
    final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first);
    expect(container.duration, LockoutMotion.springFast.duration);
    expect(container.curve, LockoutMotion.springFast.curve);
  });

  testWidgets('reduced motion snaps instead of springing', (tester) async {
    await tester.pumpWidget(_host(active: false, reduceMotion: true));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(active: true, reduceMotion: true));
    await tester.pump();
    expect(_radiusOf(tester), 12,
        reason: 'the morph must be instant under "remove animations"');
  });

  testWidgets('an active scale shrinks the surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MorphingSurface(
            restRadius: 999,
            activeRadius: 12,
            active: true,
            activeScale: 0.97,
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 0.97);
  });
}
```

- [ ] **Step 2: Write the failing `ConnectedGroup` test**

Create `test/connected_group_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/connected_group.dart';

List<BorderRadius> _radiiOf(WidgetTester tester) {
  return tester
      .widgetList<ClipRRect>(find.descendant(
        of: find.byType(ConnectedGroup),
        matching: find.byType(ClipRRect),
      ))
      .map((c) => c.borderRadius as BorderRadius)
      .toList();
}

void main() {
  Widget host(int count) => MaterialApp(
        home: Scaffold(
          body: ConnectedGroup(
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(key: ValueKey(i), height: 72, child: Text('row $i')),
            ],
          ),
        ),
      );

  testWidgets('the first and last child carry the large outer corners',
      (tester) async {
    await tester.pumpWidget(host(4));
    await tester.pumpAndSettle();

    final radii = _radiiOf(tester);
    expect(radii.length, 4);

    expect(radii.first.topLeft.x, LockoutTheme.radiusGroupEnd);
    expect(radii.first.topRight.x, LockoutTheme.radiusGroupEnd);
    expect(radii.first.bottomLeft.x, LockoutTheme.radiusRowRest);

    expect(radii.last.bottomLeft.x, LockoutTheme.radiusGroupEnd);
    expect(radii.last.bottomRight.x, LockoutTheme.radiusGroupEnd);
    expect(radii.last.topLeft.x, LockoutTheme.radiusRowRest);
  });

  testWidgets('inner children are small on every corner', (tester) async {
    await tester.pumpWidget(host(4));
    await tester.pumpAndSettle();

    final middle = _radiiOf(tester)[1];
    expect(middle.topLeft.x, LockoutTheme.radiusRowRest);
    expect(middle.bottomRight.x, LockoutTheme.radiusRowRest);
  });

  testWidgets('a single child is large on all four corners', (tester) async {
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle();

    final only = _radiiOf(tester).single;
    expect(only.topLeft.x, LockoutTheme.radiusGroupEnd);
    expect(only.bottomRight.x, LockoutTheme.radiusGroupEnd);
  });

  testWidgets('children sit 3dp apart', (tester) async {
    await tester.pumpWidget(host(3));
    await tester.pumpAndSettle();

    final boxes = tester
        .widgetList<SizedBox>(find.descendant(
          of: find.byType(ConnectedGroup),
          matching: find.byType(SizedBox),
        ))
        .where((b) => b.height == LockoutTheme.groupGap);
    expect(boxes.length, 2, reason: 'n children need n-1 gaps');
  });

  testWidgets('an empty group renders nothing rather than throwing',
      (tester) async {
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    expect(_radiiOf(tester), isEmpty);
  });
}
```

- [ ] **Step 3: Run both tests to verify they fail**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/morphing_surface_test.dart test/connected_group_test.dart`
Expected: FAIL — neither widget file exists.

- [ ] **Step 4: Replace the radius constants**

In `lib/theme/lockout_theme.dart`, replace lines 16-22:

```dart
  // Shape scale.
  static const double radiusButton = 14;
  static const double radiusCard = 18;
  static const double radiusDialog = 24;
  static const double radiusSheet = 28;
  static const double radiusField = 14;
  static const double radiusPill = 999;
```

with:

```dart
  // Shape scale. SHAPE IS A STATE, NOT A CONSTANT: every interactive
  // surface carries a rest radius and an active (pressed or selected)
  // radius and animates between them. The pairs come from
  // `docs/design/nuvetrix-app-design-system.md` section 5.2.
  static const double radiusButtonRest = 999;
  static const double radiusButtonActive = 12;
  static const double radiusButtonLargeActive = 16;

  static const double radiusRowRest = 8;
  static const double radiusRowActive = 20;

  static const double radiusChipRest = 12;
  static const double radiusChipActive = 999;

  static const double radiusSegmentInner = 8;
  static const double radiusSegmentEnd = 22;

  static const double radiusSwatchRest = 18;
  static const double radiusSwatchActive = 26;

  /// The outer corners of a connected group's first and last child.
  static const double radiusGroupEnd = 26;

  /// How far apart rows sit inside a connected group.
  static const double groupGap = 3;

  /// How far a pressed surface shrinks.
  static const double pressScale = 0.97;

  // Non-interactive surfaces keep a single radius: shape-as-state applies to
  // interaction, and a dialog does not have a pressed state.
  static const double radiusCard = 28;
  static const double radiusDialog = 32;
  static const double radiusSheet = 32;
  static const double radiusField = 16;
  static const double radiusPill = 999;

  /// The family's signature card outline — 36dp on three corners, 12dp on
  /// the bottom-left.
  ///
  /// Static rather than a rest/active pair: the house document makes this
  /// outline the identity of a hero card, and a card has no pressed state.
  static const RoundedRectangleBorder heroCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(36),
      topRight: Radius.circular(36),
      bottomRight: Radius.circular(36),
      bottomLeft: Radius.circular(12),
    ),
  );
```

Change `sectionGap` on line 33 from `24` to `28`, and add the house's bottom padding below it:

```dart
  static const double sectionGap = 28;

  /// Bottom padding for a scrollable screen that carries both a nav bar and
  /// a FAB, so the last row is never hidden behind either.
  static const double scrollBottomPadding = 128;

  /// The gap between a section heading and its content.
  static const double headingGap = 12;
```

Run: `C:\src\flutter\bin\flutter.bat analyze` and replace every `radiusButton` reference with `radiusButtonRest` (or `radiusButtonActive` where the call site is already describing a pressed state). Re-run until clean.

- [ ] **Step 5: Write `lib/widgets/morphing_surface.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/lockout_motion.dart';

/// A surface whose corner radius is a function of its interaction state.
///
/// The one place the shape-as-state rule is implemented, so a screen never
/// writes its own `AnimatedContainer` with a hand-picked duration. Pass the
/// rest and active radii from `LockoutTheme`'s pairs; pass `activeScale` on
/// anything the house document says shrinks while pressed.
///
/// `MediaQuery.disableAnimationsOf` is honoured through
/// `LockoutMotionTier.durationFor`, so a user who asked the OS to remove
/// animations gets an instant state change rather than a spring.
class MorphingSurface extends StatelessWidget {
  final double restRadius;
  final double activeRadius;
  final bool active;

  /// 1.0 for anything that does not shrink. The house press morph is 0.97.
  final double activeScale;

  /// Painted behind [child]. Null leaves the surface transparent, for a
  /// caller that paints its own background inside.
  final Color? color;

  final Widget child;

  const MorphingSurface({
    super.key,
    required this.restRadius,
    required this.activeRadius,
    required this.active,
    this.activeScale = 1.0,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tier = LockoutMotion.springFast;
    final duration = tier.durationFor(context);

    return AnimatedScale(
      scale: active ? activeScale : 1.0,
      duration: duration,
      curve: tier.curve,
      child: AnimatedContainer(
        duration: duration,
        curve: tier.curve,
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              BorderRadius.circular(active ? activeRadius : restRadius),
        ),
        clipBehavior: color == null ? Clip.none : Clip.antiAlias,
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 6: Write `lib/widgets/connected_group.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/lockout_theme.dart';

/// A column of rows that reads as one object rather than a stack of cards.
///
/// The first and last child carry large outer corners; everything between
/// them stays small on every corner, and the rows sit 3dp apart. The house
/// document's section 5.2 calls this a grouped list, and it replaces the
/// previous pattern of separate floating cards with drop shadows.
///
/// A single child is large on all four corners — it is simultaneously the
/// first and the last.
class ConnectedGroup extends StatelessWidget {
  final List<Widget> children;

  const ConnectedGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    const end = Radius.circular(LockoutTheme.radiusGroupEnd);
    const inner = Radius.circular(LockoutTheme.radiusRowRest);

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final first = i == 0;
      final last = i == children.length - 1;

      rows.add(
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: first ? end : inner,
            topRight: first ? end : inner,
            bottomLeft: last ? end : inner,
            bottomRight: last ? end : inner,
          ),
          child: children[i],
        ),
      );

      if (!last) {
        rows.add(const SizedBox(height: LockoutTheme.groupGap));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
```

- [ ] **Step 7: Run both tests to verify they pass**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/morphing_surface_test.dart test/connected_group_test.dart test/lockout_theme_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/theme/lockout_theme.dart lib/widgets/morphing_surface.dart lib/widgets/connected_group.dart test/morphing_surface_test.dart test/connected_group_test.dart
git commit -m "feat(ui): adopt the house corner scale and add the shape-as-state primitives"
```

---

### Task 8: Rebuild the settings theme picker

**Files:**
- Modify: `lib/screens/settings_screen.dart` — `_buildAppearanceCard` (around line 562), the `_ThemeSwatch` widget, `_applyTheme` (line 330), and the backup-restore read (around line 450)
- Test: `test/theme_picker_test.dart` (rewrite), `test/settings_restyle_test.dart` (update)

**Interfaces:**
- Consumes: `LockoutAccent`, `LockoutBrightnessChoice`, `ThemeController.selectBrightness` / `.selectAccent` (Tasks 5-6); `CookieBorder` (Task 4); `MorphingSurface` (Task 7).
- Produces: no new public API. The picker is two controls — a three-way brightness segmented button and a row of five accent swatches.

- [ ] **Step 1: Write the failing picker test**

Replace `test/theme_picker_test.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/settings_screen.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/theme_controller.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await resetTestDatabase();
    ThemeController.instance.resetForTest();
    await ThemeController.instance.load();
  });

  testWidgets('the picker offers all three brightness choices',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('the picker offers all five accents', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    for (final accent in LockoutAccent.all) {
      expect(find.bySemanticsLabel(accent.name), findsOneWidget,
          reason: '${accent.key} swatch is missing');
    }
  });

  testWidgets('gold is not offered — it belongs to another app',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Gold'), findsNothing);
  });

  testWidgets('choosing an accent persists it without touching brightness',
      (tester) async {
    await ThemeController.instance
        .selectBrightness(LockoutBrightnessChoice.dark);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(LockoutAccent.teal.name));
    await tester.pumpAndSettle();

    expect(ThemeController.instance.accent, LockoutAccent.teal);
    expect(ThemeController.instance.brightnessChoice,
        LockoutBrightnessChoice.dark);
  });

  testWidgets('choosing a brightness persists it without touching the accent',
      (tester) async {
    await ThemeController.instance.selectAccent(LockoutAccent.coral);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(ThemeController.instance.brightnessChoice,
        LockoutBrightnessChoice.dark);
    expect(ThemeController.instance.accent, LockoutAccent.coral);
  });

  testWidgets('the selected swatch announces itself as selected',
      (tester) async {
    await ThemeController.instance.selectAccent(LockoutAccent.violet);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel(LockoutAccent.violet.name)),
      matchesSemantics(
        label: LockoutAccent.violet.name,
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('every swatch clears the 48dp touch target', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    for (final accent in LockoutAccent.all) {
      final size = tester.getSize(find.bySemanticsLabel(accent.name));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('there is no wallpaper-colours control', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('wallpaper'), findsNothing);
    expect(find.textContaining('Dynamic'), findsNothing);
  });
}
```

Match `resetTestDatabase()` to whatever helper `test/test_helpers.dart` already exposes; do not add a second one.

- [ ] **Step 2: Run the test to verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/theme_picker_test.dart`
Expected: FAIL — the old picker renders scheme names, not brightness labels and accent swatches.

- [ ] **Step 3: Rebuild the appearance card**

In `lib/screens/settings_screen.dart`, replace the body of `_buildAppearanceCard` with:

```dart
  Widget _buildAppearanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ThemeController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Applies instantly.', style: theme.textTheme.bodySmall),
        const SizedBox(height: LockoutTheme.headingGap),

        SegmentedButton<LockoutBrightnessChoice>(
          segments: const [
            ButtonSegment(
              value: LockoutBrightnessChoice.system,
              label: Text('System'),
            ),
            ButtonSegment(
              value: LockoutBrightnessChoice.light,
              label: Text('Light'),
            ),
            ButtonSegment(
              value: LockoutBrightnessChoice.dark,
              label: Text('Dark'),
            ),
          ],
          selected: {controller.brightnessChoice},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              _applyBrightness(selection.first),
        ),

        const SizedBox(height: LockoutTheme.sectionGap),
        Text('Accent', style: theme.textTheme.titleLarge),
        const SizedBox(height: LockoutTheme.headingGap),

        Row(
          children: [
            for (final accent in LockoutAccent.all) ...[
              _AccentSwatch(
                accent: accent,
                selected: controller.accent == accent,
                onTap: () => _applyAccent(accent),
              ),
              if (accent != LockoutAccent.all.last)
                const SizedBox(width: LockoutTheme.spaceSm),
            ],
          ],
        ),
      ],
    );
  }
```

Replace `_applyTheme` (line 330) with the two handlers the card calls:

```dart
  Future<void> _applyBrightness(LockoutBrightnessChoice choice) async {
    try {
      await ThemeController.instance.selectBrightness(choice);
    } catch (_) {
      _toast('Could not apply the theme.', warn: true);
    }
    if (mounted) setState(() {});
  }

  Future<void> _applyAccent(LockoutAccent accent) async {
    try {
      await ThemeController.instance.selectAccent(accent);
    } catch (_) {
      _toast('Could not apply the accent.', warn: true);
    }
    if (mounted) setState(() {});
  }
```

- [ ] **Step 4: Replace `_ThemeSwatch` with `_AccentSwatch`**

Delete the `_ThemeSwatch` widget entirely and add:

```dart
/// One accent choice.
///
/// The swatch is the one place in the app where the shape language is itself
/// the content, so it wears a lobed outline rather than a rounded rectangle,
/// and the outline is what changes when it is chosen.
class _AccentSwatch extends StatelessWidget {
  final LockoutAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tier = LockoutMotion.springFast;

    return Semantics(
      label: accent.name,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: LockoutTheme.minTouchTarget,
          height: LockoutTheme.minTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: tier.durationFor(context),
              curve: tier.curve,
              width: selected ? 40 : 32,
              height: selected ? 40 : 32,
              decoration: ShapeDecoration(
                color: accent.accent,
                shape: CookieBorder(
                  lobes: CookieBorder.training.lobes,
                  amplitude: selected
                      ? CookieBorder.training.amplitude
                      : CookieBorder.training.amplitude / 2,
                  side: BorderSide(
                    color: selected ? colors.onSurface : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 18, color: accent.ink)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
```

Add the imports this needs at the top of the file: `../theme/accents.dart`, `../theme/cookie_border.dart`, `../theme/lockout_motion.dart`. Remove the `../theme/schemes.dart` import.

- [ ] **Step 5: Fix the backup-restore read**

At line ~450 the restore path reads the old setting and feeds it to the removed `select`. Replace:

```dart
    final restoredTheme =
        await db.getSetting('theme_key', defaultValue: LockoutScheme.fallback.key);
    await ThemeController.instance.select(restoredTheme);
```

with:

```dart
    // `load()` re-reads the setting and runs the same migration a fresh
    // launch would, so a backup written before the two-axis change restores
    // onto the right brightness and accent rather than the default.
    await ThemeController.instance.load();
```

- [ ] **Step 6: Run the picker tests**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/theme_picker_test.dart test/settings_restyle_test.dart`
Expected: PASS. If `matchesSemantics` fails on a flag the real widget does not set, adjust the matcher to the flags `InkWell` actually produces rather than wrapping the widget in extra semantics.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/settings_screen.dart test/theme_picker_test.dart test/settings_restyle_test.dart
git commit -m "feat(ui): rebuild the theme picker on brightness and accent axes"
```

---

### Task 9: Today tab — the proof surface

**Files:**
- Modify: `lib/screens/today_tab.dart` — `_buildSessionHeader` (line 708), the hero eyebrow (line 538), the action-grid icon containers (lines 757, 1101)
- Modify: `lib/widgets/lockout_card.dart` — add the optional `shape` override
- Modify: `lib/widgets/hero_card.dart` — adopt `LockoutTheme.heroCardShape`, sentence-case the eyebrow
- Test: `test/today_tab_test.dart` (extend), `test/widgets_v2_test.dart` (update)

**Interfaces:**
- Consumes: `LockoutTheme.heroCardShape`, `LockoutTheme.countdown`, `CookieBorder`, `MorphingSurface`, `LockoutMotion`.
- Produces: no new public API.

- [ ] **Step 1: Write the failing test**

Add to `test/today_tab_test.dart`:

```dart
  testWidgets('the hero card wears the signature asymmetric outline',
      (tester) async {
    await pumpTodayTab(tester);
    await tester.pumpAndSettle();

    final card = tester.widget<Card>(
      find.descendant(
        of: find.byType(HeroCard),
        matching: find.byType(Card),
      ).first,
    );
    final radius =
        (card.shape! as RoundedRectangleBorder).borderRadius as BorderRadius;

    expect(radius.topLeft.x, 36);
    expect(radius.topRight.x, 36);
    expect(radius.bottomRight.x, 36);
    expect(radius.bottomLeft.x, 12,
        reason: 'the bottom-left corner is the family signature');
  });

  testWidgets('the hero card does not morph on press', (tester) async {
    await pumpTodayTab(tester);
    await tester.pumpAndSettle();

    Object? shapeNow() => tester.widget<Card>(
          find.descendant(
            of: find.byType(HeroCard),
            matching: find.byType(Card),
          ).first,
        ).shape;

    final before = shapeNow();
    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HeroCard)));
    await tester.pump(const Duration(milliseconds: 120));
    expect(shapeNow(), before, reason: 'a card has no pressed state');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the eyebrow is sentence case', (tester) async {
    await pumpTodayTab(tester);
    await tester.pumpAndSettle();

    final hero = tester.widget<HeroCard>(find.byType(HeroCard));
    expect(hero.eyebrow, isNot(hero.eyebrow.toUpperCase()),
        reason: 'the house document forbids all-caps labels (section 4.2)');
  });

  testWidgets('the session header leads with one big countdown number',
      (tester) async {
    await pumpTodayTabWithLiveSession(tester);
    await tester.pumpAndSettle();

    final big = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.fontSize == 88)
        .toList();
    expect(big.length, 1,
        reason: 'at most one big number per screen, and exactly one here');
    expect(big.single.style!.fontFamily, LockoutTheme.fontDisplay);
    expect(big.single.style!.fontWeight, FontWeight.w800);
    expect(find.textContaining('sets left'), findsOneWidget);
  });

  testWidgets('the session marker is a lobed shape whose lobes read as '
      'register', (tester) async {
    await pumpTodayTabWithLiveSession(tester);
    await tester.pumpAndSettle();

    final lobed = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => d.shape)
        .whereType<CookieBorder>()
        .toList();

    expect(lobed, isNotEmpty,
        reason: 'the session marker must carry a CookieBorder');
    expect(lobed.map((b) => b.lobes), everyElement(anyOf(4, 6)),
        reason: '4 lobes is rest, 6 is training; the marker is one of them');
  });

  testWidgets('the action-grid icon containers do not rotate lobe count',
      (tester) async {
    await pumpTodayTab(tester);
    await tester.pumpAndSettle();

    final gridShapes = tester
        .widgetList<Container>(find.descendant(
          of: find.byType(ActionGrid),
          matching: find.byType(Container),
        ))
        .map((c) => c.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => d.shape)
        .whereType<CookieBorder>();

    expect(gridShapes, isEmpty,
        reason: 'repeated small icon containers take one consistent '
            'squircle; colour already carries category');
  });
```

Add the imports the new cases need: `package:lockout/theme/cookie_border.dart`, `package:lockout/theme/lockout_theme.dart`, `package:lockout/widgets/hero_card.dart`, `package:lockout/widgets/action_grid.dart`.

Reuse whatever pump helpers `today_tab_test.dart` already defines rather than adding `pumpTodayTab` and `pumpTodayTabWithLiveSession` under those names — the session header only renders while a session is running, so the two countdown cases need the suite's existing live-session setup, not the plain pump.

- [ ] **Step 2: Run the test to verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/today_tab_test.dart`
Expected: FAIL — the hero card is a uniform 18dp rounded rectangle and there is no 88px numeral.

- [ ] **Step 3: Let `LockoutCard` take a shape, and give `HeroCard` the signature outline**

`HeroCard` paints through `LockoutCard`, which wraps a `Card` and takes its shape from `cardTheme`. Give it an override.

In `lib/widgets/lockout_card.dart`, add a field to the constructor:

```dart
  /// Overrides the theme's card shape. Only the hero card passes one — it
  /// wears the family's signature asymmetric outline, and every other card
  /// takes the uniform shape from `cardTheme`.
  final ShapeBorder? shape;
```

Add `this.shape,` to the constructor parameter list, pass it through to the `Card`:

```dart
    return Card(
      color: color,
      elevation: elevated ? 3 : null,
      shape: shape,
```

and make the `InkWell`'s ripple follow it, since a pill-radius ripple on an asymmetric card bleeds past the corner:

```dart
          : InkWell(
              onTap: onTap,
              customBorder: shape ??
                  RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(LockoutTheme.radiusCard),
                  ),
```

In `lib/widgets/hero_card.dart`, pass the shape through:

```dart
      child: LockoutCard(
        elevated: true,
        shape: LockoutTheme.heroCardShape,
```

- [ ] **Step 4: Put the big number in the session header and make the eyebrow sentence case**

The live-session header at `lib/screens/today_tab.dart:708` (`_buildSessionHeader`) is the Today tab's hero surface. It already computes `_sessionCompletedSets` and `_sessionTotalSets`; the house recipe's "one big number" is the sets still to go, which needs no new state.

Replace the `Text(_sessionTitle, ...)` block and the three-stat row's leading edge with:

```dart
          Text(
            _sessionTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LockoutTheme.spaceXs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The lobed marker reads as register: 6 lobes while a session
              // is running, 4 when the day is rest. It is a subject-scale
              // element, which is the only place a lobed shape is allowed.
              Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: _sessionTotalSets > 0
                      ? CookieBorder.training
                      : CookieBorder.rest,
                ),
                child: Icon(
                  _sessionTotalSets > 0
                      ? Icons.bolt_outlined
                      : Icons.bedtime_outlined,
                  size: 22,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: LockoutTheme.spaceMd),
              Text(
                '${_sessionTotalSets - _sessionCompletedSets}',
                style: LockoutTheme.countdown(theme.colorScheme),
              ),
              const SizedBox(width: LockoutTheme.spaceSm),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  _sessionTotalSets - _sessionCompletedSets == 1
                      ? 'set left'
                      : 'sets left',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: LockoutTheme.spaceMd),
```

The existing Duration / Volume / Sets row stays exactly as it is, below this. Drop the `Sets` stat from it — the big number now carries that figure, and the house document allows one big number per screen, not the same number twice.

Then fix the two all-caps strings this branch owns. At `lib/screens/today_tab.dart:538`, change:

```dart
        eyebrow: 'TODAY · $code',
```

to:

```dart
        eyebrow: 'Today · $code',
```

And in `lib/widgets/hero_card.dart`, the eyebrow's doc comment claims all-caps survives there. It does not any more — the house document forbids it outright. Replace the comment and drop the tracking override, because the house `labelSmall` has zero tracking:

```dart
  /// Small label above the title — context, not content. Sentence case, like
  /// everything else: the house document forbids all-caps labels (section
  /// 4.2), so what used to be an all-caps eyebrow is now distinguished by
  /// size and colour alone.
  final String eyebrow;
```

```dart
                    Text(
                      eyebrow,
                      style: text.labelSmall?.copyWith(color: accent),
                    ),
```

- [ ] **Step 5: Square the action-grid icon containers**

At `lib/screens/today_tab.dart:757` and `:1101` the icon containers use `BorderRadius.circular(LockoutTheme.radiusPill)`. Replace both with the one consistent squircle:

```dart
                borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
```

They must not take a `CookieBorder`: colour already carries category, and two signals on one axis read as noise.

- [ ] **Step 6: Run the tests**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/today_tab_test.dart test/widgets_v2_test.dart test/home_tab_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/today_tab.dart lib/widgets/hero_card.dart lib/widgets/lockout_card.dart test/today_tab_test.dart test/widgets_v2_test.dart
git commit -m "feat(ui): prove the expressive system on the Today tab"
```

---

### Task 10: Close the branch — the contract guard, the sweep, the suite, the docs

**Files:**
- Create: `test/expressive_contract_test.dart`
- Modify: `README.md` — the theming paragraph
- Modify: `.spine/config.md` — the test baseline

**Interfaces:**
- Consumes: everything above.
- Produces: no new public API.

- [ ] **Step 1: Write the contract guard**

The guard reads the vendored house document and asserts the app against it, so there is one copy of each value rather than two that can drift apart.

Create `test/expressive_contract_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/lockout_motion.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/theme/palette.dart';

/// The vendored house document. Every value asserted below is read from it
/// rather than restated here: a second copy of the palette in a test file is
/// a second thing to keep in step.
final String _house =
    File('docs/design/nuvetrix-app-design-system.md').readAsStringSync();

/// The files branch 1 restyles.
///
/// Several guards below are scoped to this list rather than to all of `lib`,
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
  'lib/screens/settings_screen.dart',
  'lib/screens/today_tab.dart',
];

/// True when the document mentions this hex anywhere, in either case.
bool _houseDeclares(Color colour) {
  final hex = colour.toARGB32().toRadixString(16).padLeft(8, '0')
      .substring(2).toUpperCase();
  return _house.toUpperCase().contains('#$hex');
}

void main() {
  group('the house document is present and is the one we tested against', () {
    test('the vendored copy exists and is version 1.1 or later', () {
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
        final scheme =
            LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        for (final entry in {
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
        }.entries) {
          expect(_houseDeclares(entry.value), isTrue,
              reason: '$brightness $entry.key is not a house colour');
        }
      }
    });

    test('every accent and its ink appear in the house document', () {
      for (final accent in LockoutAccent.all) {
        if (accent == LockoutAccent.steel) continue; // D6: Lockout's own.
        expect(_houseDeclares(accent.accent), isTrue,
            reason: '${accent.key} is not a house accent');
        expect(_houseDeclares(accent.ink), isTrue,
            reason: "${accent.key}'s ink is not a house value");
      }
    });

    test('WishPlay gold appears nowhere in the app', () {
      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().toUpperCase().contains('FFB938'))
          .map((f) => f.path);
      expect(sources, isEmpty);
    });
  });

  group('type', () {
    test('the three bundled families are the only ones named', () {
      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.readAsStringSync())
          .join();
      for (final banned in const ['Inter', 'SpaceGrotesk', 'Roboto']) {
        expect(sources.contains("'$banned'"), isFalse,
            reason: '$banned is not a bundled family');
      }
    });

    test('the house declares every size the scale uses', () {
      final text = LockoutTheme.textThemeFor(const ColorScheme.light());
      for (final size in [
        text.displayLarge!.fontSize,
        text.displayMedium!.fontSize,
        text.headlineLarge!.fontSize,
        text.headlineMedium!.fontSize,
        text.titleLarge!.fontSize,
        text.titleMedium!.fontSize,
        text.bodyMedium!.fontSize,
        text.labelSmall!.fontSize,
      ]) {
        expect(_house.contains('| ${size!.toInt()} /'), isTrue,
            reason: '${size.toInt()}sp is not a house size');
      }
    });

    test('nothing this branch owns is uppercase', () {
      // Scoped to the files branch 1 restyles. The six remaining tabs still
      // carry all-caps copy and `toUpperCase()` on tag comparisons; the copy
      // sweep is branch 2, and widening this list is that branch's job.
      // Data normalisation — `schedulingMode.name.toUpperCase()`, tag
      // matching in `schedule_service.dart` — is not display copy and never
      // belongs in this list.
      for (final path in _branchOneFiles) {
        expect(File(path).readAsStringSync().contains('toUpperCase'), isFalse,
            reason: '$path still uppercases display copy; the house '
                'document forbids all-caps labels (section 4.2)');
      }
    });
  });

  group('shape', () {
    test('the hero card is 36 on three corners and 12 bottom-left', () {
      final radius =
          LockoutTheme.heroCardShape.borderRadius as BorderRadius;
      expect(radius.topLeft.x, 36);
      expect(radius.topRight.x, 36);
      expect(radius.bottomRight.x, 36);
      expect(radius.bottomLeft.x, 12);
    });

    test('every interactive radius is a pair, not a constant', () {
      expect(LockoutTheme.radiusButtonRest,
          isNot(LockoutTheme.radiusButtonActive));
      expect(LockoutTheme.radiusRowRest,
          isNot(LockoutTheme.radiusRowActive));
      expect(LockoutTheme.radiusChipRest,
          isNot(LockoutTheme.radiusChipActive));
      expect(LockoutTheme.radiusSwatchRest,
          isNot(LockoutTheme.radiusSwatchActive));
    });

    test('the house declares each corner value the app uses', () {
      for (final value in const [8, 12, 16, 22, 26, 28, 32, 36]) {
        expect(_house.contains('$value dp'), isTrue,
            reason: '${value}dp is not a house corner value');
      }
    });
  });

  group('motion', () {
    test('there are exactly three tiers', () {
      expect(LockoutMotion.springFast.duration.inMilliseconds, 250);
      expect(LockoutMotion.springDefault.duration.inMilliseconds, 450);
      expect(LockoutMotion.effects.duration.inMilliseconds, 200);
    });

    test('no animated surface this branch owns hand-rolls a duration', () {
      // Matched on the animated widgets rather than on the literal, because
      // a debounce or a timer is a duration that is not motion and must not
      // be dragged into the motion system.
      const animated = [
        'AnimatedContainer(',
        'AnimatedScale(',
        'AnimatedOpacity(',
        'AnimatedAlign(',
        'AnimatedPadding(',
        'AnimationController(',
      ];
      for (final path in _branchOneFiles) {
        if (path.endsWith('lockout_motion.dart')) continue;
        final source = File(path).readAsStringSync();
        for (final widget in animated) {
          if (!source.contains(widget)) continue;
          expect(source.contains('LockoutMotion.'), isTrue,
              reason: '$path animates with $widget but never reads a tier');
        }
      }
    });

    test('framework easing tokens are gone from the theme layer', () {
      for (final file in Directory('lib/theme')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        expect(source.contains('Easing.'), isFalse, reason: file.path);
        expect(source.contains('Durations.'), isFalse, reason: file.path);
      }
    });
  });

  group('dependencies', () {
    test('no new package arrived and dynamic_color left', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('dynamic_color'), isFalse);
      expect(pubspec.contains('google_fonts'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run it and fix what it finds**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/expressive_contract_test.dart`
Expected: FAIL on the first pass, naming each branch-1 file that still animates without reading a tier, each uppercase string this branch owns, and any palette colour not declared upstream. Fix each by reading a `LockoutMotion` tier, rewriting the string in sentence case, or correcting the hex to the house value.

Fix the code, never the guard. The one legitimate reason to touch a case here is a file genuinely outside branch 1's scope appearing in `_branchOneFiles` — remove it from the list and say so in the commit message. Widening a guard to pass is how a contract stops being one.

- [ ] **Step 3: Run the full suite**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1`
Expected: PASS, at or above 586. Record the new count.

- [ ] **Step 4: Analyse**

Run: `C:\src\flutter\bin\flutter.bat analyze`
Expected: "No issues found!"

- [ ] **Step 5: Update the README theming paragraph**

Replace the paragraph describing the six schemes with:

```markdown
### Theming

Lockout follows the Nuvetrix App Design System, vendored at
`docs/design/nuvetrix-app-design-system.md`. Appearance has two independent
axes: brightness (System, Light or Dark) and accent (Rep lime, Violet, Teal,
Coral or Steel). Both live in the `theme_key` setting and migrate
automatically from the six themes earlier versions shipped.

Typefaces are bundled rather than downloaded, so the app renders correctly
with no network: Bricolage Grotesque for display, Figtree for body text, and
JetBrains Mono for figures that must line up in a column. There is no
wallpaper-derived (Material You) colour — the house system reserves colour
identity for the app.

`test/expressive_contract_test.dart` asserts the app against the vendored
house document, so drift from the family standard fails a test rather than a
review.
```

- [ ] **Step 6: Update the contract's test baseline**

In `.spine/config.md`, update the Test runner line's baseline from `586 passed` to the count Step 3 reported, and name the commit it was measured at.

Then re-run the config assertion, because the contract changed:

```bash
C:\src\flutter\bin\flutter.bat test --concurrency=1 test/backup_roundtrip_test.dart
sh "$CLAUDE_PLUGIN_ROOT/hooks/config-hash.sh" .spine/config.md > .spine/config-asserted
```

If `$CLAUDE_PLUGIN_ROOT` is empty, resolve it per `using-spine`'s bounded fallback.

- [ ] **Step 7: Commit**

```bash
git add test/expressive_contract_test.dart README.md .spine/config.md .spine/config-asserted
git commit -m "test(ui,docs): guard the house contract and record the new baseline"
```

---

## Branch exit criteria

- Full serial suite green; the new count recorded in `.spine/config.md`.
- `flutter analyze` clean.
- `expressive_contract_test.dart` passing, so the house system's rules are enforced in tooling rather than by willpower.
- A real device or emulator pass of the Today tab and the settings picker across all five accents in both brightnesses, plus one pass with the OS "remove animations" setting on.
- Whole-branch review (Gate D) before any merge.
