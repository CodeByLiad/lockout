# Expressive Foundation (Branch 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-dev (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Lockout read as Material 3 Expressive: a scheme generated from the accent on a user-chosen style, a distinct Material shape per icon container, and the Expressive navigation bar — plus the branch-1 loose ends.

**Architecture:** The colour engine moves from authored house neutrals to `ColorScheme.fromSeed` behind the unchanged `LockoutPalette` seam, with a third persisted axis (`LockoutSchemeStyle`) folded into the existing `theme_key` setting. Every shape from `material_new_shapes` passes through one adapter file, `lib/theme/lockout_shapes.dart`, which exposes a closed `LockoutShape` enum and a `LockoutShapeBorder`. `NvNavigationBar` is a new catalog component consumed in the same task by `BottomNav`.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, sqflite, `material_new_shapes` 1.0.0 (new, D14).

Spec: `docs/spine/specs/2026-10-28-expressive-foundation-design.md`. Config: `.spine/config.md`.

## Global Constraints

- Flutter is NOT on PATH. Run `C:\src\flutter\bin\flutter.bat` by absolute path.
- Full suite is serial: `C:\src\flutter\bin\flutter.bat test --concurrency=1`. Floor: 890 passed at `7fcce7f`. Re-measure; never drop below without a named deletion.
- Analyzer: `C:\src\flutter\bin\flutter.bat analyze` — baseline 3 issues; a task must not add one.
- ONE new dependency only: `material_new_shapes: ^1.0.0`, imported ONLY by `lib/theme/lockout_shapes.dart`. No other package.
- No database schema change. `theme_key` stays one setting; its value becomes `brightness|accent|style`.
- Never clear `theme_key`. Every historical value migrates in `ThemeController._resolve`.
- Fresh install: `system|lime|tonal`.
- `dynamic_color` stays removed. The seed is always the user's accent.
- `surfaceTint` stays `Colors.transparent`.
- Colour, type and shape resolve through `Theme.of(context)` / `ColorScheme` / `LockoutSemantics.of(context)`. No compile-time colour constant in a screen or catalog widget.
- Motion uses only `LockoutMotion.springFast` / `springDefault` / `effects`, read through `durationFor(context)`; reduced motion is instant.
- Sentence case everywhere. No all-caps strings in UI.
- A rebuilt screen (`today_tab.dart`, `about_screen.dart`, `settings_screen.dart`, `profile_tab.dart`) composes from `lib/widgets/house/` and the theme only.
- Cards, list rows and grouped-list rows stay rounded rectangles. Real content is never clipped into an irregular shape.
- Lobed (cookie) shapes appear only on subject-scale elements, with register 4 rest, 6 training, 9 streak, 12 achievement (D5).
- Commits end with the session attribution lines from the controller.

## Plan-level decisions (approved with this plan)

- **`semanticsFor` takes the generated scheme, not the style.** Spec §5.1 says it "takes the style and the generated scheme". The style is fully carried by the scheme, and an unused parameter would be lint noise. Signature: `semanticsFor(Brightness, LockoutAccent, ColorScheme)`.
- **Controller method is `selectStyle`, not `setStyle`.** The spec names `setStyle` by analogy with "`setAccent`", but the real methods are `selectBrightness` / `selectAccent`. Match the code.
- **`NvIconTile` drops its `color` parameter.** Its one caller passes a single neutral. The tile now fills itself with `secondaryContainer` / `onSecondaryContainer` (spec §5.5), and takes a required `LockoutShape`.
- **Settings captions drop to `titleSmall`.** Section headings stay `titleMedium`. The in-section captions "Accent", "Style" and "Activity level" move from `titleLarge` to `titleSmall`, so no caption outranks the heading of its own section. This is the "one heading style" fix.
- **Quick-action shapes exclude the cookies and the circle.** Cookies are reserved for D5 registers; the circle is the pressed target.

---

## File structure and seams

| File | Responsibility | Seam (the interface later tasks depend on) |
| --- | --- | --- |
| `lib/theme/scheme_style.dart` (new) | The style axis enum | `enum LockoutSchemeStyle { tonal, vibrant, expressive }` with `String key`, `String label`, `DynamicSchemeVariant variant`, `static LockoutSchemeStyle byKey(String)`, `static const fallback = tonal` |
| `lib/theme/palette.dart` | Scheme + semantics generation | `static ColorScheme schemeFor(Brightness, LockoutAccent, LockoutSchemeStyle)`; `static LockoutSemantics semanticsFor(Brightness, LockoutAccent, ColorScheme)` |
| `lib/theme/lockout_semantics.dart` | Custom roles | adds `final Color heroFill; final Color onHeroFill;` |
| `lib/theme/theme_controller.dart` | Axis state + persistence + migration | adds `LockoutSchemeStyle get style`, `Future<void> selectStyle(LockoutSchemeStyle)` |
| `lib/theme/lockout_shapes.dart` (new) | The ONLY importer of `material_new_shapes` | `enum LockoutShape {...}`; `class LockoutShapeBorder extends OutlinedBorder` with `const LockoutShapeBorder(LockoutShape shape, {LockoutShape? morphTo, double progress = 0, BorderSide side = BorderSide.none})` |
| `lib/widgets/house/nv_icon_tile.dart` | Icon tile with shape + press morph | `NvIconTile({required IconData icon, required LockoutShape shape, required String label, required VoidCallback onTap})` |
| `lib/widgets/house/nv_navigation_bar.dart` (new) | Expressive short nav bar | `NvNavigationBar({Key? key, required int selectedIndex, required ValueChanged<int> onDestinationSelected, required List<NvNavigationDestination> destinations})`; `NvNavigationDestination({required IconData icon, required IconData selectedIcon, required String label})` |
| `lib/widgets/bottom_nav.dart` | Consumer; public API unchanged | `BottomNav`, `NavTab`, `NavTabDef`, `visibleTabs`, `lastRenderedHeight` unchanged |
| `lib/theme/cookie_border.dart` | DELETED in Task 7 | — |

---

### Task 1: Branch-1 visible loose ends

Sentence case, Settings caption hierarchy, disabled `NvIconButton`.

**Files:**
- Modify: `lib/screens/today_tab.dart:335` (`'Custom Session'`), `:697` (`'Today · $code'`)
- Modify: `lib/services/nutrition_planner.dart:9-13` (`ActivityLevel` labels)
- Modify: `lib/screens/settings_screen.dart:918` (`'Accent'` caption), `:1015` (`'Activity level'` caption)
- Modify: `lib/widgets/house/nv_button.dart:215-265` (`_NvIconButtonState.build`)
- Test: `test/today_tab_test.dart`, `test/settings_restyle_test.dart`, `test/nv_button_test.dart` (create the group in whichever file already tests `NvIconButton`; `grep -ln NvIconButton test/` to find it)

**Interfaces:**
- Consumes: nothing new.
- Produces: `ActivityLevel.label` values `Sedentary`, `Lightly active`, `Moderately active`, `Very active`, `Athlete`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/today_tab_test.dart — inside the existing pre-session group
testWidgets('the day line is sentence case, not an all-caps code',
    (tester) async {
  await pumpToday(tester); // use this file's existing pump helper
  final line = find.textContaining('Today · ');
  expect(line, findsOneWidget);
  final text = tester.widget<Text>(line).data!;
  final day = text.split(' · ').last;
  expect(day, matches(RegExp(r'^[A-Z][a-z]{2}$')),
      reason: 'expected e.g. "Wed", got "$day"');
});
```

```dart
// test/nutrition_planner_test.dart (create if absent)
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/services/nutrition_planner.dart';

void main() {
  test('activity level names are sentence case', () {
    for (final a in ActivityLevel.values) {
      final rest = a.label.substring(1);
      expect(rest, rest.toLowerCase(), reason: a.label);
    }
  });
}
```

```dart
// test/settings_restyle_test.dart
testWidgets('no caption inside a section outranks the section heading',
    (tester) async {
  await pumpSettings(tester); // this file's existing helper
  final theme = Theme.of(tester.element(find.text('Training')));
  final heading = tester.widget<Text>(find.text('Training')).style!;
  for (final caption in ['Accent', 'Activity level']) {
    final style = tester.widget<Text>(find.text(caption)).style!;
    expect(style.fontSize! <= heading.fontSize!, isTrue,
        reason: '"$caption" is larger than its section heading');
    expect(style, theme.textTheme.titleSmall);
  }
  expect(heading, theme.textTheme.titleMedium);
});
```

```dart
// NvIconButton group
testWidgets('a disabled NvIconButton drops its filled surface',
    (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: lockoutTestTheme(lightAppearance),
    home: const Scaffold(
      body: Row(children: [
        NvIconButton(icon: Icons.add, tooltip: 'On', onPressed: _noop),
        NvIconButton(icon: Icons.add, tooltip: 'Off', onPressed: null),
      ]),
    ),
  ));
  Color fill(String tip) => tester
      .widget<MorphingSurface>(find.descendant(
          of: find.byTooltip(tip), matching: find.byType(MorphingSurface)))
      .color;
  final colors = lightAppearance.colors;
  expect(fill('On'), colors.surfaceContainerHigh);
  expect(fill('Off'), colors.onSurface.withValues(alpha: 0.12));
});
void _noop() {}
```

- [ ] **Step 2: Run them, expect FAIL**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/today_tab_test.dart test/nutrition_planner_test.dart test/settings_restyle_test.dart <NvIconButton test file>`
Expected: 4 failures (all-caps day, title-case labels, `titleLarge` captions, full disabled fill).

