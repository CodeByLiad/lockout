# House Rebuild — Branch 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-dev (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Today and Profile/Settings from a house component catalog under `lib/widgets/house/`, so screen composition follows `docs/design/nuvetrix-app-design-system.md` rather than the previous design wearing house tokens.

**Architecture:** Each `Nv*` component is written in the same task as its first real consumer screen and is never merged without one. Components compose the two existing shape-as-state primitives (`MorphingSurface`, `ConnectedGroup`) and read colour, type, shape and motion through `Theme.of(context)`, `LockoutSemantics.of(context)` and `LockoutMotion`. Screens are rewritten, not restyled: a rebuilt screen imports from `lib/widgets/house/` and the theme only.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, sqflite, no new package dependencies.

**Spec:** `docs/spine/specs/2026-10-07-house-rebuild-design.md`
**House document:** `docs/design/nuvetrix-app-design-system.md` (v1.1)

## Global Constraints

- Flutter SDK is **not on PATH**. Every command uses the absolute path `C:\src\flutter\bin\flutter.bat`.
- Tests are **serial**: `C:\src\flutter\bin\flutter.bat test --concurrency=1`. Suites share one sqflite file; the default parallel run produces ~10 spurious failures.
- Baseline at branch start: **695 tests passing**. No task may reduce that number.
- **No new package dependencies.** Shape, motion and the bespoke controls are framework-only.
- **No compile-time colour constant and no static token class** in any new widget. Colour resolves through `Theme.of(context).colorScheme` or `LockoutSemantics.of(context)`.
- **No hand-rolled `Duration`.** Animated surfaces use a `LockoutMotion` tier and `tier.durationFor(context)`, which returns `Duration.zero` under reduced motion.
- **Sentence case everywhere.** No all-caps copy, no `toUpperCase()` on display strings (house §4.2, deviation D8).
- **Consumer-pulled rule:** a component in `lib/widgets/house/` must be built by a screen in the same commit. A variant with no consumer at branch end is recorded as deliberately absent in the spec, not written speculatively.
- Spacing: screen margins 20 dp for text/headings and 16 dp for grouped lists/cards, section gap 28 dp, heading-to-content 12 dp, 128 dp bottom padding on scrollable screens. Constants already exist on `LockoutTheme`.
- Old widgets under `lib/widgets/` are **not deleted on this branch** — the five out-of-scope screens still consume them. Each task records what it orphaned.
- Commit messages are normal English, imperative mood, with the trailer `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.

## Before Task 1

The branch does not exist yet. ISOLATE (`using-git-worktrees`) creates it off `expressive-restyle-branch-1` at `811fdce`, and `.spine/frame-approved` is re-stamped to the new branch name — switching branch after approval is a genuine re-approval event, and the Frame Gate hook reads the marker file. Confirm the clean baseline before Task 1: `C:\src\flutter\bin\flutter.bat test --concurrency=1` reports 695 passing.

## File Structure and Seams

| File | Responsibility | Seam (the interface callers depend on) |
| --- | --- | --- |
| `lib/widgets/house/nv_button.dart` | Every button variant and the icon button | `NvButton({required NvButtonVariant variant, required String label, IconData? icon, required VoidCallback? onPressed, bool large})`, `NvIconButton({required IconData icon, required String tooltip, required VoidCallback? onPressed})` |
| `lib/widgets/house/nv_hero_card.dart` | The one accent hero card per screen | `NvHeroCard({required String title, required String value, required String unit, Widget? marker, double? progress, List<Widget> actions})` |
| `lib/widgets/house/nv_grouped_list.dart` | Grouped list and its row | `NvGroupedList({required List<Widget> children})`, `NvListItem({Widget? leading, required String title, String? supporting, Widget? trailing, VoidCallback? onTap})` |
| `lib/widgets/house/nv_status_badge.dart` | Right-hand badge on a list row | `NvStatusBadge({required String label, required NvBadgeKind kind})` |
| `lib/widgets/house/nv_cards.dart` | Info card and TBA card | `NvInfoCard({required Widget child})`, `NvTbaCard({required String message})` |
| `lib/widgets/house/nv_empty_state.dart` | Empty state block | `NvEmptyState({required String headline, required String body, required String actionLabel, required VoidCallback onAction})` |
| `lib/widgets/house/nv_wavy_progress.dart` | Wavy linear progress, the only ambient motion | `NvWavyProgress({required double value})` |
| `lib/widgets/house/nv_icon_tile.dart` | 40 dp squircle icon tile for the action grid | `NvIconTile({required IconData icon, required Color color, required String label, required VoidCallback onTap})` |
| `lib/widgets/house/nv_text_field.dart` | Outlined text field, label above | `NvTextField({required String label, required TextEditingController controller, TextInputType? keyboardType, String? errorText})` |
| `lib/widgets/house/nv_sheet.dart` | Bottom sheet and snackbar | `showNvSheet<T>({required BuildContext context, required Widget child})`, `showNvSnackbar({required BuildContext context, required String message})` |
| `lib/widgets/house/nv_dialog.dart` | Destructive confirmation only | `showNvDestructiveDialog({required BuildContext context, required String title, required String body, required String confirmLabel})` |
| `lib/widgets/house/nv_segmented_button.dart` | Bespoke segmented control (retires D9) | `NvSegmentedButton<T>({required List<NvSegment<T>> segments, required T selected, required ValueChanged<T> onChanged})` |
| `lib/widgets/house/nv_switch.dart` | Switch row | `NvSwitchRow({required String title, String? supporting, required bool value, required ValueChanged<bool> onChanged})` |
| `lib/screens/today_tab.dart` | Rebuilt: composes house components only | Public `TodayTabState` API unchanged — `main_screen.dart` and the existing tests depend on it |
| `lib/screens/settings_screen.dart` | Rebuilt: §12.2 order | `SettingsBody` / `SettingsBodyState` names unchanged |
| `lib/screens/about_screen.dart` | New pushed screen | `AboutScreen()` |

**Interface ownership:** the signatures above are approved as part of this plan. An implementer changes an implementation freely behind them; changing a signature requires updating this plan first.

---

### Task 1: NvButton family, consumed by Today's pre-session actions

Builds the Accent and Tonal variants only — the two Today's pre-session actually presses. Other variants arrive with their own consumers in later tasks. Closes deviation D10: the press morph reads reduced motion from `BuildContext` via `MorphingSurface`, which a context-free `ThemeData` could not.

**Files:**
- Create: `lib/widgets/house/nv_button.dart`
- Create: `test/nv_button_test.dart`
- Modify: `lib/screens/today_tab.dart:528-571` (`_buildPreSession`'s `heroActions`)

**Interfaces:**
- Consumes: `MorphingSurface` from `lib/widgets/morphing_surface.dart`; `LockoutTheme.radiusButtonRest`, `radiusButtonActive`, `radiusButtonLargeActive`, `pressScale`, `minTouchTarget`; `LockoutMotion.springFast`.
- Produces: `enum NvButtonVariant { accent, tonal, filled, outlined, text, danger }` and `class NvButton extends StatefulWidget` with `NvButton({Key? key, required NvButtonVariant variant, required String label, IconData? icon, required VoidCallback? onPressed, bool large = false})`. Later tasks add variants to the same enum and the same `_colorsFor` switch.

- [ ] **Step 1: Write the failing test**

Create `test/nv_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_button.dart';

import 'test_helpers.dart';

Widget _host({required NvButtonVariant variant, bool large = false}) {
  return MaterialApp(
    theme: lockoutTestTheme(),
    home: Scaffold(
      body: Center(
        child: NvButton(
          variant: variant,
          label: 'Start session',
          onPressed: () {},
          large: large,
        ),
      ),
    ),
  );
}

double _radiusOf(WidgetTester tester) {
  final container =
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
  return (((container.decoration! as BoxDecoration).borderRadius!)
          as BorderRadius)
      .topLeft
      .x;
}