- [ ] **Step 3: Implement**

`today_tab.dart:662` area — keep `ScheduleService.weekdayCode` as the source, format for display only:

```dart
final code = ScheduleService.weekdayCode(DateTime.now());
// The code is a storage key ("WED"); the screen shows it in sentence case.
final dayLabel = '${code[0]}${code.substring(1).toLowerCase()}';
```
and `'Today · $dayLabel'` at `:697`. At `:335`: `await _beginSession('Custom session', []);`.

`nutrition_planner.dart` — labels become `'Lightly active'`, `'Moderately active'`, `'Very active'` (others already sentence case). Grep tests for the old strings and update them: `grep -rn "Lightly Active\|Moderately Active\|Very Active\|Custom Session" test lib`.

`settings_screen.dart:918` and `:1015` — `theme.textTheme.titleLarge` → `theme.textTheme.titleSmall`.

`nv_button.dart` `_NvIconButtonState.build` — after the `switch`, before `return`:

```dart
// A disabled control must not keep the surface that says "press me".
// The M3 disabled container: onSurface at 12%, glyph at 38%.
final fill = _enabled ? background : colors.onSurface.withValues(alpha: 0.12);
final glyph =
    _enabled ? foreground : colors.onSurface.withValues(alpha: 0.38);
```
and pass `color: fill` to `MorphingSurface` and `color: glyph` to `Icon`.

- [ ] **Step 4: Run the four files, expect PASS; then the full suite**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1` — expect ≥ 894 passed, 0 failed.

- [ ] **Step 5: Commit**

```bash
git add -A lib test
git commit -m "fix(ui): sentence case, caption hierarchy and a disabled icon button that looks disabled"
```

---

### Task 2: Round-3 Minors 3–7, 9, 11

Source: `.spine/final-review-findings-6.md` "Minor backlog". Minors 1, 2, 8 are already closed (`7d6c29e`); Minor 10 is Task 1.

**Files:**
- Modify: `lib/screens/settings_screen.dart` (import tail ~`:620-701`, `_section` ~`:795-830`, `_CardMargin` dartdoc)
- Modify: the M7 keyboard-focus ticket — `grep -rn "M7" docs/spine` to locate it
- Test: `test/settings_restyle_test.dart`, the import-tail test file (`grep -ln "coercedValues" test/`)

**Interfaces:**
- Consumes / Produces: none outside `settings_screen.dart`.

- [ ] **Step 1: Write the failing tests**

```dart
// Minor 3 — import-tail test file
testWidgets('a theme reload failure does not blame the backup file',
    (tester) async {
  // Reuse the file's existing setup that makes ThemeController.load() throw
  // via ThemeController.readStoredChoice (restore it in addTearDown).
  // Arrange a backup with coercedValues == 0.
  ...
  expect(find.textContaining('Check the backup file'), findsNothing);
});

// Minor 4
testWidgets('a warning toast stays 8 seconds', (tester) async {
  // Drive the same failing tail, then:
  final bar = tester.widget<SnackBar>(find.byType(SnackBar));
  expect(bar.duration, const Duration(seconds: 8));
});

// Minor 11 — settings_restyle_test.dart
testWidgets('a section with no rows keeps the 12dp heading gap',
    (tester) async {
  await pumpSettings(tester);
  final heading = tester.getRect(find.text('Look and feel'));
  final first = tester.getRect(find.text('Applies instantly.'));
  expect(first.top - heading.bottom, closeTo(12, 0.5));
});

// Minor 6 — extend the existing margin test to every `_section` call site
// that passes a grouped list or filled card in `extras`, not just one.
```

The implementer writes the "…" arrange body from the existing tests in the same file; no new seam is needed — `readStoredChoice` already exists.

- [ ] **Step 2: Run, expect FAIL** (Minor 6's extension may already pass — if so it is a characterisation test; say so in the report).

- [ ] **Step 3: Implement**
  - Minor 3: append "Check the backup file." only when `result.coercedValues > 0`.
  - Minor 4: every `warn` toast passes `duration: const Duration(seconds: 8)`.
  - Minor 5: rewrite the comment at ~`:810-812` to say the save button stretches to the column width, 8dp narrower than before (W-40, was W-32).
  - Minor 6: `_CardMargin` dartdoc gains: "Only works as a direct element of `extras`. Wrapped in anything else it is not seen, and the card silently takes the 20dp text margin."
  - Minor 7: the ticket names all four affected widgets: `NvButton`, `NvIconButton`, `NvSegmentedButton`, `NvListItem`.
  - Minor 9: comment says "the re-read completed", not "what the user is looking at is the imported thing".
  - Minor 11: in `_section`, when `rows` is empty, the gap between heading and first extra is `LockoutTheme.headingGap` (12), not the 28dp section gap.

- [ ] **Step 4: Run the files, then the full suite. Expect PASS.**

- [ ] **Step 5: Commit** — `git commit -m "fix(settings): close round-3 review minors 3-7, 9, 11"`

---

### Task 3: Colour engine

**Files:**
- Create: `lib/theme/scheme_style.dart`
- Modify: `lib/theme/palette.dart` (whole `schemeFor`/`semanticsFor`; delete the authored neutral constants)
- Modify: `lib/theme/lockout_semantics.dart` (add `heroFill`, `onHeroFill`)
- Modify: `lib/widgets/house/nv_hero_card.dart:48` (fill from `heroFill`/`onHeroFill`)
- Modify: `lib/theme/theme_controller.dart:57-72` (pass `LockoutSchemeStyle.tonal` for now — Task 4 adds the field)
- Modify: `test/test_helpers.dart:156-209` (`TestAppearance` gains `style`)
- Modify: `test/expressive_contract_test.dart:196,325-327,393-395` (new signatures)
- Rewrite: `test/palette_test.dart`
- Create: `test/contrast_matrix_test.dart`

**Interfaces:**
- Produces:
  - `enum LockoutSchemeStyle { tonal, vibrant, expressive }` — `key` (`'tonal'|'vibrant'|'expressive'`), `label` (`'Tonal'|'Vibrant'|'Expressive'`), `variant` (`DynamicSchemeVariant.tonalSpot|vibrant|expressive`), `static LockoutSchemeStyle byKey(String)` (junk → `tonal`), `static const LockoutSchemeStyle fallback = tonal`.
  - `LockoutPalette.schemeFor(Brightness brightness, LockoutAccent accent, LockoutSchemeStyle style) → ColorScheme`
  - `LockoutPalette.semanticsFor(Brightness brightness, LockoutAccent accent, ColorScheme scheme) → LockoutSemantics`
  - `LockoutSemantics.heroFill` == `accent.accent`, `LockoutSemantics.onHeroFill` == `accent.ink`
  - `TestAppearance(Brightness brightness, LockoutAccent accent, [LockoutSchemeStyle style = LockoutSchemeStyle.tonal])`; `allAppearances` now spans 2 × 5 × 3 = 30; `key` is `'brightness|accent|style'`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/palette_test.dart — replaces the old constant-pinning groups.
// Keep the existing `LockoutSemantics.onCategoryColor` group and the
// "the ramp has eight entries" test verbatim.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/palette.dart';
import 'package:lockout/theme/scheme_style.dart';

void main() {
  group('the framework generator is what we think it is', () {
    test('fromSeed honours dynamicSchemeVariant on the pinned SDK', () {
      final tonal = ColorScheme.fromSeed(
          seedColor: LockoutAccent.lime.accent,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot);
      final vivid = ColorScheme.fromSeed(
          seedColor: LockoutAccent.lime.accent,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant);
      expect(tonal.primary, isNot(vivid.primary));
    });
  });

  group('schemeFor', () {
    for (final style in LockoutSchemeStyle.values) {
      for (final accent in LockoutAccent.all) {
        for (final b in Brightness.values) {
          test('${b.name}|${accent.key}|${style.key} is fromSeed itself', () {
            final expected = ColorScheme.fromSeed(
              seedColor: accent.accent,
              brightness: b,
              dynamicSchemeVariant: style.variant,
            );
            final actual = LockoutPalette.schemeFor(b, accent, style);
            expect(actual.brightness, b);
            expect(actual.primary, expected.primary);
            expect(actual.surface, expected.surface);
            expect(actual.surfaceContainer, expected.surfaceContainer);
            expect(actual.secondaryContainer, expected.secondaryContainer);
            expect(actual.surfaceTint, Colors.transparent);
          });
        }
      }
    }

    test('in light, the accent now changes primary (complaint 1)', () {
      final lime = LockoutPalette.schemeFor(
          Brightness.light, LockoutAccent.lime, LockoutSchemeStyle.tonal);
      final violet = LockoutPalette.schemeFor(
          Brightness.light, LockoutAccent.violet, LockoutSchemeStyle.tonal);
      expect(lime.primary, isNot(violet.primary));
      expect(lime.surface, isNot(violet.surface),
          reason: 'the accent must tint the surfaces too (complaint 2)');
    });

    test('style maps to the variant the spec names', () {
      expect(LockoutSchemeStyle.tonal.variant, DynamicSchemeVariant.tonalSpot);
      expect(LockoutSchemeStyle.vibrant.variant, DynamicSchemeVariant.vibrant);
      expect(LockoutSchemeStyle.expressive.variant,
          DynamicSchemeVariant.expressive);
    });

    test('byKey: known keys round-trip, junk falls back to tonal', () {
      for (final s in LockoutSchemeStyle.values) {
        expect(LockoutSchemeStyle.byKey(s.key), s);
      }
      expect(LockoutSchemeStyle.byKey('neon'), LockoutSchemeStyle.tonal);
      expect(LockoutSchemeStyle.byKey(''), LockoutSchemeStyle.tonal);
    });
  });

  group('semanticsFor', () {
    test('the hero keeps the exact identity accent in every style', () {
      for (final style in LockoutSchemeStyle.values) {
        for (final b in Brightness.values) {
          final scheme =
              LockoutPalette.schemeFor(b, LockoutAccent.lime, style);
          final s =
              LockoutPalette.semanticsFor(b, LockoutAccent.lime, scheme);
          expect(s.heroFill, LockoutAccent.lime.accent);
          expect(s.onHeroFill, LockoutAccent.lime.ink);
        }
      }
    });

    test('success and the ramp keep their branch-1 values', () {
      final light = LockoutPalette.semanticsFor(Brightness.light,
          LockoutAccent.lime,
          LockoutPalette.schemeFor(Brightness.light, LockoutAccent.lime,
              LockoutSchemeStyle.vibrant));
      expect(light.success, const Color(0xFF1E6E47));
      expect(light.categoryRamp.first, const Color(0xFF365E27));
    });
  });
}
```

```dart
// test/contrast_matrix_test.dart
import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('allAppearances is the full 2 x 5 x 3 matrix', () {
    expect(allAppearances.length, 30);
  });

  for (final a in allAppearances) {
    test('${a.key}: every text pair clears 4.5:1', () {
      final c = a.colors, s = a.semantics;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (c.onSurface, c.surface),
        'onSurfaceVariant/surface': (c.onSurfaceVariant, c.surface),
        'onPrimary/primary': (c.onPrimary, c.primary),
        'onPrimaryContainer/primaryContainer':
            (c.onPrimaryContainer, c.primaryContainer),
        'onSecondaryContainer/secondaryContainer':
            (c.onSecondaryContainer, c.secondaryContainer),
        'onSuccess/success': (s.onSuccess, s.success),
        'success/surface': (s.success, c.surface),
        'warning/surface': (s.warning, c.surface),
        'danger/surface': (s.danger, c.surface),
        'restDay/surface': (s.restDay, c.surface),
        'onHeroFill/heroFill': (s.onHeroFill, s.heroFill),
      };
      for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
        expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5),
            reason: '$key in ${a.key}');
      }
    });
  }
}
```

- [ ] **Step 2: Run, expect FAIL** (missing `scheme_style.dart`, wrong arity).

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/palette_test.dart test/contrast_matrix_test.dart`

- [ ] **Step 3: Implement**

`lib/theme/scheme_style.dart`:

```dart
import 'package:flutter/material.dart';

/// The third theme axis: which Material scheme variant the accent seed
/// generates the whole colour scheme with (deviation D12).
///
/// The house system has no such axis. The user chose to let people pick the
/// variant themselves.
enum LockoutSchemeStyle {
  tonal('tonal', 'Tonal', DynamicSchemeVariant.tonalSpot),
  vibrant('vibrant', 'Vibrant', DynamicSchemeVariant.vibrant),
  expressive('expressive', 'Expressive', DynamicSchemeVariant.expressive);

  const LockoutSchemeStyle(this.key, this.label, this.variant);

  /// The value persisted as the third field of `theme_key`.
  final String key;

  /// What the picker calls it. Sentence case.
  final String label;

  final DynamicSchemeVariant variant;

  /// The style on a fresh install, and for any value written before the
  /// axis existed.
  static const LockoutSchemeStyle fallback = tonal;

  /// Never throws; junk becomes [fallback].
  static LockoutSchemeStyle byKey(String key) {
    for (final style in values) {
      if (style.key == key) return style;
    }
    return fallback;
  }
}
```

`lib/theme/palette.dart` — delete every `_light*` / `_dark*` neutral, primary, secondary, tertiary, error and inverse constant. KEEP `_lightSuccess`, `_lightSuccessContainer`, `_darkSuccess`, `_darkSuccessContainer`, `_lightRamp`, `_darkRamp`. Rewrite the class dartdoc to say the scheme is generated (D11). Then:

```dart
  /// The `ColorScheme` for a brightness, accent and style.
  ///
  /// Generated, not authored (deviation D11): the accent seeds Material's own
  /// tonal algorithm, so surfaces, containers and controls all follow it.
  /// `surfaceTint` is cleared because elevation reads through the container
  /// roles, not through a tint overlay.
  static ColorScheme schemeFor(
    Brightness brightness,
    LockoutAccent accent,
    LockoutSchemeStyle style,
  ) {
    return ColorScheme.fromSeed(
      seedColor: accent.accent,
      brightness: brightness,
      dynamicSchemeVariant: style.variant,
    ).copyWith(surfaceTint: Colors.transparent);
  }

  /// The roles Material 3 has none for.
  ///
  /// [scheme] is the generated scheme these roles will sit on. `restDay` and
  /// `danger` follow it; `success`, `warning`, the chart fill and the
  /// category ramp keep their authored values, re-verified against every
  /// generated surface by `contrast_matrix_test.dart`. The hero keeps the
  /// exact accent: a generated tonal lime is muted, and the hero is where
  /// Rep lime has to read as itself.
  static LockoutSemantics semanticsFor(
    Brightness brightness,
    LockoutAccent accent,
    ColorScheme scheme,
  ) {
    final light = brightness == Brightness.light;
    return LockoutSemantics(
      success: light ? _lightSuccess : _darkSuccess,
      onSuccess: light ? const Color(0xFFFFFFFF) : const Color(0xFF0F3D27),
      warning: light ? const Color(0xFF8A5A00) : const Color(0xFFE8C06A),
      danger: scheme.error,
      restDay: scheme.onSurfaceVariant,
      chartLine: accent.accent,
      chartFill: light ? _lightSuccessContainer : _darkSuccessContainer,
      categoryRamp: light ? _lightRamp : _darkRamp,
      heroFill: accent.accent,
      onHeroFill: accent.ink,
    );
  }
```

Add `import 'scheme_style.dart';`. If `contrast_matrix_test` reports a failing pair, STOP and report the pair and ratio — do not retune a value silently.

`lib/theme/lockout_semantics.dart` — add fields with dartdoc ("The hero card's fill: the exact accent, whatever the generated scheme is"), constructor params, `copyWith` params, `lerp` lines (`Color.lerp(heroFill, other.heroFill, t)!`). Remove the "dynamic (Material You) scheme" phrasing from the class dartdoc; it is a generated scheme now.

`lib/widgets/house/nv_hero_card.dart:48` — the fill becomes `LockoutSemantics.of(context).heroFill`, and every `colors.onPrimaryContainer` in the card becomes `.onHeroFill`. Update `test/nv_hero_card_test.dart` expectations accordingly.

`lib/theme/theme_controller.dart:57-72`:

```dart
  ThemeData get lightTheme => _themeFor(Brightness.light);
  ThemeData get darkTheme => _themeFor(Brightness.dark);

  ThemeData _themeFor(Brightness brightness) {
    final colors =
        LockoutPalette.schemeFor(brightness, _accent, LockoutSchemeStyle.tonal);
    return LockoutTheme.build(
      colors: colors,
      semantics: LockoutPalette.semanticsFor(brightness, _accent, colors),
    );
  }