void main() {
  testWidgets('it is a pill at rest', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 999);
  });

  testWidgets('it morphs to 12dp while pressed', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 12);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 999);
  });

  testWidgets('a large button morphs to 16dp instead', (tester) async {
    await tester.pumpWidget(
        _host(variant: NvButtonVariant.accent, large: true));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 16);
    await gesture.up();
  });

  testWidgets('it is at least 48dp tall', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.tonal));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(NvButton)).height,
        greaterThanOrEqualTo(48));
  });

  testWidgets('reduced motion collapses the morph to an instant change',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: Center(
              child: NvButton(
                variant: NvButtonVariant.accent,
                label: 'Start session',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pump();
    expect(_radiusOf(tester), 12,
        reason: 'with animations off the radius must land immediately');
    await gesture.up();
  });

  testWidgets('a disabled button does not report a press', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Center(
            child: NvButton(
              variant: NvButtonVariant.accent,
              label: 'Start session',
              onPressed: null,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();
    expect(pressed, isFalse);
  });

  testWidgets('it exposes a button semantics node', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Start session')),
      matchesSemantics(label: 'Start session', isButton: true, hasEnabledState: true, isEnabled: true, isFocusable: true, hasTapAction: true),
    );
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_button_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'lockout/widgets/house/nv_button.dart'`.

- [ ] **Step 3: Write the component**

Create `lib/widgets/house/nv_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_semantics.dart';
import '../../theme/lockout_theme.dart';
import '../morphing_surface.dart';

/// The house button variants, section 8 of the design system.
///
/// One filled or accent button per screen; the rest carry secondary and
/// low-emphasis actions. Variants are added as a screen consumes them —
/// a variant nothing presses is not built.
enum NvButtonVariant { accent, tonal, filled, outlined, text, danger }

/// A button whose corner radius is a function of its press state.
///
/// Bespoke rather than a themed `FilledButton` because the press morph has
/// to honour "remove animations", and that setting lives on `MediaQuery` —
/// unreachable from the context-free `ThemeData` the previous approach
/// built the style in. That limitation was deviation D10; this retires it.
class NvButton extends StatefulWidget {
  final NvButtonVariant variant;
  final String label;
  final IconData? icon;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// The hero size: 60dp tall, morphing to 16dp rather than 12dp.
  final bool large;

  const NvButton({
    super.key,
    required this.variant,
    required this.label,
    this.icon,
    required this.onPressed,
    this.large = false,
  });

  @override
  State<NvButton> createState() => _NvButtonState();
}

class _NvButtonState extends State<NvButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  ({Color background, Color foreground, BorderSide side}) _colorsFor(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;
    final semantics = LockoutSemantics.of(context);
    return switch (widget.variant) {
      NvButtonVariant.accent => (
          background: colors.primaryContainer,
          foreground: colors.onPrimaryContainer,
          side: BorderSide.none,
        ),
      NvButtonVariant.filled => (
          background: colors.primary,
          foreground: colors.onPrimary,
          side: BorderSide.none,
        ),
      NvButtonVariant.tonal => (
          background: colors.secondaryContainer,
          foreground: colors.onSecondaryContainer,
          side: BorderSide.none,
        ),
      NvButtonVariant.outlined => (
          background: Colors.transparent,
          foreground: colors.onSurface,
          side: BorderSide(color: colors.outline),
        ),
      NvButtonVariant.text => (
          background: Colors.transparent,
          foreground: colors.primary,
          side: BorderSide.none,
        ),
      NvButtonVariant.danger => (
          background: Colors.transparent,
          foreground: semantics.danger,
          side: BorderSide(color: colors.outlineVariant),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _colorsFor(context);
    final height =
        widget.large ? 60.0 : LockoutTheme.minTouchTarget;
    final foreground =
        _enabled ? palette.foreground : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: MorphingSurface(
          restRadius: LockoutTheme.radiusButtonRest,
          activeRadius: widget.large
              ? LockoutTheme.radiusButtonLargeActive
              : LockoutTheme.radiusButtonActive,
          active: _pressed,
          activeScale: LockoutTheme.pressScale,
          color: _enabled
              ? palette.background
              : theme.colorScheme.surfaceContainerHighest,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.spaceLg,
            ),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(palette.side),
              borderRadius: BorderRadius.circular(
                _pressed
                    ? (widget.large
                        ? LockoutTheme.radiusButtonLargeActive
                        : LockoutTheme.radiusButtonActive)
                    : LockoutTheme.radiusButtonRest,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: foreground),
                  const SizedBox(width: LockoutTheme.spaceSm),
                ],
                Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_button_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Wire the real consumer**

In `lib/screens/today_tab.dart`, replace the two framework buttons inside `_buildPreSession`'s `heroActions` list:

```dart
heroActions: [
  if (!isRest && !isEmptyDay)
    NvButton(
      variant: NvButtonVariant.accent,
      label: 'Start session',
      onPressed: _startScheduledSession,
    ),
  NvButton(
    variant: NvButtonVariant.tonal,
    label: 'Custom session',
    onPressed: _startCustomSession,
  ),
],
```

Add `import '../widgets/house/nv_button.dart';` and delete no other import yet — `HomeHub` is replaced in Task 2.

- [ ] **Step 6: Run the affected suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_button_test.dart test/today_tab_test.dart test/home_tab_test.dart test/home_composition_test.dart`
Expected: PASS. If a Today test matches on `FilledButton`, update that test to `find.widgetWithText(NvButton, 'Start session')` — the button type changed on purpose.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/house/nv_button.dart test/nv_button_test.dart lib/screens/today_tab.dart test/today_tab_test.dart
git commit -m "feat(ui): add NvButton and press it from Today's hero actions"
```

---

### Task 2: NvHeroCard, NvIconTile, NvGroupedList, NvEmptyState, NvTbaCard — Today's pre-session rebuilt

Replaces `HomeHub` entirely. This is the task that removes `'QUICK ACTIONS'` and the uniform-card stack.

**Files:**
- Create: `lib/widgets/house/nv_hero_card.dart`, `lib/widgets/house/nv_icon_tile.dart`, `lib/widgets/house/nv_grouped_list.dart`, `lib/widgets/house/nv_empty_state.dart`, `lib/widgets/house/nv_cards.dart`
- Create: `test/nv_hero_card_test.dart`, `test/nv_grouped_list_test.dart`, `test/nv_icon_tile_test.dart`
- Modify: `lib/screens/today_tab.dart:528-571` (`_buildPreSession` rewritten)
- Modify: `test/home_composition_test.dart`, `test/today_tab_test.dart` as the composition changes

**Interfaces:**
- Consumes: `NvButton` (Task 1), `ConnectedGroup`, `CookieBorder.rest` / `CookieBorder.training`, `LockoutTheme.heroCardShape`, `LockoutSemantics.of(context).categoryRamp`.
- Produces:
  - `NvHeroCard({Key? key, required String title, required String value, required String unit, Widget? marker, double? progress, List<Widget> actions = const []})`
  - `NvIconTile({Key? key, required IconData icon, required Color color, required String label, required VoidCallback onTap})`
  - `NvGroupedList({Key? key, required List<Widget> children})`, `NvListItem({Key? key, Widget? leading, required String title, String? supporting, Widget? trailing, VoidCallback? onTap})`
  - `NvEmptyState({Key? key, required String headline, required String body, required String actionLabel, required VoidCallback onAction})`
  - `NvInfoCard({Key? key, required Widget child})`, `NvTbaCard({Key? key, required String message})`

- [ ] **Step 1: Write the failing hero-card test**

Create `test/nv_hero_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/cookie_border.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/house/nv_hero_card.dart';

import 'test_helpers.dart';

Widget _host({double? progress, Widget? marker}) => MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: NvHeroCard(
          title: 'Push day',
          value: '18',
          unit: 'sets',
          marker: marker,
          progress: progress,
        ),
      ),
    );

void main() {
  testWidgets('it wears the signature asymmetric outline', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(NvHeroCard),
        matching: find.byType(Material),
      ).first,
    );
    expect(material.shape, LockoutTheme.heroCardShape);
  });

  testWidgets('it fills with the accent, not a neutral', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NvHeroCard));
    final colors = Theme.of(context).colorScheme;
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(NvHeroCard),
        matching: find.byType(Material),
      ).first,
    );
    expect(material.color, colors.primaryContainer,
        reason: 'house section 8 gives the hero card an accent fill; a '
            'neutral fill with an accent rail is the old design');
  });

  testWidgets('the big number uses the countdown style', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NvHeroCard));
    final colors = Theme.of(context).colorScheme;
    final value = tester.widget<Text>(find.text('18'));
    expect(value.style?.fontSize,
        LockoutTheme.countdown(colors).fontSize,
        reason: 'the one big number is the house countdown style, not a '
            'display size borrowed from the text theme');
  });

  testWidgets('it shows no progress bar when progress is null',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint).evaluate().isEmpty, isFalse);
  });

  testWidgets('a marker renders inside the card', (tester) async {
    await tester.pumpWidget(
      _host(
        marker: const DecoratedBox(
          decoration: ShapeDecoration(
            shape: CookieBorder.training,
            color: Color(0xFF000000),
          ),
          child: SizedBox(width: 56, height: 56),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DecoratedBox), findsWidgets);
  });
}
```

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_hero_card_test.dart`
Expected: FAIL — package `lockout/widgets/house/nv_hero_card.dart` does not resolve.

- [ ] **Step 3: Write NvHeroCard**

Create `lib/widgets/house/nv_hero_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import 'nv_wavy_progress.dart';

/// The one accent card a screen is allowed, section 8.
///
/// Accent fill, the signature asymmetric outline (36 on three corners, 12
/// bottom-left), 22dp padding, one big number in the countdown style with a
/// unit label. It does not morph: a card has no pressed state.
class NvHeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  /// The subject-scale element — usually a lobed day marker.
  final Widget? marker;

  /// 0..1, or null for a card with nothing in progress.
  final double? progress;

  final List<Widget> actions;

  const NvHeroCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.marker,
    this.progress,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      shape: LockoutTheme.heroCardShape,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: LockoutTheme.spaceSm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: LockoutTheme.countdown(
                              colors,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: LockoutTheme.spaceSm),
                          Text(
                            unit,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (marker != null) marker!,
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: LockoutTheme.spaceMd),
              NvWavyProgress(value: progress!),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: LockoutTheme.spaceMd),
              Wrap(
                spacing: LockoutTheme.spaceSm,
                runSpacing: LockoutTheme.spaceSm,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

`NvHeroCard` imports `NvWavyProgress`, so create `lib/widgets/house/nv_wavy_progress.dart` here using the code in Task 3's Step 3, verbatim. Task 3 adds its tests and its second consumer; this task only needs it to compile and paint.

- [ ] **Step 4: Write the grouped-list test**

Create `test/nv_grouped_list_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_grouped_list.dart';

import 'test_helpers.dart';

Widget _host(int count) => MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: NvGroupedList(
          children: [
            for (var i = 0; i < count; i++)
              NvListItem(
                title: 'Row $i',
                supporting: '3 sets',
                onTap: () {},
              ),
          ],
        ),
      ),
    );

void main() {
  testWidgets('a row is at least 72dp tall', (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(NvListItem).first).height,
        greaterThanOrEqualTo(72));
  });

  testWidgets('a pressed row rounds to 20dp', (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await tester.pumpAndSettle();

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.widgetWithText(NvListItem, 'Row 1'),
        matching: find.byType(AnimatedContainer),
      ).first,
    );
    final radius = (((container.decoration! as BoxDecoration).borderRadius!)
            as BorderRadius)
        .topLeft
        .x;
    expect(radius, 20);
    await gesture.up();
  });

  testWidgets('a single child is large on all four corners', (tester) async {
    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();

    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(NvGroupedList),
        matching: find.byType(ClipRRect),
      ).first,
    );
    final radius = clip.borderRadius as BorderRadius;
    expect(radius.topLeft.x, 26);
    expect(radius.bottomLeft.x, 26);
  });
}
```

- [ ] **Step 5: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_grouped_list_test.dart`
Expected: FAIL — `nv_grouped_list.dart` does not resolve.

- [ ] **Step 6: Write NvGroupedList and NvListItem**

Create `lib/widgets/house/nv_grouped_list.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import '../connected_group.dart';
import '../morphing_surface.dart';

/// A column of rows that reads as one object, section 5.2.
///
/// The corner arithmetic — 26dp outer, 8dp inner, 3dp gaps — already lives
/// in `ConnectedGroup`; this is the house-named entry point so a screen
/// never reaches past the catalog.
class NvGroupedList extends StatelessWidget {
  final List<Widget> children;

  const NvGroupedList({super.key, required this.children});

  @override
  Widget build(BuildContext context) => ConnectedGroup(children: children);
}

/// One row of a grouped list, section 8.
///
/// Minimum 72dp tall, `surfaceContainer` fill, 16dp padding, an optional
/// 40dp leading tile, a title, optional supporting text and an optional
/// trailing badge or control. Pressing it rounds the row to 20dp.
class NvListItem extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? supporting;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NvListItem({
    super.key,
    this.leading,
    required this.title,
    this.supporting,
    this.trailing,
    this.onTap,
  });

  @override
  State<NvListItem> createState() => _NvListItemState();
}

class _NvListItemState extends State<NvListItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: widget.onTap != null,
      label: widget.title,
      child: GestureDetector(
        onTapDown:
            widget.onTap == null ? null : (_) => setState(() => _pressed = true),
        onTapUp:
            widget.onTap == null ? null : (_) => setState(() => _pressed = false),
        onTapCancel:
            widget.onTap == null ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: MorphingSurface(
          restRadius: LockoutTheme.radiusRowRest,
          activeRadius: LockoutTheme.radiusRowActive,
          active: _pressed,
          color: colors.surfaceContainer,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(LockoutTheme.spaceMd),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: LockoutTheme.spaceMd),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleMedium),
                      if (widget.supporting != null) ...[
                        const SizedBox(height: LockoutTheme.spaceXs),
                        Text(
                          widget.supporting!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: LockoutTheme.spaceMd),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Write NvIconTile, NvEmptyState, NvInfoCard and NvTbaCard**

Create `lib/widgets/house/nv_icon_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// The 40dp icon tile from section 8's list spec, used for the Today action
/// grid.
///
/// One consistent squircle across every tile. Lobe count deliberately does
/// not rotate here: colour already carries category, and two signals on one
/// axis read as noise (spec section 5.3).
class NvIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const NvIconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LockoutTheme.spaceSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.surface),
              ),
              const SizedBox(height: LockoutTheme.spaceSm),
              Text(
                label,
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

Create `lib/widgets/house/nv_empty_state.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import 'nv_button.dart';

/// Section 8's empty state: a `surfaceContainer` block with 32dp corners, a
/// short headline, one sentence of guidance and one button that acts.
///
/// Empty is an invitation to act, not a sad face.
class NvEmptyState extends StatelessWidget {
  final String headline;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  const NvEmptyState({
    super.key,
    required this.headline,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LockoutTheme.spaceLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(headline, style: theme.textTheme.headlineMedium),
          const SizedBox(height: LockoutTheme.spaceSm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LockoutTheme.spaceMd),
          NvButton(
            variant: NvButtonVariant.tonal,
            label: actionLabel,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
```

Create `lib/widgets/house/nv_cards.dart`. `NvTbaCard` is consumed in this task's Step 8; `NvInfoCard` is consumed one task later, by Task 4's leg-safety notice. They share a file because they are one idea — a card that is not the hero — and splitting them to satisfy the consumer-pulled rule by the letter would cost a file for nothing. If Task 4 slips, `NvInfoCard` goes with it rather than sitting unused at branch end.

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// Section 8's info card: `surfaceContainer`, 28dp corners, 20dp padding.
class NvInfoCard extends StatelessWidget {
  final Widget child;

  const NvInfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LockoutTheme.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(LockoutTheme.radiusCard),
      ),
      child: child,
    );
  }
}

/// Section 8's TBA card: transparent with a 2dp dashed `outlineVariant`
/// border, for whenever data is not available yet.
///
/// The dashes are painted rather than borrowed from a package — this branch
/// adds no dependency.
class NvTbaCard extends StatelessWidget {
  final String message;

  const NvTbaCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: theme.colorScheme.outlineVariant,
        radius: LockoutTheme.radiusCard,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LockoutTheme.screenPadding),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
```

- [ ] **Step 8: Rewrite `_buildPreSession`**

Replace the whole `HomeHub(...)` call in `lib/screens/today_tab.dart` with a scroll view composed from the catalog. The day marker is the subject-scale element and takes `CookieBorder.rest` on a rest day, `CookieBorder.training` otherwise:

```dart
Widget _buildPreSession(BuildContext context) {
  final theme = Theme.of(context);
  final semantics = LockoutSemantics.of(context);
  final sched = _scheduled;
  final code = ScheduleService.weekdayCode(DateTime.now());
  final isRest = sched == null;
  final isEmptyDay = sched != null && sched.exercises.isEmpty;
  final setCount =
      sched?.exercises.fold<int>(0, (s, e) => s + e.targetSets) ?? 0;

  return SingleChildScrollView(
    padding: const EdgeInsets.only(
      bottom: LockoutTheme.scrollBottomPadding,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LockoutTheme.screenPadding,
            LockoutTheme.screenPadding,
            LockoutTheme.screenPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRest ? 'Rest day' : sched.day.name,
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: LockoutTheme.spaceXs),
              Text(
                'Today · $code',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LockoutTheme.headingGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LockoutTheme.cardPadding,
          ),
          child: NvHeroCard(
            title: isRest ? 'Nothing scheduled' : sched.day.name,
            value: '$setCount',
            unit: setCount == 1 ? 'set' : 'sets',
            marker: DecoratedBox(
              decoration: ShapeDecoration(
                shape: isRest ? CookieBorder.rest : CookieBorder.training,
                color: semantics.categoryAt(isRest ? 7 : 0),
              ),
              child: const SizedBox(width: 56, height: 56),
            ),
            actions: [
              if (!isRest && !isEmptyDay)
                NvButton(
                  variant: NvButtonVariant.accent,
                  label: 'Start session',
                  onPressed: _startScheduledSession,
                ),
              NvButton(
                variant: NvButtonVariant.tonal,
                label: 'Custom session',
                onPressed: _startCustomSession,
              ),
            ],
          ),
        ),
        const SizedBox(height: LockoutTheme.sectionGap),
        if (isRest)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: NvEmptyState(
              headline: 'No session today',
              body: 'Train off-plan or take the day.',
              actionLabel: 'Start a custom session',
              onAction: _startCustomSession,
            ),
          )
        else if (isEmptyDay)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: const NvTbaCard(
              message: 'This training day has no exercises yet. Add them on '
                  'the Routines tab, then come back to start the session.',
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: NvGroupedList(
              children: [
                for (final exercise in sched.exercises)
                  NvListItem(
                    title: exercise.name,
                    supporting: '${exercise.targetSets} sets',
                  ),
              ],
            ),
          ),
        const SizedBox(height: LockoutTheme.sectionGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LockoutTheme.screenPadding,
          ),
          child: Text('Quick actions', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: LockoutTheme.headingGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LockoutTheme.cardPadding,
          ),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final action in _quickActions(context))
                NvIconTile(
                  icon: action.icon,
                  color: action.color,
                  label: action.label,
                  onTap: action.onTap,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

Keep `_quickActions` as it is — it already returns `ActionItem`s with sentence-case labels and ramp colours. Delete the `HomeHub` import from this file. Do **not** delete `lib/widgets/home_hub.dart`: other suites still reference it until Task 11's orphan ledger says otherwise.

- [ ] **Step 9: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_hero_card_test.dart test/nv_grouped_list_test.dart test/today_tab_test.dart test/home_composition_test.dart test/home_tab_test.dart`
Expected: PASS. Tests that assert the old `HomeHub` composition are rewritten to assert the new one — a test asserting the removed widget is updated, never deleted wholesale, and its intent is carried over.

- [ ] **Step 10: Commit**

```bash
git add lib/widgets/house test/nv_hero_card_test.dart test/nv_grouped_list_test.dart lib/screens/today_tab.dart test
git commit -m "feat(ui): rebuild Today's pre-session from the house catalog"
```

---

### Task 3: NvWavyProgress and NvIconButton — Today's active-session header

**Files:**
- Create: `lib/widgets/house/nv_wavy_progress.dart` (if Task 2 did not already), `test/nv_wavy_progress_test.dart`
- Modify: `lib/widgets/house/nv_button.dart` (add `NvIconButton`)
- Modify: `lib/screens/today_tab.dart:712-840` (`_buildSessionHeader`)

**Interfaces:**
- Consumes: `LockoutMotion.effects`, `LockoutTheme.minTouchTarget`.
- Produces: `NvWavyProgress({Key? key, required double value})`; `NvIconButton({Key? key, required IconData icon, required String tooltip, required VoidCallback? onPressed})`.

- [ ] **Step 1: Write the failing test**

Create `test/nv_wavy_progress_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_wavy_progress.dart';

import 'test_helpers.dart';

Widget _host({required double value, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(body: NvWavyProgress(value: value)),
    ),
  );
}

void main() {
  testWidgets('it reports its value to assistive technology',
      (tester) async {
    await tester.pumpWidget(_host(value: 0.5));
    await tester.pump();
    final node = tester.getSemantics(find.byType(NvWavyProgress));
    expect(node.value, '50%');
  });

  testWidgets('the wave drifts', (tester) async {
    await tester.pumpWidget(_host(value: 0.5));
    await tester.pump();
    final first = tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(NvWavyProgress),
          matching: find.byType(CustomPaint),
        ).first)
        .painter!;

    await tester.pump(const Duration(milliseconds: 400));
    final second = tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(NvWavyProgress),
          matching: find.byType(CustomPaint),
        ).first)
        .painter!;

    expect(second.shouldRepaint(first), isTrue,
        reason: 'the wave is the one ambient motion in the app');
  });

  testWidgets('reduced motion stops the wave', (tester) async {
    await tester.pumpWidget(_host(value: 0.5, reduceMotion: true));
    await tester.pump();
    final first = tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(NvWavyProgress),
          matching: find.byType(CustomPaint),
        ).first)
        .painter!;

    await tester.pump(const Duration(milliseconds: 400));
    final second = tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(NvWavyProgress),
          matching: find.byType(CustomPaint),
        ).first)
        .painter!;

    expect(second.shouldRepaint(first), isFalse,
        reason: 'house section 6: reduced motion stops the wave');
  });

  testWidgets('it clamps a value outside 0..1', (tester) async {
    await tester.pumpWidget(_host(value: 1.4));
    await tester.pump();
    expect(tester.getSemantics(find.byType(NvWavyProgress)).value, '100%');
  });
}
```

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_wavy_progress_test.dart`
Expected: FAIL — the widget does not exist, or (if Task 2 wrote a first cut) the drift and reduced-motion tests fail.

- [ ] **Step 3: Write NvWavyProgress**

Create `lib/widgets/house/nv_wavy_progress.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Section 8's wavy linear progress — the only ambient motion in the app.
///
/// The wave drifts on its own; section 6 stops it entirely when the user has
/// asked the OS to remove animations, which is why the ticker is torn down
/// rather than merely slowed.
class NvWavyProgress extends StatefulWidget {
  /// 0..1. Values outside the range are clamped rather than rejected: a
  /// progress bar is not the place to throw.
  final double value;

  const NvWavyProgress({super.key, required this.value});

  @override
  State<NvWavyProgress> createState() => _NvWavyProgressState();
}

class _NvWavyProgressState extends State<NvWavyProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _drift.stop();
      _drift.value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = widget.value.clamp(0.0, 1.0);

    return Semantics(
      value: '${(value * 100).round()}%',
      child: SizedBox(
        height: 12,
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _WavePainter(
              progress: value,
              phase: _drift.value,
              track: colors.surfaceContainerHighest,
              wave: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color track;
  final Color wave;

  const _WavePainter({
    required this.progress,
    required this.phase,
    required this.track,
    required this.wave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;

    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), trackPaint);

    final wavePaint = Paint()
      ..color = wave
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final filled = size.width * progress;
    final path = Path()..moveTo(0, mid);
    for (var x = 0.0; x <= filled; x += 1) {
      final y = mid +
          math.sin((x / 16) + (phase * 2 * math.pi)) * (size.height / 3);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.track != track ||
      old.wave != wave;
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_wavy_progress_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Add NvIconButton**

Append to `lib/widgets/house/nv_button.dart`:

```dart
/// Section 8's icon button: a 48dp pill that rounds to 14dp while pressed.
///
/// A content description is required, not optional — section 9 says an
/// icon-only button always carries one.
class NvIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const NvIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<NvIconButton> createState() => _NvIconButtonState();
}

class _NvIconButtonState extends State<NvIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: MorphingSurface(
            restRadius: LockoutTheme.radiusButtonRest,
            activeRadius: 14,
            active: _pressed,
            color: colors.surfaceContainerHigh,
            child: SizedBox(
              width: LockoutTheme.minTouchTarget,
              height: LockoutTheme.minTouchTarget,
              child: Icon(
                widget.icon,
                size: 24,
                color: enabled ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Add two tests to `test/nv_button_test.dart` mirroring the NvButton ones: the icon button is 48 × 48, and it rounds to 14dp while pressed.

- [ ] **Step 6: Wire both into the session header**

In `_buildSessionHeader`, replace the existing progress indicator with `NvWavyProgress(value: exerciseProgress)` and the header's icon affordances with `NvIconButton`. Keep the header's existing text content and semantics labels.

- [ ] **Step 7: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_wavy_progress_test.dart test/nv_button_test.dart test/today_tab_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/house test/nv_wavy_progress_test.dart test/nv_button_test.dart lib/screens/today_tab.dart
git commit -m "feat(ui): give the active session a wavy progress bar and house icon buttons"
```

---

### Task 4: NvStatusBadge and NvTextField — the set rows and the number stepper

**Files:**
- Create: `lib/widgets/house/nv_status_badge.dart`, `lib/widgets/house/nv_text_field.dart`
- Create: `test/nv_status_badge_test.dart`, `test/nv_text_field_test.dart`
- Modify: `lib/screens/today_tab.dart:865-1131` (`_buildExerciseCard`, `_buildSetRow`, `_numberStepper`)

**Interfaces:**
- Consumes: `NvGroupedList`, `NvListItem`, `NvIconButton`, `LockoutSemantics.of(context).success` / `.onSuccess` / `.warning`, `LockoutTheme.radiusField`.
- Produces: `enum NvBadgeKind { accent, done, unknown, neutral }`; `NvStatusBadge({Key? key, required String label, required NvBadgeKind kind})`; `NvTextField({Key? key, required String label, required TextEditingController controller, TextInputType? keyboardType, String? errorText, ValueChanged<String>? onChanged})`.

- [ ] **Step 1: Write the failing badge test**

Create `test/nv_status_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/widgets/house/nv_status_badge.dart';

import 'test_helpers.dart';

Widget _host(NvBadgeKind kind) => MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: Center(child: NvStatusBadge(label: 'Done', kind: kind)),
      ),
    );

Color _fillOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(NvStatusBadge),
      matching: find.byType(Container),
    ).first,
  );
  return ((container.decoration! as BoxDecoration).color)!;
}

void main() {
  testWidgets('a done badge uses the success role', (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.done));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NvStatusBadge));
    expect(_fillOf(tester), LockoutSemantics.of(context).success);
  });

  testWidgets('an accent badge uses the accent, not a neutral',
      (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.accent));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NvStatusBadge));
    expect(_fillOf(tester), Theme.of(context).colorScheme.primaryContainer);
  });

  testWidgets('an unknown badge is transparent with a dashed border',
      (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.unknown));
    await tester.pumpAndSettle();
    expect(_fillOf(tester), const Color(0x00000000));
  });

  testWidgets('every kind resolves a colour from the theme', (tester) async {
    for (final kind in NvBadgeKind.values) {
      await tester.pumpWidget(_host(kind));
      await tester.pumpAndSettle();
      expect(_fillOf(tester), isA<Color>());
    }
  });
}
```

House §8 names a `successContainer` fill for a done badge. `LockoutSemantics` carries `success` and `onSuccess` and no container pair, and the token layer is out of scope on this branch — so the done badge fills with `success` and inks with `onSuccess`. Record that mapping in a comment on the component; it is a faithful read of the role Lockout actually has, not a new deviation.

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_status_badge_test.dart`
Expected: FAIL — `nv_status_badge.dart` does not resolve.

- [ ] **Step 3: Write NvStatusBadge**

Create `lib/widgets/house/nv_status_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_semantics.dart';
import '../../theme/lockout_theme.dart';

/// The four status badges section 8 puts on the right of a list row.
enum NvBadgeKind {
  /// Imminent or in progress.
  accent,

  /// Finished.
  done,

  /// Not known yet.
  unknown,

  /// Everything else.
  neutral,
}

class NvStatusBadge extends StatelessWidget {
  final String label;
  final NvBadgeKind kind;

  const NvStatusBadge({super.key, required this.label, required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantics = LockoutSemantics.of(context);

    final (Color fill, Color ink, BoxBorder? border) = switch (kind) {
      NvBadgeKind.accent => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
          null,
        ),
      // House section 8 names `successContainer` here. Lockout's semantics
      // extension carries `success`/`onSuccess` and no container pair, and
      // the token layer is out of scope on this branch, so the pair it has
      // stands in. Same role, one shade stronger.
      NvBadgeKind.done => (
          semantics.success,
          semantics.onSuccess,
          null,
        ),
      NvBadgeKind.unknown => (
          const Color(0x00000000),
          colors.onSurfaceVariant,
          Border.all(color: colors.outline, width: 1.5),
        ),
      NvBadgeKind.neutral => (
          colors.surfaceContainerHigh,
          colors.onSurfaceVariant,
          null,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LockoutTheme.spaceSm,
        vertical: LockoutTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: BorderRadius.circular(LockoutTheme.radiusChipRest),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: ink)),
    );
  }
}
```

- [ ] **Step 4: Write the failing field test**

Create `test/nv_text_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_text_field.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('the label sits above the field, not inside it',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Reps', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelY = tester.getTopLeft(find.text('Reps')).dy;
    final fieldY = tester.getTopLeft(find.byType(TextField)).dy;
    expect(labelY, lessThan(fieldY));
  });

  testWidgets('it is 56dp tall', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Reps', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextField)).height, 56);
  });

  testWidgets('an error renders below the field', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(
            label: 'Reps',
            controller: controller,
            errorText: 'Enter a number',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Enter a number')).dy,
      greaterThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });
}
```

- [ ] **Step 5: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_text_field_test.dart`
Expected: FAIL — `nv_text_field.dart` does not resolve.

- [ ] **Step 6: Write NvTextField**

Create `lib/widgets/house/nv_text_field.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// Section 8's text field: outlined, 56dp tall, 16dp corners, the label
/// above the field rather than floating inside it, error text below.
class NvTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const NvTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
      borderSide: BorderSide(color: colors.outline),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: LockoutTheme.spaceXs),
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LockoutTheme.spaceMd,
              ),
              enabledBorder: border,
              border: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: LockoutTheme.spaceXs),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 7: Rebuild the set rows and the stepper**

In `lib/screens/today_tab.dart`:
- `_buildExerciseCard` wraps its set rows in `NvGroupedList` instead of a card.
- `_buildSetRow` renders the set state through `NvStatusBadge` — `NvBadgeKind.done` for a completed set, `NvBadgeKind.accent` for the live one, `NvBadgeKind.neutral` otherwise — and keeps the `numericTable` text style on the numerals (deviation D1).
- `_numberStepper` uses `NvIconButton` for its minus and plus affordances and `NvTextField` for the value, keeping the existing `numeric_guard` validation path untouched.
- `_buildLegSafetyNotice` becomes an `NvInfoCard` — `surfaceContainer`, 28dp corners, 20dp padding — with its advisory text inked in `LockoutSemantics.of(context).warning`. This is `NvInfoCard`'s first consumer; it was created in Task 2 alongside `NvTbaCard` and must not reach the end of that task unused.

- [ ] **Step 8: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_status_badge_test.dart test/nv_text_field_test.dart test/today_tab_test.dart test/numeric_guard_test.dart`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/widgets/house test/nv_status_badge_test.dart test/nv_text_field_test.dart lib/screens/today_tab.dart
git commit -m "feat(ui): rebuild the set rows and the number stepper from the catalog"
```

---

### Task 5: NvBottomSheet and NvSnackbar — Today's overlays

**Files:**
- Create: `lib/widgets/house/nv_sheet.dart`, `test/nv_sheet_test.dart`
- Modify: `lib/screens/today_tab.dart:1216-1268` (`_FinishSummarySheet` and its presentation), plus the set-logged confirmation

**Interfaces:**
- Consumes: `LockoutTheme.radiusSheet`, `LockoutMotion.springDefault`.
- Produces: `Future<T?> showNvSheet<T>({required BuildContext context, required Widget child})`; `void showNvSnackbar({required BuildContext context, required String message})`.

- [ ] **Step 1: Write the failing test**

Create `test/nv_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_sheet.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('the sheet has 32dp top corners and a drag handle',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showNvSheet<void>(
                context: context,
                child: const Text('Session saved'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Session saved'), findsOneWidget);

    final material = tester.widget<Material>(
      find.ancestor(
        of: find.text('Session saved'),
        matching: find.byType(Material),
      ).last,
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect((shape.borderRadius as BorderRadius).topLeft.x, 32);
  });

  testWidgets('a snackbar repeats the action name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showNvSnackbar(context: context, message: 'Set logged'),
              child: const Text('log'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('log'));
    await tester.pump();
    expect(find.text('Set logged'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Set logged'), findsNothing,
        reason: 'section 8 auto-dismisses a snackbar after 3 seconds');
  });
}
```

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_sheet_test.dart`
Expected: FAIL — `nv_sheet.dart` does not resolve.

- [ ] **Step 3: Write the overlays**

Create `lib/widgets/house/nv_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// Section 8's bottom sheet: `surfaceContainer`, 32dp top corners, a drag
/// handle, 24dp side padding. Preferred over a dialog for choices,
/// confirmations and short forms.
Future<T?> showNvSheet<T>({
  required BuildContext context,
  required Widget child,
}) {
  final colors = Theme.of(context).colorScheme;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: colors.surfaceContainer,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(LockoutTheme.radiusSheet),
      ),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        LockoutTheme.spaceLg,
        0,
        LockoutTheme.spaceLg,
        LockoutTheme.spaceLg,
      ),
      child: child,
    ),
  );
}

/// Section 8's snackbar: `onSurface` background, `surface` text, 16dp
/// corners, above the nav bar, gone after three seconds. The message repeats
/// the action's name.
void showNvSnackbar({
  required BuildContext context,
  required String message,
}) {
  final theme = Theme.of(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.surface,
        ),
      ),
      backgroundColor: theme.colorScheme.onSurface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
      ),
    ),
  );
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_sheet_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Wire the consumers**

Present `_FinishSummarySheet` through `showNvSheet`, and replace the session-saved confirmation with `showNvSnackbar(context: context, message: 'Session saved')`. The previous copy was `'SESSION SAVED - ...'`; the replacement is sentence case, and it names the action.

- [ ] **Step 6: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_sheet_test.dart test/today_tab_test.dart test/expressive_contract_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/house/nv_sheet.dart test/nv_sheet_test.dart lib/screens/today_tab.dart
git commit -m "feat(ui): present Today's summary and confirmations as house overlays"
```

---

### Task 6: Contract guard — Today's rebuild asserted

**Files:**
- Modify: `test/expressive_contract_test.dart`

**Interfaces:**
- Consumes: `_branchOneFiles`, `_dartFilesIn`, `_withoutComments` (all already in the file).
- Produces: a renamed `_rebuiltFiles` list that later tasks append to, plus three new guards.

- [ ] **Step 1: Write the new guards, and prove each fails first**

Add to `test/expressive_contract_test.dart`:

```dart
/// The files this branch rebuilds from the house catalog.
///
/// Guards scoped to this list widen as screens land. They never weaken: a
/// guard that stops asserting something is a regression, not a scope change.
const List<String> _rebuiltFiles = [
  ..._branchOneFiles,
  'lib/screens/today_tab.dart',
];

group('the house catalog', () {
  test('every catalog component resolves colour through the theme', () {
    for (final file in _dartFilesIn('lib/widgets/house')) {
      final source = _withoutComments(file.readAsStringSync());
      expect(RegExp(r'Color\(0x').hasMatch(source), isFalse,
          reason: '${file.path} hard-codes a colour; colour resolves through '
              'Theme.of(context) or LockoutSemantics.of(context)');
      expect(source.contains('JinatraTokens'), isFalse,
          reason: '${file.path} reaches for the retired token class');
    }
  });

  test('a rebuilt screen composes from the catalog, not the old widgets',
      () {
    // The failure this branch exists to prevent: a screen that imports a
    // widget written for the previous design keeps that design's decisions
    // in places no token can reach.
    const forbidden = [
      'home_hub.dart',
      'lockout_card.dart',
      'hero_card.dart',
      'calm_row.dart',
      'action_grid.dart',
      'stat_tile.dart',
      'today_day_card.dart',
    ];

    for (final path in ['lib/screens/today_tab.dart']) {
      final source = _withoutComments(File(path).readAsStringSync());
      for (final widget in forbidden) {
        expect(source.contains(widget), isFalse,
            reason: '$path still imports $widget, a pre-rebuild widget');
      }
    }
  });

  test('every catalog component with a press state declares both radii', () {
    // A single fixed radius on an interactive surface is a contract
    // violation. Each interactive component routes its press through
    // MorphingSurface, which takes a rest and an active radius by
    // construction — asserting the route is what makes the rule reachable.
    const interactive = [
      'lib/widgets/house/nv_button.dart',
      'lib/widgets/house/nv_grouped_list.dart',
    ];

    for (final path in interactive) {
      final source = _withoutComments(File(path).readAsStringSync());
      expect(source.contains('MorphingSurface('), isTrue,
          reason: '$path has a press state but does not morph');
      expect(source.contains('restRadius:'), isTrue);
      expect(source.contains('activeRadius:'), isTrue);
    }
  });
});
```

Prove each new guard fails against the pre-rebuild code before accepting it: `git stash` the screen rewrite, run the guard, confirm the failure names the real cause, then `git stash pop`. A guard that is green the first time it runs has asserted nothing.

- [ ] **Step 2: Widen the case rule to the rebuilt files**

Change the all-caps loop's `for (final path in _branchOneFiles)` to `for (final path in _rebuiltFiles)`.

- [ ] **Step 3: Run the contract suite**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/expressive_contract_test.dart`
Expected: PASS. Any failure here is a real finding against Tasks 1–5, not a reason to weaken the guard.

- [ ] **Step 4: Run the full suite**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1`
Expected: PASS, at least 695 tests.

- [ ] **Step 5: Commit**

```bash
git add test/expressive_contract_test.dart
git commit -m "test(ui): assert Today's rebuild against the house catalog"
```

---

### GATE: device QA on Today

**This is a hard gate, not a task. No Profile/Settings task is dispatched until it passes.**

- [ ] Build the release APK: `C:\src\flutter\bin\flutter.bat build apk --release`
- [ ] Start the emulator `lockout_qa` (Android 16 / API 36, 1080 × 2400, density 420) and install the APK.
- [ ] Walk every Today state: rest day, training day, training day with no exercises, an active session with a live set, the rest timer, the finish summary sheet.
- [ ] Screenshot each state to `docs/spine/qa/2026-10-07/` — **not** the scratchpad. The previous pass lost its screenshots with the session.
- [ ] Check reduced motion: enable "Remove animations" in developer options, confirm the press morphs land instantly and the wave stops.
- [ ] Record the verdict in `.spine/progress.md`: what was looked at, what was found, pass or fail.
- [ ] A finding here is a defect on this branch and is fixed before the gate reopens — the two defects the last pass found were both invisible to 695 green tests.

---

### Task 7: NvSegmentedButton and NvSwitchRow — Profile's header and "Look and feel"

Retires deviation D9: the segment shapes section 5.2 asks for are unreachable through a Flutter theme, so the control is bespoke.

**Files:**
- Create: `lib/widgets/house/nv_segmented_button.dart`, `lib/widgets/house/nv_switch.dart`
- Create: `test/nv_segmented_button_test.dart`
- Modify: `lib/screens/settings_screen.dart:587-643` (`_buildAppearanceCard`), and the screen's header

**Interfaces:**
- Consumes: `LockoutTheme.radiusSegmentInner` (8), `radiusSegmentEnd` (22), `radiusChipActive` (999), `LockoutMotion.springFast`, `CookieBorder` (12 lobes for the profile avatar, house §5.3).
- Produces: `class NvSegment<T> { final T value; final String label; const NvSegment({required this.value, required this.label}); }`; `NvSegmentedButton<T>({Key? key, required List<NvSegment<T>> segments, required T selected, required ValueChanged<T> onChanged})`; `NvSwitchRow({Key? key, required String title, String? supporting, required bool value, required ValueChanged<bool> onChanged})`.

- [ ] **Step 1: Write the failing test**

Create `test/nv_segmented_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_segmented_button.dart';

import 'test_helpers.dart';

Widget _host({required String selected, required ValueChanged<String> onChanged}) {
  return MaterialApp(
    theme: lockoutTestTheme(),
    home: Scaffold(
      body: NvSegmentedButton<String>(
        segments: const [
          NvSegment(value: 'light', label: 'Light'),
          NvSegment(value: 'dark', label: 'Dark'),
          NvSegment(value: 'system', label: 'System'),
        ],
        selected: selected,
        onChanged: onChanged,
      ),
    ),
  );
}

double _radiusOf(WidgetTester tester, String label, {required bool leading}) {
  final container = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    ).first,
  );
  final radius =
      ((container.decoration! as BoxDecoration).borderRadius!) as BorderRadius;
  return leading ? radius.topLeft.x : radius.topRight.x;
}

void main() {
  testWidgets('the outer ends are 22dp', (tester) async {
    await tester.pumpWidget(_host(selected: 'dark', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester, 'Light', leading: true), 22);
    expect(_radiusOf(tester, 'System', leading: false), 22);
  });

  testWidgets('an unselected inner segment is 8dp', (tester) async {
    await tester.pumpWidget(_host(selected: 'light', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester, 'Dark', leading: true), 8);
  });

  testWidgets('the selected segment becomes a full pill', (tester) async {
    await tester.pumpWidget(_host(selected: 'dark', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester, 'Dark', leading: true), 999);
  });

  testWidgets('tapping a segment reports its value', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      _host(selected: 'dark', onChanged: (value) => chosen = value),
    );
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(chosen, 'system');
  });

  testWidgets('each segment is a selectable semantics node', (tester) async {
    await tester.pumpWidget(_host(selected: 'dark', onChanged: (_) {}));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.text('Dark'));
    expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
  });
}
```

Add `import 'package:flutter/semantics.dart';` to the test if `SemanticsFlag` does not resolve.

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_segmented_button_test.dart`
Expected: FAIL — `nv_segmented_button.dart` does not resolve.

- [ ] **Step 3: Write NvSegmentedButton**

Create `lib/widgets/house/nv_segmented_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_motion.dart';
import '../../theme/lockout_theme.dart';

/// One option in an [NvSegmentedButton].
@immutable
class NvSegment<T> {
  final T value;
  final String label;

  const NvSegment({required this.value, required this.label});
}

/// Section 5.2's segmented control: inner segments 8dp, outer ends 22dp, the
/// selected segment a full pill.
///
/// Bespoke rather than a themed `SegmentedButton`, which hardcodes each
/// segment's shape in `segmentStyleFor` and resolves the group style with
/// `selected` permanently set — so none of the three shapes is reachable
/// from a theme. That was deviation D9; this retires it.
class NvSegmentedButton<T> extends StatelessWidget {
  final List<NvSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const NvSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tier = LockoutMotion.springFast;
    final duration = tier.durationFor(context);

    return Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: segments[i].value == selected,
              label: segments[i].label,
              child: GestureDetector(
                onTap: () => onChanged(segments[i].value),
                child: AnimatedContainer(
                  duration: duration,
                  curve: tier.curve,
                  height: LockoutTheme.minTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: segments[i].value == selected
                        ? colors.secondaryContainer
                        : colors.surfaceContainer,
                    borderRadius: _radiusFor(i),
                  ),
                  child: Text(
                    segments[i].label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: segments[i].value == selected
                          ? colors.onSecondaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i != segments.length - 1)
            const SizedBox(width: LockoutTheme.groupGap),
        ],
      ],
    );
  }

  /// A selected segment is a pill on every corner. Otherwise the group's two
  /// ends carry 22dp on their outer side and 8dp inside, and everything
  /// between them is 8dp all round.
  BorderRadius _radiusFor(int index) {
    if (segments[index].value == selected) {
      return BorderRadius.circular(LockoutTheme.radiusChipActive);
    }

    const end = Radius.circular(LockoutTheme.radiusSegmentEnd);
    const inner = Radius.circular(LockoutTheme.radiusSegmentInner);
    final first = index == 0;
    final last = index == segments.length - 1;

    return BorderRadius.only(
      topLeft: first ? end : inner,
      bottomLeft: first ? end : inner,
      topRight: last ? end : inner,
      bottomRight: last ? end : inner,
    );
  }
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_segmented_button_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Write NvSwitchRow**

Create `lib/widgets/house/nv_switch.dart`:

```dart
import 'package:flutter/material.dart';

import 'nv_grouped_list.dart';

/// A grouped-list row whose trailing control is a switch, section 8.
///
/// The switch is the standard Material one — section 8 asks for exactly
/// that, and its thumb already grows when on.
class NvSwitchRow extends StatelessWidget {
  final String title;
  final String? supporting;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NvSwitchRow({
    super.key,
    required this.title,
    this.supporting,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NvListItem(
      title: title,
      supporting: supporting,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
```

- [ ] **Step 6: Rebuild the header and "Look and feel"**

In `lib/screens/settings_screen.dart`:
- Add the §12.2 header: a 12-lobe `CookieBorder` avatar carrying the app symbol, and the app name. No name, no email, no Pro badge — there is no account and no Pro tier (deviation D2).
- Replace `_buildAppearanceCard`'s brightness control with `NvSegmentedButton<ThemeMode>`, wired to `ThemeController.instance` exactly as the existing control is.
- Keep the five accent swatches, each still morphing 18 → 26dp on selection.

Do not touch `ThemeController`.

- [ ] **Step 7: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_segmented_button_test.dart test/settings_restyle_test.dart test/theme_picker_test.dart test/profile_tab_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/house test/nv_segmented_button_test.dart lib/screens/settings_screen.dart
git commit -m "feat(ui): give settings a bespoke segmented control and a house header"
```

---

### Task 8: Settings sections as grouped lists

**Files:**
- Modify: `lib/screens/settings_screen.dart:644-1005` (`_buildUnitsCard`, `_buildTrainingCard`, `_buildFoodCard`, `_buildNotificationsCard`), `_sectionCaption`
- Modify: `test/settings_restyle_test.dart`

**Interfaces:**
- Consumes: `NvGroupedList`, `NvListItem`, `NvSwitchRow`, `NvSegmentedButton`, `showNvSheet`.
- Produces: nothing new. This task only replaces composition.

- [ ] **Step 1: Write the failing test**

Add to `test/settings_restyle_test.dart`:

```dart
testWidgets('every settings section is a grouped list, not a card',
    (tester) async {
  await tester.pumpWidget(hostedProfileTab());
  await settle(tester);

  expect(find.byType(NvGroupedList), findsWidgets);
  expect(find.byType(LockoutCard), findsNothing,
      reason: 'grouped lists replace the stack of uniform cards');
});

testWidgets('a section caption is sentence case', (tester) async {
  await tester.pumpWidget(hostedProfileTab());
  await settle(tester);

  expect(find.text('Look and feel'), findsOneWidget);
  expect(find.text('LOOK AND FEEL'), findsNothing);
});
```

Import `NvGroupedList` and whatever card class the file currently uses.

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/settings_restyle_test.dart`
Expected: FAIL — the cards are still there.

- [ ] **Step 3: Give every section the same frame**

These sections are forms, not pure lists — Units ends in a "Save height" button, Food calculates a target. So the grouped list replaces the `LockoutCard` wrapper and holds the rows that *are* rows; fields and the section's save button sit below the group, inside the same section frame:

```dart
Widget _section(
  BuildContext context, {
  required String heading,
  required List<Widget> rows,
  List<Widget> extras = const [],
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LockoutTheme.screenPadding,
        ),
        child: Text(heading, style: Theme.of(context).textTheme.titleMedium),
      ),
      const SizedBox(height: LockoutTheme.headingGap),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LockoutTheme.cardPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rows.isNotEmpty) NvGroupedList(children: rows),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: LockoutTheme.spaceMd),
              ...extras,
            ],
          ],
        ),
      ),
      const SizedBox(height: LockoutTheme.sectionGap),
    ],
  );
}
```

`_sectionCaption` is replaced by this `heading`, in sentence case, with no uppercase styling.

- [ ] **Step 4: Convert the four sections, one at a time**

**Units** — `rows`: none. `extras`: `NvSegmentedButton<String>` for centimetres / feet-and-inches, the height `NvTextField`s (one for cm, two for ft/in), and a `NvButton(variant: NvButtonVariant.filled, label: 'Save height')`. The existing `_switchHeightUnit` and `_saveHeightSettings` handlers are unchanged.

**Training** — `rows`: one `NvListItem` for "Days per week" with the current count as supporting text, opening a `showNvSheet` stepper; one `NvListItem` per activity level, with the multiplier (`x1.2`) as its trailing text and the blurb as supporting text, selected state shown by `NvStatusBadge(label: 'Selected', kind: NvBadgeKind.accent)`. `extras`: none. This replaces the `RadioListTile` group — a grouped list with a badge is the house pattern for a single choice among several.

**Food** — `rows`: `NvSwitchRow(title: 'Enable nutrition tab', ...)`. `extras`: the age, target-weight and timeframe `NvTextField`s, the `NvSegmentedButton<Sex>`, `NvButton(variant: NvButtonVariant.filled, label: 'Calculate my target')`, the resulting plan summary (keep its existing `Chip` content but render the direction label through `NvStatusBadge`), the daily-calorie-target `NvTextField`, and `NvButton(variant: NvButtonVariant.filled, label: 'Save food settings')`.

**Notifications** — `rows`: `NvSwitchRow(title: 'Daily training nudge', ...)`, `NvListItem(title: 'Reminder time', supporting: <the current time>, onTap: <the existing picker>)`, `NvSwitchRow(title: 'Streak warning at 21:00', ...)`. `extras`: `NvButton(variant: NvButtonVariant.tonal, label: 'Send test notification')`.

Every setting that opens a choice presents it through `showNvSheet` rather than a dialog — §8 prefers a sheet for choices and reserves dialogs for destructive confirmations. One filled button per section is the limit; a section that would need two keeps the primary one filled and makes the other tonal.

- [ ] **Step 5: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/settings_restyle_test.dart test/profile_tab_test.dart test/theme_controller_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/settings_screen.dart test/settings_restyle_test.dart
git commit -m "feat(ui): rebuild the settings sections as grouped lists"
```

---

### Task 9: NvDialog and the data section

Brings the `outlined`, `text` and `danger` button variants into existence — each with a real consumer in this task's dialog and data rows.

**Files:**
- Create: `lib/widgets/house/nv_dialog.dart`, `test/nv_dialog_test.dart`
- Modify: `lib/widgets/house/nv_button.dart` (no code change if Task 1's switch already covers all six variants — confirm the three new variants are actually reachable)
- Modify: `lib/screens/settings_screen.dart:1006-1052` (`_buildDataCard`)

**Interfaces:**
- Consumes: `NvButton` with `NvButtonVariant.outlined`, `.text` and `.danger`; `LockoutTheme.radiusDialog`; `LockoutSemantics.of(context).danger`.
- Produces: `Future<bool> showNvDestructiveDialog({required BuildContext context, required String title, required String body, required String confirmLabel})` — resolves `true` only on confirm.

- [ ] **Step 1: Write the failing test**

Create `test/nv_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_dialog.dart';

import 'test_helpers.dart';

Future<bool?> _open(WidgetTester tester) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showNvDestructiveDialog(
                context: context,
                title: 'Clear all data?',
                body: 'Every logged session and weigh-in is removed. This '
                    'cannot be undone.',
                confirmLabel: 'Clear data',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('it has 32dp corners', (tester) async {
    await _open(tester);
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final shape = dialog.shape! as RoundedRectangleBorder;
    expect((shape.borderRadius as BorderRadius).topLeft.x, 32);
  });

  testWidgets('cancelling resolves false', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('confirming names the action it performs', (tester) async {
    await _open(tester);
    expect(find.text('Clear data'), findsOneWidget,
        reason: 'the confirm label is a verb that says what happens');
  });
}
```

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_dialog_test.dart`
Expected: FAIL — `nv_dialog.dart` does not resolve.

- [ ] **Step 3: Write the dialog**

Create `lib/widgets/house/nv_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import 'nv_button.dart';

/// Section 8 allows a dialog for one thing only: a destructive
/// confirmation. Everything else that needs a choice is a bottom sheet.
///
/// Resolves `true` only when the user confirms; a dismissal resolves
/// `false`, never null, so a caller cannot treat "dismissed" as "confirmed"
/// by forgetting a null check.
Future<bool> showNvDestructiveDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final theme = Theme.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LockoutTheme.radiusDialog),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LockoutTheme.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: LockoutTheme.spaceSm),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: LockoutTheme.spaceLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NvButton(
                  variant: NvButtonVariant.text,
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: LockoutTheme.spaceSm),
                NvButton(
                  variant: NvButtonVariant.danger,
                  label: confirmLabel,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return confirmed ?? false;
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_dialog_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Rebuild the data section**

`_buildDataCard` becomes an `NvGroupedList` with one row per action — export, import, clear — and every destructive action routes through `showNvDestructiveDialog`. Export and import keep their existing `BackupService` calls untouched.

- [ ] **Step 6: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/nv_dialog_test.dart test/settings_restyle_test.dart test/backup_roundtrip_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/house/nv_dialog.dart test/nv_dialog_test.dart lib/screens/settings_screen.dart
git commit -m "feat(ui): confirm destructive data actions through a house dialog"
```

---

### Task 10: About screen

**Files:**
- Create: `lib/screens/about_screen.dart`, `test/about_screen_test.dart`
- Modify: `lib/screens/settings_screen.dart:1053-1079` (`_buildAboutCard` becomes a row that pushes the screen)

**Interfaces:**
- Consumes: `NvGroupedList`, `NvListItem`, `NvInfoCard`.
- Produces: `class AboutScreen extends StatelessWidget` with a const constructor.

- [ ] **Step 1: Write the failing test**

Create `test/about_screen_test.dart`:

```dart
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

    expect(find.textContaining('Made by Nuvetrix'), findsOneWidget);
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
}
```

- [ ] **Step 2: Run it and verify it fails**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/about_screen_test.dart`
Expected: FAIL — `about_screen.dart` does not resolve.

- [ ] **Step 3: Write the screen**

Create `lib/screens/about_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/lockout_theme.dart';
import '../widgets/house/nv_cards.dart';

/// Section 12.3's About screen.
///
/// The house text asks for links to the privacy policy and terms on the
/// Nuvetrix website. Lockout renders them as text instead: the app is
/// zero-network at runtime, and a link that cannot open is worse than a line
/// that says where to look.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Kept in step with `pubspec.yaml` by `about_screen_test.dart`.
  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(LockoutTheme.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lockout', style: theme.textTheme.displaySmall),
            const SizedBox(height: LockoutTheme.spaceSm),
            Text('Made by Nuvetrix · version $version',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: LockoutTheme.sectionGap),
            const NvInfoCard(
              child: Text(
                'Licensed under the GPL, version 3 or later. Everything you '
                'log stays on this phone: the app makes no network requests '
                'and has no account. The privacy policy and terms are on the '
                'Nuvetrix website.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Add a test asserting `AboutScreen.version` matches the `version:` line in `pubspec.yaml`, so the two cannot drift.

- [ ] **Step 4: Run the test and verify it passes**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/about_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Push it from settings**

`_buildAboutCard` becomes one `NvListItem` in the account group: title "About", trailing chevron, pushing `AboutScreen`.

- [ ] **Step 6: Run the suites**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1 test/about_screen_test.dart test/settings_restyle_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/about_screen.dart test/about_screen_test.dart lib/screens/settings_screen.dart
git commit -m "feat(ui): add the About screen"
```

---

### Task 11: Guard the Profile rebuild, record the orphan ledger, close the branch

**Files:**
- Modify: `test/expressive_contract_test.dart`
- Create: `docs/spine/orphaned-widgets.md`
- Modify: `docs/spine/specs/2026-10-07-house-rebuild-design.md` (record which catalog variants went unbuilt)

**Interfaces:**
- Consumes: `_rebuiltFiles` from Task 6.
- Produces: nothing new.

- [ ] **Step 1: Widen the guards**

Add `'lib/screens/settings_screen.dart'` and `'lib/screens/about_screen.dart'` to `_rebuiltFiles`, and add both to the forbidden-import loop's path list. Run the contract suite and confirm each new entry fails before the screens are clean — if adding a path turns nothing red, the path was already clean and the guard proves nothing new; say so rather than claiming coverage.

- [ ] **Step 2: Write the orphan ledger**

Create `docs/spine/orphaned-widgets.md` listing every widget under `lib/widgets/` that no rebuilt screen reaches, with its remaining consumers. Produce the list mechanically:

```bash
for f in lib/widgets/*.dart; do
  name=$(basename "$f" .dart)
  echo "$name: $(grep -rl "$name" lib --include=*.dart | grep -v "$f" | tr '\n' ' ')"
done
```

A widget whose only remaining consumers are the five out-of-scope screens is deleted on the branch that rebuilds them, not here.

- [ ] **Step 3: Record the unbuilt catalog variants**

In the spec's §5.2, append the variants that reached branch end without a consumer. Filter chips, the search field and the loading indicator are already recorded; add any `NvButton` variant nothing pressed.

- [ ] **Step 4: Run the full suite**

Run: `C:\src\flutter\bin\flutter.bat test --concurrency=1`
Expected: PASS, at least 695 tests.

- [ ] **Step 5: Run the analyzer**

Run: `C:\src\flutter\bin\flutter.bat analyze`
Expected: clean apart from the 3 pre-existing infos.

- [ ] **Step 6: Second device QA pass**

Repeat the GATE procedure above across Today, Profile/Settings and About. Screenshots to `docs/spine/qa/2026-10-07/`. Record the verdict in `.spine/progress.md`.

- [ ] **Step 7: Commit**

```bash
git add test/expressive_contract_test.dart docs/spine/orphaned-widgets.md docs/spine/specs/2026-10-07-house-rebuild-design.md
git commit -m "test(ui): guard the Profile rebuild and record the orphan ledger"
```

---

## After the last task

REVIEW (`requesting-code-review`) runs against the whole branch — and because this branch stacks on `expressive-restyle-branch-1`, the review range spans both. FINISH (`finishing-a-branch`) comes after the review's findings are closed and the Gate D receipt matches the branch tip.