```
Keep the existing "Always non-null now" dartdoc on `darkTheme`.

`test/test_helpers.dart` — `TestAppearance` gains `final LockoutSchemeStyle style;` as an optional third positional (default `LockoutSchemeStyle.tonal`), `colors` passes it, `semantics` calls `LockoutPalette.semanticsFor(brightness, accent, colors)`, `key` returns `'${brightness.name}|${accent.key}|${style.key}'`, and `allAppearances` loops styles × accents × brightness. Update its dartdoc ("two independent axes" → three).

`test/expressive_contract_test.dart` — each call site gets `LockoutSchemeStyle.tonal` and the new `semanticsFor` form. The test at `:196` that asserts house hexes are declared in the house document now only applies to the authored roles left (success, ramp); rewrite it to check those and say why in its comment (D11).

- [ ] **Step 4: Run the two new files, then the full suite. Expect PASS.** Any other failing test that pinned an old neutral hex is updated to read the role from `lightAppearance.colors` / `darkAppearance.colors` instead; list each in the report.

- [ ] **Step 5: Commit** — `git commit -m "feat(theme): generate the scheme from the accent seed (D11)"`

---

### Task 4: Style axis — storage, migration, controller, Settings

**Files:**
- Modify: `lib/theme/theme_controller.dart`
- Modify: `lib/screens/settings_screen.dart` (`_buildAppearanceCard` ~`:883-940`, add `_applyStyle` next to `_applyAccent` ~`:487`)
- Test: `test/theme_controller_test.dart`, `test/theme_picker_test.dart`

**Interfaces:**
- Consumes: `LockoutSchemeStyle` (Task 3).
- Produces: `ThemeController.style` getter; `Future<void> ThemeController.selectStyle(LockoutSchemeStyle style)`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/theme_controller_test.dart — follow the file's existing pattern for
// overriding ThemeController.readStoredChoice and reading back the saved
// setting; restore in addTearDown.
const cases = <String, String>{
  // three-part values survive
  'dark|teal|vibrant': 'dark|teal|vibrant',
  'light|lime|expressive': 'light|lime|expressive',
  // branch-1 two-part values gain tonal
  'dark|teal': 'dark|teal|tonal',
  'system|lime': 'system|lime|tonal',
  'light|coral': 'light|coral|tonal',
  // the six retired single keys plus dynamic
  'graphite': 'dark|steel|tonal',
  'paper': 'light|steel|tonal',
  'ember': 'dark|coral|tonal',
  'linen': 'light|coral|tonal',
  'indigo': 'dark|violet|tonal',
  'frost': 'light|teal|tonal',
  'dynamic': 'system|lime|tonal',
  // pre-scheme keys, folded first hop
  'carbon_lime': 'dark|steel|tonal',
  'mint_lab': 'light|teal|tonal',
  // junk and absent
  '': 'system|lime|tonal',
  'nonsense': 'system|lime|tonal',
  'dark|teal|neon': 'dark|teal|tonal',
};
for (final MapEntry(key: stored, value: canonical) in cases.entries) {
  test('"$stored" resolves and is written back as "$canonical"', () async {
    ThemeController.readStoredChoice = () async => stored;
    addTearDown(() => ThemeController.readStoredChoice =
        ThemeController.defaultReadStoredChoice);
    await ThemeController.instance.load();
    final parts = canonical.split('|');
    expect(ThemeController.instance.brightnessChoice.key, parts[0]);
    expect(ThemeController.instance.accent.key, parts[1]);
    expect(ThemeController.instance.style.key, parts[2]);
    expect(await savedThemeKey(), stored == canonical ? stored : canonical);
  });
}

test('selectStyle persists then commits, and the last tap wins', () async {
  // mirror the existing selectAccent race test: fire vibrant then tonal
  // without awaiting the first; expect style == tonal and stored == ...|tonal.
});

test('selectStyle keeps brightness and accent', () async {
  await ThemeController.instance.selectAccent(LockoutAccent.teal);
  await ThemeController.instance.selectStyle(LockoutSchemeStyle.expressive);
  expect(await savedThemeKey(), 'system|teal|expressive');
});
```

`savedThemeKey()` is whatever helper the file already uses to read `theme_key`; if none, read it with `DatabaseService.instance.getSetting('theme_key', defaultValue: '')`.

```dart
// test/theme_picker_test.dart
testWidgets('Look and feel offers Tonal, Vibrant, Expressive under Accent',
    (tester) async {
  await tester.pumpWidget(hostedProfileTab());
  await tester.pumpAndSettle();
  // scroll to Look and feel the way this file already does
  expect(find.text('Style'), findsOneWidget);
  for (final s in LockoutSchemeStyle.values) {
    expect(find.text(s.label), findsOneWidget);
  }
  final accentY = tester.getTopLeft(find.text('Accent')).dy;
  expect(tester.getTopLeft(find.text('Style')).dy, greaterThan(accentY));
});

testWidgets('choosing Vibrant repaints the app at once', (tester) async {
  await tester.pumpWidget(hostedProfileTab());
  await tester.pumpAndSettle();
  final before = Theme.of(tester.element(find.text('Style'))).colorScheme;
  await tester.tap(find.text('Vibrant'));
  await tester.pumpAndSettle();
  final after = Theme.of(tester.element(find.text('Style'))).colorScheme;
  expect(ThemeController.instance.style, LockoutSchemeStyle.vibrant);
  expect(after.primary, isNot(before.primary));
});
```

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement — controller**

In `theme_controller.dart`:
- Class dartdoc: "Two axes, not three" → "Three axes": brightness, accent, and the scheme style (D12). Keep the paragraph on why there is still no wallpaper axis.
- `_separator` dartdoc: "The three axes are stored in one setting as `brightness|accent|style`, so the schema does not change. A single separator rather than JSON: the fields are short closed sets with no separator in any key."
- Add `LockoutSchemeStyle _style = LockoutSchemeStyle.fallback;`, `LockoutSchemeStyle get style => _style;`, `LockoutSchemeStyle? _pendingStyle;`.
- `_themeFor` passes `_style` instead of `LockoutSchemeStyle.tonal`.
- `_persist(brightness, accent, style)` and `_encode(brightness, accent, style)` take all three; `selectBrightness` / `selectAccent` pass `_pendingStyle ?? _style`.
- `selectStyle` — same shape as `selectAccent`:

```dart
  Future<void> selectStyle(LockoutSchemeStyle style) async {
    if (style == (_pendingStyle ?? _style)) return;
    _pendingStyle = style;
    try {
      await _persist(
        _pendingBrightness ?? _brightness,
        _pendingAccent ?? _accent,
        style,
      );
      if (_pendingStyle != style) return;
      _style = style;
      notifyListeners();
    } finally {
      if (_pendingStyle == style) _pendingStyle = null;
    }
  }
```

- `_resolve` returns `(LockoutBrightnessChoice, LockoutAccent, LockoutSchemeStyle)`:

```dart
    if (saved.contains(_separator)) {
      final parts = saved.split(_separator);
      return (
        LockoutBrightnessChoice.byKey(parts.first),
        LockoutAccent.byKey(parts.length > 1 ? parts[1] : ''),
        // A two-part value was written by a branch-1 build, before the style
        // axis existed; it was on the house palette, and tonal is the closest
        // generated look.
        LockoutSchemeStyle.byKey(parts.length > 2 ? parts[2] : ''),
      );
    }
    final key = _preSchemeKeys[saved] ?? saved;
    return (
      _legacyBrightness[key] ?? LockoutBrightnessChoice.system,
      LockoutAccent.byKey(key),
      LockoutSchemeStyle.fallback,
    );
```
- `load()` destructures three and writes back `_encode(b, a, s)` when it differs from `saved` (unchanged logic).
- `resetForTest()` also resets `_style` and `_pendingStyle`.

- [ ] **Step 4: Implement — Settings**

Next to `_applyAccent` add `_applyStyle(LockoutSchemeStyle style)`, a copy of `_applyAccent`'s body with `selectStyle` and the same failure toast. In `_buildAppearanceCard`, after the accent `Wrap`:

```dart
        const SizedBox(height: LockoutTheme.sectionGap),
        Text('Style', style: theme.textTheme.titleSmall),
        const SizedBox(height: LockoutTheme.headingGap),
        NvSegmentedButton<LockoutSchemeStyle>(
          segments: [
            for (final style in LockoutSchemeStyle.values)
              NvSegment(value: style, label: style.label),
          ],
          selected: controller.style,
          onChanged: _applyStyle,
        ),
```
Update the method dartdoc: "two independent axes, nothing else" → three axes; the style is a segmented button because it is a short closed set. `_AccentSwatch` already fills with `accent.accent` — add a test asserting the swatch fill equals `accent.accent` under `vibrant` (spec §5.2 "Swatches").

- [ ] **Step 5: Run the two files, then the full suite. Expect PASS.**

- [ ] **Step 6: Commit** — `git commit -m "feat(theme): add the scheme style axis with a three-part theme_key (D12)"`

---

### CHECKPOINT A: Device pass 1 (controller, not a subagent)

Run by the controller after Task 4 is reviewed. Uses `lockout_qa` emulator and a release build.

- [ ] Build and install: `C:\src\flutter\bin\flutter.bat build apk --release` then `adb install -r build\app\outputs\flutter-apk\app-release.apk`.
- [ ] For each style (tonal, vibrant, expressive) × each accent (lime, violet, teal, coral, steel) × light and dark — 30 states — screenshot Today and Profile/Settings: `adb exec-out screencap -p > docs/spine/qa/branch2-pass1/<brightness>-<accent>-<style>-<screen>.png`.
- [ ] Check by eye: hero fill reads as the exact accent; category ramp fills stay distinct against tinted surfaces (spec §7 risk 1); no unreadable text.
- [ ] Write `docs/spine/qa/2026-10-xx-branch2-pass1.md` with findings; send the user a contact sheet.
- [ ] **STOP. The user sees pass 1 before Task 5 starts** (spec §5.6).

---

### Task 5: Shapes adapter and the dependency

**Files:**
- Modify: `pubspec.yaml` (add `material_new_shapes: ^1.0.0` under `dependencies`)
- Create: `lib/theme/lockout_shapes.dart`
- Create: `test/lockout_shapes_test.dart`
- Modify: `test/expressive_contract_test.dart` (`dependencies` group)

**Interfaces:**
- Produces:

```dart
enum LockoutShape {
  circle, square, slanted, arch, pill, diamond, clamShell, pentagon, gem,
  sunny, verySunny, clover4Leaf, clover8Leaf, flower, puffy, bun, heart,
  softBurst, ghostish,
  cookie4, cookie6, cookie9, cookie12;

  /// D5 registers.
  static const LockoutShape rest = cookie4;
  static const LockoutShape training = cookie6;
  static const LockoutShape streak = cookie9;
  static const LockoutShape achievement = cookie12;

  bool get isCookie;
}

class LockoutShapeBorder extends OutlinedBorder {
  const LockoutShapeBorder(this.shape,
      {this.morphTo, this.progress = 0, super.side});
  final LockoutShape shape;
  final LockoutShape? morphTo;
  final double progress; // clamped to [0, 1] when drawn
}
```

- [ ] **Step 1: Add the dependency and confirm it resolves**

Edit `pubspec.yaml`, then run `C:\src\flutter\bin\flutter.bat pub get`.
Expected: resolves. **If it does not resolve, STOP and report the error. Do not hand-port.** (Spec §6.)

- [ ] **Step 2: Write the failing tests**

```dart
// test/lockout_shapes_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_shapes.dart';

void main() {
  const rect = Rect.fromLTWH(10, 20, 40, 40);

  for (final shape in LockoutShape.values) {
    test('$shape stays inside the rect it is given', () {
      final bounds = LockoutShapeBorder(shape).getOuterPath(rect).getBounds();
      expect(bounds.left, greaterThanOrEqualTo(rect.left - 0.01));
      expect(bounds.top, greaterThanOrEqualTo(rect.top - 0.01));
      expect(bounds.right, lessThanOrEqualTo(rect.right + 0.01));
      expect(bounds.bottom, lessThanOrEqualTo(rect.bottom + 0.01));
      expect(bounds.width, greaterThan(rect.width * 0.5),
          reason: 'the shape should fill most of its box');
    });
  }

  test('the four registers are the four cookies', () {
    expect(LockoutShape.rest, LockoutShape.cookie4);
    expect(LockoutShape.training, LockoutShape.cookie6);
    expect(LockoutShape.streak, LockoutShape.cookie9);
    expect(LockoutShape.achievement, LockoutShape.cookie12);
    expect(LockoutShape.values.where((s) => s.isCookie).length, 4);
  });

  test('a morph at 0 and 1 matches its two ends', () {
    Rect b(ShapeBorder s) => s.getOuterPath(rect).getBounds();
    const m0 = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 0);
    const m1 = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1);
    expect(b(m0), _near(b(const LockoutShapeBorder(LockoutShape.gem))));
    expect(b(m1), _near(b(const LockoutShapeBorder(LockoutShape.circle))));
  });

  test('progress outside [0, 1] is clamped, so a spring overshoot is safe',
      () {
    const over = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1.3);
    const end = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1);
    expect(over.getOuterPath(rect).getBounds(),
        _near(end.getOuterPath(rect).getBounds()));
  });

  test('lerp between two borders of one morph interpolates progress', () {
    const a = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 0);
    const b = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1);
    final mid = a.lerpTo(b, 0.5)! as LockoutShapeBorder;
    expect(mid.progress, closeTo(0.5, 1e-9));
  });

  test('equality is value equality', () {
    expect(const LockoutShapeBorder(LockoutShape.gem),
        const LockoutShapeBorder(LockoutShape.gem));
    expect(const LockoutShapeBorder(LockoutShape.gem),
        isNot(const LockoutShapeBorder(LockoutShape.arch)));
  });
}

Matcher _near(Rect r) => predicate<Rect>(
    (x) =>
        (x.left - r.left).abs() < 0.5 &&
        (x.top - r.top).abs() < 0.5 &&
        (x.right - r.right).abs() < 0.5 &&
        (x.bottom - r.bottom).abs() < 0.5,
    'within 0.5 of $r');
```

Contract guard, `dependencies` group in `test/expressive_contract_test.dart`:

```dart
    test('material_new_shapes is the one new package, behind one file', () {
      final declarations = File('pubspec.yaml')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('#'))
          .join('\n');
      expect(declarations.contains('material_new_shapes:'), isTrue);
      for (final file in _dartFilesIn('lib')) {
        if (_posixPath(file.path).endsWith('lib/theme/lockout_shapes.dart')) {
          continue;
        }
        final source = _withoutComments(file.readAsStringSync());
        expect(source.contains('package:material_new_shapes'), isFalse,
            reason: '${file.path} imports material_new_shapes directly; '
                'go through lib/theme/lockout_shapes.dart (D14)');
      }
    });
```
Rename the existing `'no new package arrived, and dynamic_color left'` test to `'dynamic_color and google_fonts stay gone'` — its body is unchanged.

- [ ] **Step 3: Run, expect FAIL.**

- [ ] **Step 4: Implement `lib/theme/lockout_shapes.dart`**

```dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
// `show`, not a bare import: the package exports its own `Cubic`, which would
// shadow the framework curve `LockoutMotion.spring` is built from.
import 'package:material_new_shapes/material_new_shapes.dart'
    show
        MaterialShapes,
        Morph,
        MorphToPathExtension,
        RoundedPolygon,
        RoundedPolygonToPathExtension;

/// The closed set of Material shapes Lockout uses (deviation D13).
///
/// This file is the only importer of `material_new_shapes` (D14); a screen
/// names a shape here and never reaches for the package.
enum LockoutShape {
  circle,
  square,
  slanted,
  arch,
  pill,
  diamond,
  clamShell,
  pentagon,
  gem,
  sunny,
  verySunny,
  clover4Leaf,
  clover8Leaf,
  flower,
  puffy,
  bun,
  heart,
  softBurst,
  ghostish,
  cookie4,
  cookie6,
  cookie9,
  cookie12;

  /// D5's registers. Cookies are reserved for subject-scale elements.
  static const LockoutShape rest = cookie4;
  static const LockoutShape training = cookie6;
  static const LockoutShape streak = cookie9;
  static const LockoutShape achievement = cookie12;

  bool get isCookie =>
      this == cookie4 || this == cookie6 || this == cookie9 || this == cookie12;

  RoundedPolygon get _polygon => switch (this) {
        circle => MaterialShapes.circle,
        square => MaterialShapes.square,
        slanted => MaterialShapes.slanted,
        arch => MaterialShapes.arch,
        pill => MaterialShapes.pill,
        diamond => MaterialShapes.diamond,
        clamShell => MaterialShapes.clamShell,
        pentagon => MaterialShapes.pentagon,
        gem => MaterialShapes.gem,
        sunny => MaterialShapes.sunny,
        verySunny => MaterialShapes.verySunny,
        clover4Leaf => MaterialShapes.clover4Leaf,
        clover8Leaf => MaterialShapes.clover8Leaf,
        flower => MaterialShapes.flower,
        puffy => MaterialShapes.puffy,
        bun => MaterialShapes.bun,
        heart => MaterialShapes.heart,
        softBurst => MaterialShapes.softBurst,
        ghostish => MaterialShapes.ghostish,
        cookie4 => MaterialShapes.cookie4Sided,
        cookie6 => MaterialShapes.cookie6Sided,
        cookie9 => MaterialShapes.cookie9Sided,
        cookie12 => MaterialShapes.cookie12Sided,
      };
}

/// A [LockoutShape] as a `ShapeBorder`, optionally part-way through a morph
/// into a second shape.
///
/// The package's shapes live in a unit square; this scales the path to the
/// rect it is given. [progress] is clamped to [0, 1] when drawn, so a spring
/// curve that overshoots its target cannot extrapolate the path past the end
/// shape.
@immutable
class LockoutShapeBorder extends OutlinedBorder {
  final LockoutShape shape;
  final LockoutShape? morphTo;
  final double progress;

  const LockoutShapeBorder(
    this.shape, {
    this.morphTo,
    this.progress = 0,
    super.side,
  });

  /// A [Morph] matches curves between two shapes, which is the expensive
  /// part. Cached per pair so a press does not re-match on every frame
  /// (spec §7, "shape morph cost").
  static final Map<(LockoutShape, LockoutShape), Morph> _morphs = {};

  Path _unitPath() {
    final to = morphTo;
    if (to == null) return shape._polygon.toPath();
    final morph =
        _morphs.putIfAbsent((shape, to), () => Morph(shape._polygon, to._polygon));
    return morph.toPath(progress: progress.clamp(0.0, 1.0));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final matrix = Matrix4.identity()
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(rect.width, rect.height, 1, 1);
    return _unitPath().transform(matrix.storage);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.strokeInset),
          textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  LockoutShapeBorder copyWith({BorderSide? side}) => LockoutShapeBorder(
        shape,
        morphTo: morphTo,
        progress: progress,
        side: side ?? this.side,
      );

  @override
  ShapeBorder scale(double t) => copyWith(side: side.scale(t));

  /// Interpolates [progress] (and the side) between two borders of the same
  /// morph; anything else falls back to the framework's cross-fade.
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is LockoutShapeBorder && a.shape == shape && a.morphTo == morphTo) {
      return LockoutShapeBorder(
        shape,
        morphTo: morphTo,
        progress: lerpDouble(a.progress, progress, t)!,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is LockoutShapeBorder && b.shape == shape && b.morphTo == morphTo) {
      return LockoutShapeBorder(
        shape,
        morphTo: morphTo,
        progress: lerpDouble(progress, b.progress, t)!,
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is LockoutShapeBorder &&
      other.shape == shape &&
      other.morphTo == morphTo &&
      other.progress == progress &&
      other.side == side;

  @override
  int get hashCode => Object.hash(shape, morphTo, progress, side);

  @override
  String toString() => 'LockoutShapeBorder($shape'
      '${morphTo == null ? '' : ' -> $morphTo @ $progress'})';
}
```

If `translateByDouble`/`scaleByDouble` are not on the pinned `vector_math`, use `..translate(rect.left, rect.top)..scale(rect.width, rect.height)` instead and say so in the report. If any shape fails the bounds test (some package shapes are not normalised), wrap that polygon in `.normalized()` in `_polygon` and note which.

- [ ] **Step 5: Run the shapes test and the contract test, then the full suite. Expect PASS.**

- [ ] **Step 6: Commit** — `git commit -m "feat(theme): add material_new_shapes behind LockoutShapeBorder (D13, D14)"`

---

### Task 6: `NvIconTile` shapes, press morph, and Today's quick-action table

**Files:**
- Modify: `lib/widgets/house/nv_icon_tile.dart` (whole file)
- Modify: `lib/screens/today_tab.dart:649-656` (`_quickActionTile`), `:947-1025` (`_quickActions`)
- Test: `test/nv_icon_tile_test.dart`, `test/today_tab_test.dart`

**Interfaces:**
- Consumes: `LockoutShape`, `LockoutShapeBorder` (Task 5); `LockoutMotion.springFast`.
- Produces: `NvIconTile({Key? key, required IconData icon, required LockoutShape shape, required String label, required VoidCallback onTap})`; top-level `@visibleForTesting const Map<String, LockoutShape> quickActionShapes` in `today_tab.dart`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/nv_icon_tile_test.dart — replace tests that passed `color:`
ShapeDecoration _decoration(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.descendant(
        of: find.byType(NvIconTile), matching: find.byType(DecoratedBox)))
    .map((d) => d.decoration)
    .whereType<ShapeDecoration>()
    .single;

Widget _host({bool reduce = false}) => MaterialApp(
      theme: lockoutTestTheme(lightAppearance),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: Center(
            child: NvIconTile(
              icon: Icons.add,
              shape: LockoutShape.gem,
              label: 'Custom',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

testWidgets('at rest the tile wears its own shape on secondaryContainer',
    (tester) async {
  await tester.pumpWidget(_host());
  final d = _decoration(tester);
  final border = d.shape as LockoutShapeBorder;
  expect(border.shape, LockoutShape.gem);
  expect(border.morphTo, LockoutShape.circle);
  expect(border.progress, 0);
  expect(d.color, lightAppearance.colors.secondaryContainer);
  expect(tester.widget<Icon>(find.byIcon(Icons.add)).color,
      lightAppearance.colors.onSecondaryContainer);
});

testWidgets('pressed, it morphs to a circle on springFast', (tester) async {
  await tester.pumpWidget(_host());
  final gesture =
      await tester.startGesture(tester.getCenter(find.byType(NvIconTile)));
  await tester.pump(const Duration(milliseconds: 125));
  final mid = (_decoration(tester).shape as LockoutShapeBorder).progress;
  expect(mid, greaterThan(0));
  await tester.pump(const Duration(milliseconds: 200));
  expect((_decoration(tester).shape as LockoutShapeBorder).progress,
      closeTo(1, 0.05));
  await gesture.up();
  await tester.pumpAndSettle();
  expect((_decoration(tester).shape as LockoutShapeBorder).progress, 0);
});

testWidgets('under reduced motion the morph is instant', (tester) async {
  await tester.pumpWidget(_host(reduce: true));
  final gesture =
      await tester.startGesture(tester.getCenter(find.byType(NvIconTile)));
  await tester.pump();
  expect((_decoration(tester).shape as LockoutShapeBorder).progress, 1);
  await gesture.up();
});
```
Keep the existing semantics tests (single button node with label and tap action).

```dart
// test/today_tab_test.dart
test('every quick action has its own shape, none a cookie or the circle', () {
  final shapes = quickActionShapes.values.toList();
  expect(shapes.toSet().length, shapes.length);
  expect(shapes.any((s) => s.isCookie || s == LockoutShape.circle), isFalse);
});

testWidgets('each tile wears the shape its table row assigns',
    (tester) async {
  await pumpToday(tester); // existing helper; Food tab enabled
  for (final MapEntry(key: label, value: shape) in quickActionShapes.entries) {
    final tile = tester.widget<NvIconTile>(find.ancestor(
        of: find.text(label), matching: find.byType(NvIconTile)));
    expect(tile.shape, shape, reason: label);
  }
  expect(find.byType(NvIconTile), findsNWidgets(8));
});
```

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement `NvIconTile`**

A `StatefulWidget` with `SingleTickerProviderStateMixin`. Keep the outer `Semantics(button:, label:, onTap:, excludeSemantics: true)` and its comment. Replace the `InkWell` with a `GestureDetector` (`onTapDown` → forward, `onTapUp`/`onTapCancel` → reverse, `onTap: widget.onTap`) so the ripple does not paint outside the shape. Rewrite the class dartdoc: each tile carries its own fixed shape (D13, superseding "one consistent squircle"), and morphs to a circle while pressed.

```dart
class _NvIconTileState extends State<NvIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final tier = LockoutMotion.springFast;
    final duration = tier.durationFor(context);
    if (duration == Duration.zero) {
      _press.value = target;
      return;
    }
    _press.animateTo(target, duration: duration, curve: tier.curve);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _animateTo(1),
        onTapUp: (_) => _animateTo(0),
        onTapCancel: () => _animateTo(0),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LockoutTheme.spaceSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _press,
                builder: (context, child) => DecoratedBox(
                  decoration: ShapeDecoration(
                    color: colors.secondaryContainer,
                    shape: LockoutShapeBorder(
                      widget.shape,
                      morphTo: LockoutShape.circle,
                      progress: _press.value,
                    ),
                  ),
                  child: child,
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(widget.icon,
                      size: 22, color: colors.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: LockoutTheme.spaceSm),
              Text(
                widget.label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

48dp rather than 40: irregular shapes lose area at the edges, and 48 keeps the glyph clear of every outline in the set. (If the Today grid overflows at text scale 1.5 in its existing test, report it; do not shrink below 44.)

- [ ] **Step 4: Implement the Today table**

Above `class TodayTab` in `today_tab.dart`:

```dart
/// Each quick action's fixed shape (deviation D13), assigned once here so
/// the same action wears the same shape on every screen.
///
/// No cookie (those are D5's registers, for subject-scale elements only) and
/// no circle (every tile morphs to it when pressed).
@visibleForTesting
const Map<String, LockoutShape> quickActionShapes = {
  'Log food': LockoutShape.bun,
  'Weigh in': LockoutShape.pentagon,
  'Workout': LockoutShape.gem,
  'History': LockoutShape.arch,
  'Custom': LockoutShape.clover4Leaf,
  'Streak': LockoutShape.sunny,
  'Plan': LockoutShape.diamond,
  'Exercises': LockoutShape.slanted,
};
```

`_quickActionTile` drops `color` and reads `shape: quickActionShapes[label]!`. In `_quickActions`, delete the `tileColor` local and its long comment; replace with one comment: tiles fill with `secondaryContainer` inside `NvIconTile` so they read as tinted by the generated scheme (spec §5.5), and the shape now carries the identity the colour no longer has to. Remove `color: tileColor` from all eight calls.

- [ ] **Step 5: Run both test files, then the full suite. Expect PASS.**

- [ ] **Step 6: Commit** — `git commit -m "feat(today): give each quick action its own Material shape with a press morph"`

---

### Task 7: Cookie shapes onto the package; delete `CookieBorder`

**Files:**
- Modify: `lib/screens/today_tab.dart:723` (hero day marker), `:1131-1132` (session marker)
- Modify: `lib/screens/settings_screen.dart:867` (header medallion, 12 = achievement), `:1413-1441` (`_AccentSwatch`)
- Delete: `lib/theme/cookie_border.dart`, `test/cookie_border_test.dart`
- Modify tests: `test/nv_hero_card_test.dart:126,144`, `test/today_pre_session_test.dart:114,162`, `test/today_tab_test.dart:1039-1061`, `test/theme_picker_test.dart` (swatch shape assertions — `grep -n CookieBorder test/`)
- Modify: `test/expressive_contract_test.dart` (`shape` group)
- Modify: `docs/spine/orphaned-widgets.md` only if something outside the rebuilt screens still imports `CookieBorder` (at plan time nothing does)

**Interfaces:**
- Consumes: `LockoutShape.rest|training|streak|achievement`, `LockoutShapeBorder` (Task 5).
- Produces: nothing new. `CookieBorder` ceases to exist.

- [ ] **Step 1: Rewrite the failing tests**

Every `CookieBorder.training` expectation becomes `const LockoutShapeBorder(LockoutShape.training)`; `CookieBorder.rest` becomes `const LockoutShapeBorder(LockoutShape.rest)`; `.whereType<CookieBorder>()` becomes `.whereType<LockoutShapeBorder>()` with an added `expect(border.shape.isCookie, isTrue)`. Add:

```dart
// test/theme_picker_test.dart
testWidgets('a swatch is a six-cookie in its own accent, ringed when chosen',
    (tester) async {
  await tester.pumpWidget(hostedProfileTab());
  await tester.pumpAndSettle();
  // locate the lime swatch via its Semantics label 'Rep lime'
  final d = /* the swatch's AnimatedContainer decoration */
      as ShapeDecoration;
  final border = d.shape as LockoutShapeBorder;
  expect(border.shape, LockoutShape.training);
  expect(d.color, LockoutAccent.lime.accent);
  expect(border.side.width, 2);
});
```

Contract guard, `shape` group:

```dart
    test('CookieBorder is gone, and no rebuilt screen names it', () {
      expect(File('lib/theme/cookie_border.dart').existsSync(), isFalse);
      for (final path in _rebuiltScreens) {
        final source = _withoutComments(File(path).readAsStringSync());
        expect(source.contains('CookieBorder'), isFalse,
            reason: '$path still draws a CookieBorder; use '
                'LockoutShapeBorder with a D5 register');
      }
    });

    test('a cookie shape appears only as a register', () {
      // Rebuilt screens must name the register, not the raw cookie.
      for (final path in _rebuiltScreens) {
        final source = _withoutComments(File(path).readAsStringSync());
        expect(RegExp(r'LockoutShape\.cookie\d+').hasMatch(source), isFalse,
            reason: '$path names a raw cookie; use LockoutShape.rest, '
                '.training, .streak or .achievement');
      }
    });
```

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement**
  - Today hero marker: `shape: LockoutShapeBorder(isRest ? LockoutShape.rest : LockoutShape.training)`.
  - Today session marker: `shape: LockoutShapeBorder(_sessionTotalSets > 0 ? LockoutShape.training : LockoutShape.rest)`.
  - Settings header: `shape: const LockoutShapeBorder(LockoutShape.achievement)`.
  - `_AccentSwatch`: `customBorder: const LockoutShapeBorder(LockoutShape.training)`; decoration shape `LockoutShapeBorder(LockoutShape.training, side: BorderSide(color: selected ? colors.onSurface : Colors.transparent, width: 2))`. The lobe-amplitude growth is gone — the package cookie has a fixed outline — so the rest/selected morph is the diameter (34→44, unchanged) plus the ring. Rewrite the two comments that explain the amplitude to say this.
  - Update comments that say "lobed" / "polar-rose" in these call sites to "cookie shape, D5 register".
  - Replace imports of `../theme/cookie_border.dart` with `../theme/lockout_shapes.dart`.
  - `grep -rn "cookie_border\|CookieBorder" lib test` must return nothing outside comments that explain history. Then delete `lib/theme/cookie_border.dart` and `test/cookie_border_test.dart`.
  - Update the `.spine/context.md` **Lobed shape** entry: "a Material cookie shape (4, 6, 9 or 12 sides) from `LockoutShape`, drawn by `LockoutShapeBorder`."

- [ ] **Step 4: Run the touched files, then the full suite.** Expected count drops by the number of tests in `cookie_border_test.dart` (state the number) and rises by the new ones.

- [ ] **Step 5: Commit** — `git commit -m "refactor(theme): draw the D5 registers with Material cookies and delete CookieBorder"`

---

### Task 8: `NvNavigationBar`, consumed by `BottomNav`

**Files:**
- Create: `lib/widgets/house/nv_navigation_bar.dart`
- Modify: `lib/widgets/bottom_nav.dart:142-166` (`build`)
- Create: `test/nv_navigation_bar_test.dart`
- Modify: `test/bottom_nav_test.dart:67-110`
- Modify: `test/expressive_contract_test.dart` (`the house catalog` group)

**Interfaces:**
- Consumes: `LockoutMotion.springDefault`, `springFast`.
- Produces:

```dart
class NvNavigationDestination {
  const NvNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class NvNavigationBar extends StatefulWidget {
  const NvNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });
  static const double height = 64;
  static const Size indicatorSize = Size(56, 32);
}
```

- [ ] **Step 1: Write the failing tests**

```dart
// test/nv_navigation_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_navigation_bar.dart';

import 'test_helpers.dart';

const _dests = [
  NvNavigationDestination(
      icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  NvNavigationDestination(
      icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
];

Widget _host(int index, ValueChanged<int> onTap, {bool reduce = false}) =>
    MaterialApp(
      theme: lockoutTestTheme(lightAppearance),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          bottomNavigationBar: NvNavigationBar(
            selectedIndex: index,
            onDestinationSelected: onTap,
            destinations: _dests,
          ),
        ),
      ),
    );

Finder _indicator() => find.byKey(const ValueKey('nv-nav-indicator'));

void main() {
  testWidgets('64dp on surfaceContainer, every label shown', (tester) async {
    await tester.pumpWidget(_host(0, (_) {}));
    final bar = find.byType(NvNavigationBar);
    expect(tester.getSize(bar).height, NvNavigationBar.height);
    final material = tester.widget<Material>(
        find.descendant(of: bar, matching: find.byType(Material)).first);
    expect(material.color, lightAppearance.colors.surfaceContainer);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('selected icon is the filled variant', (tester) async {
    await tester.pumpWidget(_host(0, (_) {}));
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('the pill indicator is 56x32 and sits under the selection',
      (tester) async {
    await tester.pumpWidget(_host(1, (_) {}));
    await tester.pumpAndSettle();
    expect(tester.getSize(_indicator()), NvNavigationBar.indicatorSize);
    expect(tester.getCenter(_indicator()).dx,
        closeTo(tester.getCenter(find.byIcon(Icons.person)).dx, 0.5));
  });

  testWidgets('the indicator springs between destinations', (tester) async {
    var index = 0;
    await tester.pumpWidget(StatefulBuilder(
        builder: (_, set) => _host(index, (i) => set(() => index = i))));
    final from = tester.getCenter(_indicator()).dx;
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getCenter(_indicator()).dx;
    await tester.pumpAndSettle();
    final to = tester.getCenter(_indicator()).dx;
    expect(mid, greaterThan(from));
    expect(mid, lessThan(to));
  });

  testWidgets('reduced motion moves the indicator instantly', (tester) async {
    var index = 0;
    await tester.pumpWidget(StatefulBuilder(
        builder: (_, set) =>
            _host(index, (i) => set(() => index = i), reduce: true)));
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(tester.getCenter(_indicator()).dx,
        closeTo(tester.getCenter(find.byIcon(Icons.person)).dx, 0.5));
  });

  testWidgets('a press squashes the indicator, release recovers',
      (tester) async {
    await tester.pumpWidget(_host(0, (_) {}));
    final rest = tester.getSize(_indicator());
    final g = await tester.startGesture(tester.getCenter(find.text('Home')));
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getSize(_indicator()).width, lessThan(rest.width));
    await g.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(_indicator()), rest);
  });

  testWidgets('one semantics node per destination, labelled and selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(0, (_) {}));
    expect(
        tester.getSemantics(find.text('Home')),
        matchesSemantics(
            label: 'Home',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true));
    expect(
        tester.getSemantics(find.text('Profile')),
        matchesSemantics(
            label: 'Profile',
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true));
    handle.dispose();
  });

  testWidgets('tapping reports the index', (tester) async {
    int? tapped;
    await tester.pumpWidget(_host(0, (i) => tapped = i));
    await tester.tap(find.text('Profile'));
    expect(tapped, 1);
  });
}
```

`test/bottom_nav_test.dart:67-110` — `NavigationBar` → `NvNavigationBar`; `NavigationDestination` count assertions → `find.byType(NvNavigationBar)` plus `find.text(label)` for each visible tab. Keep the `lastRenderedHeight` tests unchanged; they must still pass.

Contract guard, `the house catalog` group:

```dart
    test('no framework NavigationBar outside NvNavigationBar', () {
      for (final file in _dartFilesIn('lib')) {
        if (_posixPath(file.path)
            .endsWith('widgets/house/nv_navigation_bar.dart')) {
          continue;
        }
        final source = _withoutComments(file.readAsStringSync());
        expect(RegExp(r'\bNavigationBar\s*\(').hasMatch(source), isFalse,
            reason: '${file.path} builds a stock NavigationBar; use '
                'NvNavigationBar');
      }
    });
```
(`\bNavigationBar` does not match inside `NvNavigationBar`, and `bottomNavigationBar:` has no `(` after it.)

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement `nv_navigation_bar.dart`**

Structure (the implementer has latitude inside it, not on the seam):
- `Material(color: colors.surfaceContainer)` → `SafeArea(top: false)` → `ConstrainedBox(constraints: BoxConstraints(minHeight: NvNavigationBar.height))` → `LayoutBuilder` → `Stack`.
- Slot width = `constraints.maxWidth / destinations.length`.
- Indicator: `AnimatedPositioned(key: ValueKey('nv-nav-indicator'), duration: LockoutMotion.springDefault.durationFor(context), curve: LockoutMotion.springDefault.curve, top: 12, left: selectedIndex * slot + (slot - indicatorWidth) / 2, width: indicatorWidth, height: 32)` holding `DecoratedBox(decoration: ShapeDecoration(color: colors.secondaryContainer, shape: const StadiumBorder()))`.
- Squash: state `int? _pressed`; `indicatorWidth` is `56 * 0.85` while `_pressed == selectedIndex`, else 56. Do the squash with a second `TweenAnimationBuilder<double>` on `springFast` driving the width, inside the positioned box, so it does not reuse the slide's 450ms. Under reduced motion both durations are zero.
- Destinations row on top of the indicator: `Row` of `Expanded`, each:

```dart
Semantics(
  button: true,
  selected: selected,
  label: d.label,
  onTap: () => widget.onDestinationSelected(i),
  excludeSemantics: true,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _pressed = i),
    onTapUp: (_) => setState(() => _pressed = null),
    onTapCancel: () => setState(() => _pressed = null),
    onTap: () => widget.onDestinationSelected(i),
    child: Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 32,
          child: Icon(selected ? d.selectedIcon : d.icon,
              size: 24,
              color: selected
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(d.label,
            style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : null),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  ),
)
```

If 12 + 32 + 4 + label + 4 exceeds 64 at text scale 1.0 with `labelMedium`, reduce the top padding to fit 64 exactly and note it; the bar grows past 64 only at larger text scales (that is why it is `minHeight`).
- Class dartdoc: the Material 3 Expressive short navigation bar; why bespoke (the framework `NavigationBar` is the stock M3 bar the user rejected, spec §1 item 3); the four behaviours from spec §5.4.

`bottom_nav.dart` `build` — keep `key: _barKey` and the index clamp:

```dart
    return NvNavigationBar(
      key: _barKey,
      selectedIndex: index,
      onDestinationSelected: widget.onTap,
      destinations: [
        for (final tab in tabs)
          NvNavigationDestination(
            icon: tab.icon,
            selectedIcon: tab.selectedIcon,
            label: tab.label,
          ),
      ],
    );
```
Update the `NavTabDef.icon` dartdoc only if it names `NavigationBar`. Remove the stock bar's `navigationBarTheme` from `lockout_theme.dart` only if nothing else reads it (`grep -n navigationBarTheme lib`); otherwise leave it.

- [ ] **Step 4: Run the three test files, then the full suite. Expect PASS.**

- [ ] **Step 5: Commit** — `git commit -m "feat(nav): replace the stock NavigationBar with the Expressive NvNavigationBar"`

---

### Task 9: Role audit of the rebuilt screens and catalog

**Files:**
- Read: `lib/screens/today_tab.dart`, `profile_tab.dart`, `settings_screen.dart`, `about_screen.dart`, every file in `lib/widgets/house/`
- Modify: whichever of those hard-code a role chosen for the old fixed palette
- Create: `docs/spine/qa/2026-10-29-branch2-role-audit.md`
- Create: `docs/spine/tickets/branch-3-4-colour-debt.md` (old-screen findings, not fixed here)
- Test: `test/expressive_contract_test.dart`

**Interfaces:** none new.

- [ ] **Step 1: Write the failing guard**

```dart
  group('generated-scheme readiness', () {
    test('no rebuilt screen or catalog widget holds a colour literal', () {
      final files = [
        ..._rebuiltScreens.map(File.new),
        ..._dartFilesIn('lib/widgets/house'),
      ];
      for (final file in files) {
        final source = _withoutComments(file.readAsStringSync());
        expect(RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').hasMatch(source), isFalse,
            reason: '${file.path} holds a colour literal that cannot follow '
                'the generated scheme');
        expect(source.contains('Colors.') &&
                RegExp(r'Colors\.(?!transparent\b)\w+').hasMatch(source),
            isFalse,
            reason: '${file.path} reaches for a Colors.* constant');
      }
    });
  });
```

- [ ] **Step 2: Run it.** If it already passes, it is a characterisation guard; say so.

- [ ] **Step 3: Audit.** For each file, list every `colorScheme.<role>` read in a table: file:line, role, what it paints, and whether that role still means the right thing under a generated scheme (e.g. `inverseSurface` for a tile fill was a fixed-palette choice — already moved in Task 6). Confirm: filled `NvButton` is on `primary`; the selected segment on `secondaryContainer` (M3 standard, kept); the hero on `heroFill`. Re-point any role that was chosen only because of the old fixed neutrals, with a test per change.

- [ ] **Step 4: Old screens.** `grep -rn "Color(0x\|Colors\.\(white\|black\|grey\)" lib/screens lib/widgets --include=*.dart` minus the rebuilt files and `lib/widgets/house/`. Record each hit in the tickets file as owed to branch 3 (Workout) or branch 4 (Progress, Body, Log, Food). Do not fix them.

- [ ] **Step 5: Full suite. Commit** — `git commit -m "docs(qa): audit rebuilt screens against the generated scheme"`

---

### CHECKPOINT B: Device pass 2 (controller)

- [ ] Release build on `lockout_qa`. Screenshots to `docs/spine/qa/branch2-pass2/`.
- [ ] Quick-action shapes, and each press morph (screen-record one press: `adb shell screenrecord`). Watch frame time with `flutter run --profile` + the performance overlay on the Today grid (spec §7 risk 3; fallback is caching the two paths per tile).
- [ ] Nav bar: indicator slide and squash on every tab; Food tab hidden case.
- [ ] Hero marker, session marker, header medallion, swatches.
- [ ] Text scale 1.0 and 1.5 (`adb shell settings put system font_scale 1.5`).
- [ ] Task-1 loose ends: "Today · Wed", "Custom session", activity levels, caption sizes, disabled stepper end.
- [ ] Ask the user for a TalkBack listen to the appearance picker (now with Style) and the new nav bar.
- [ ] Write `docs/spine/qa/2026-10-xx-branch2-pass2.md`, stamp `.spine/qa-receipt`.

Then REVIEW (`requesting-code-review`, whole branch) and FINISH.

---

## Self-review

**Spec coverage**

| Spec | Task |
| --- | --- |
| §2.1 sentence case, headings, disabled icon button | 1 |
| §2.1 round-3 Minors 3–7, 9–11 | 2 (10 in 1) |
| §5.1 colour engine, heroFill, semantics signature, 30-combo contrast | 3 |
| §5.2 storage, migration, controller, Settings Style, swatch fill | 4 |
| §5.6 device pass 1 before shapes | Checkpoint A |
| §5.3 dependency, one mapping point, `LockoutShapes` closed set + adapter | 5 |
| §5.3 `NvIconTile` shape + morph, quick-action table, 8 distinct | 6 |
| §5.5 tiles to `secondaryContainer` | 6 |
| §5.3 cookies onto package, `CookieBorder` deletion | 7 |
| §5.4 `NvNavigationBar` | 8 |
| §5.5 role audit, button on `primary` | 3 (complaint-1 test), 9 |
| §6 old-screen colour tickets | 9 |
| §5.6 guards: package import, NavigationBar, CookieBorder | 5, 8, 7 |
| §5.6 device pass 2 + TalkBack | Checkpoint B |

Spec §5.3 names the closed set `LockoutShapes`; the plan calls the enum `LockoutShape` (singular, one value per shape, matching `LockoutAccent`). The file is still `lockout_shapes.dart`.

The spec lists four subject-scale elements, including a "progress hero medallion". In code, the four cookie call sites are the Today hero marker, the Today session marker, the Settings header medallion and the accent swatch; `progress_hero.dart` draws no cookie today. Task 7 migrates the five real call sites.

**Type consistency** — checked: `schemeFor(b, a, s)`, `semanticsFor(b, a, scheme)`, `LockoutSchemeStyle.{key,label,variant,byKey,fallback}`, `selectStyle`, `LockoutShape.{rest,training,streak,achievement,isCookie}`, `LockoutShapeBorder(shape, morphTo:, progress:, side:)`, `NvIconTile(icon:, shape:, label:, onTap:)`, `NvNavigationBar(selectedIndex:, onDestinationSelected:, destinations:)`, `NvNavigationDestination(icon:, selectedIcon:, label:)`.
