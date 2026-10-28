# Expressive foundation — branch 2

Status: approved 2026-10-28. Branch: `house-rebuild-branch-2`, cut from `master` at `7fcce7f`.
It supersedes the Workout design that was briefly branch 2, which is now
`docs/spine/specs/2026-10-28-house-rebuild-branch-3-workout-design.md`.

Governing documents:

- **Material 3 Expressive** is the visual target from this branch on.
- **The Nuvetrix house system** (`docs/design/nuvetrix-app-design-system.md`) stays in force for
  layout, type, spacing, copy and components, except where §3 below departs from it.
- **The branch-1 spec** (`docs/spine/specs/2026-10-07-house-rebuild-design.md`) stays in force
  except where this document overrides it.

---

## 1. Why this branch exists

On 2026-10-28 the user reviewed the merged branch 1 on a device and rejected four things:

1. **In light mode, picking an accent visibly changes nothing.** `LockoutPalette.schemeFor`
   puts the accent only in `primaryContainer` in light, and keeps `primary` at fixed house
   indigo for every accent. Profile uses `primary` (Save) and `secondaryContainer` (the selected
   segment), so only the swatch shows the accent. In dark the accent becomes `primary`, which is
   why dark "works".
2. **The accent changes only one colour pair, not the theme.** House §3 fixes one shared
   neutral palette for every Nuvetrix app; only the accent pair varies. Material 3 Expressive
   generates the whole tonal scheme — surfaces, containers, navigation, controls — from the
   chosen colour. The user expects the latter.
3. **The bottom navigation bar is the stock Material 3 `NavigationBar`.** It is not the
   Expressive bar.
4. **Icon containers are plain rounded squares.** The branch-1 contract allowed lobed shapes
   only on four subject-scale elements and required "ONE consistent squircle" on repeated icon
   containers. Quick actions therefore read as generic.

The user asked for Material 3 Expressive throughout. Where the house system says otherwise,
Lockout departs from it via the register in §3. The house system itself is not amended.

---

## 2. Scope

### In scope

1. **Branch-1 loose ends, as task 1** (moved here from the deferred Workout spec):
   - **Sentence case.** Fix "Today · WED" (the weekday abbreviation), "Custom Session", and the
     activity-level names ("Lightly Active", "Moderately Active", and the rest).
   - **Heading style.** Settings section headings use one style. "Training" currently renders
     smaller than "Activity level".
   - **Disabled icon buttons.** A disabled `NvIconButton` must look disabled. Today it keeps
     its full `surfaceContainerHigh` fill.
   - **Round-3 Minors** 3–7 and 9–11 from `.spine/final-review-findings-6.md`.
2. **Colour engine.** `LockoutPalette.schemeFor(brightness, accent, style)` generates the full
   `ColorScheme` with `ColorScheme.fromSeed`. Details are in §5.1.
3. **The style axis.** A third, user-selectable theme axis, `tonal | vibrant | expressive`. It
   is persisted, migrated and exposed in Settings (§5.2).
4. **Shapes.** `material_new_shapes` is added. `NvIconTile` takes a Material shape. Every quick
   action gets its own fixed shape and morphs to a circle when pressed. The existing
   `CookieBorder` uses move onto the package's cookie shapes (§5.3).
5. **`NvNavigationBar`.** The Expressive short navigation bar, replacing the stock
   `NavigationBar` inside `lib/widgets/bottom_nav.dart` (§5.4).
6. **Applied to the rebuilt screens.** Today, Profile/Settings and About adopt all of the above.
   The catalog components in `lib/widgets/house/` are updated where a role or shape changes.
7. **Guards and device QA.** Contract guards are updated for the new rules. Device QA runs
   early, on the colour engine, and again to close the branch (§5.6).

### Out of scope

- **Rebuilding the old screens.** Workout is branch 3; Progress, Body, Log and Food are
  branch 4. They pick up the generated scheme through the theme automatically, and nothing on
  this branch reworks their composition.
- **Wallpaper colour.** Dynamic colour from the wallpaper stays out: the seed is always the
  user's chosen accent. `dynamic_color` stays removed.
- **Data and dependencies.** No database schema change, and no package other than
  `material_new_shapes`.

---

## 3. Deviation register — additions

Branch 1's D1–D8 stay in force, and D9/D10 stay retired. This branch adds:

| # | Deviation | Status | Reason |
| --- | --- | --- | --- |
| D11 | Generated tonal scheme instead of the shared house neutrals | in force | House §3 fixes one neutral palette and lets the accent fill only the primary pair. The user wants Material 3 Expressive, where the chosen colour generates every role. Lockout seeds `ColorScheme.fromSeed` with the accent in both brightnesses. Supersedes the branch-1 contract's "in light the accent fills `primaryContainer` while `primary` stays `#2E2766`". |
| D12 | A third theme axis: scheme style | in force | The user chose to let people pick the scheme variant themselves: `tonal` (`DynamicSchemeVariant.tonalSpot`), `vibrant` and `expressive`. The house system has no such axis. |
| D13 | A distinct Material shape per icon container | in force | Supersedes the branch-1 rule that repeated small icon containers take one consistent squircle. Each quick action and icon tile carries its own fixed shape from the Material shape set. Cards, list rows and text containers stay rounded rectangles — real content is still never clipped into an irregular shape. |
| D14 | `material_new_shapes` dependency | in force | A Dart port of `androidx.graphics.shapes` (Material's 35 shapes plus morphing). MIT, pure Dart, offline. It is the one exception to "no new package dependencies"; a hand port was considered and rejected as slower and riskier for spec fidelity. |

D5 (lobe count as register on subject-scale elements) stays. It is now drawn with the package's
cookie shapes instead of `CookieBorder`.

---

## 4. Approaches considered

### A. Retint the existing hand-built palette (rejected)

Keep the authored neutral constants and blend the accent into them. This is a partial
re-implementation of Material's colour science, so it will never match what Material 3
Expressive generates, and every new role means another hand tuning.

### B. Use the framework's generator (recommended)

Use `ColorScheme.fromSeed(seedColor:, brightness:, dynamicSchemeVariant:)`, which is in
Flutter 3.47. It runs Material's own tonal algorithm and has no dependency cost. Lockout's
custom roles stay in `LockoutSemantics`, which is D4.

### C. Pull in a whole M3E component kit (rejected)

pub.dev has several `*_m3e` packages for buttons, navigation bars and toolbars. Adopting them
would replace the catalog branch 1 just built. Their offline behaviour and maintenance are
unknown, and the "no new dependencies" rule would effectively stop applying. Only the shape
primitive is worth a dependency.

---

## 5. Design

### 5.1 Colour engine

`LockoutPalette.schemeFor(Brightness brightness, LockoutAccent accent, LockoutSchemeStyle style)`
returns `ColorScheme.fromSeed(seedColor: accent.accent, brightness: brightness,
dynamicSchemeVariant: style.variant)`.

- `LockoutSchemeStyle` is an enum: `tonal` → `tonalSpot`, `vibrant` → `vibrant`,
  `expressive` → `expressive`.
- The authored neutral constants (`_lightSurface`, `_darkSurface` and the rest) are removed
  from scheme building.
- `surfaceTint` remains transparent. Elevation reads through container roles, not a tint
  overlay.
- **The identity accent.** The hero card keeps the exact accent colour (`accent.accent` on
  `accent.ink`), whatever the generated `primaryContainer` is. A generated tonal-spot lime is
  muted, and the hero is where Rep lime has to read as itself. This is exposed as
  `LockoutSemantics.heroFill` / `onHeroFill`, so the card never reaches for `LockoutAccent`
  directly.
- **`LockoutSemantics.semanticsFor` changes signature but keeps its roles.** It takes the
  style and the generated scheme. `success` / `successContainer`, the set-state roles and
  `categoryRamp` keep their values. Their contrast against the new generated surfaces is
  re-verified in tests at 4.5:1 for text pairs, across every brightness × accent × style
  combination (2 × 5 × 3 = 30).
- `LockoutSemantics.onCategoryColor` keeps deriving the glyph colour from the fill.

### 5.2 Style axis and storage

- **Stored value.** `theme_key` becomes `brightness|accent|style`, one setting with the same
  separator, so the schema does not change. The dartdoc that says "exactly two fields and there
  always will be" is corrected.
- **Migration** happens in `ThemeController._resolve`, extending the existing chain. The
  setting is never cleared:
  - A two-part value `brightness|accent` resolves to the same pair plus `tonal`.
  - The six retired single keys resolve as before, plus `tonal`.
  - Absent or junk resolves to `system|lime|tonal`.
  - The migrated value is written back, as the existing two-hop migration does.
- **Controller.** `ThemeController` exposes `style` and `setStyle(LockoutSchemeStyle)`, with
  the same persist-then-commit order as `setAccent`.
- **Settings.** "Look and feel" gains a "Style" `NvSegmentedButton` (Tonal / Vibrant /
  Expressive) under Accent. It applies instantly, like the other two.
- **Swatches.** Each accent swatch fills with its own `accent.accent`, so the choice shows the
  colour picked, not a generated tone.

### 5.3 Shapes

- **The dependency.** `material_new_shapes: ^1.0.0` is added to `pubspec.yaml` and recorded in
  `.spine/config.md` as the one permitted new dependency.
- **One mapping point.** A new `lib/theme/lockout_shapes.dart` is the only file that imports
  the package. It exposes `LockoutShapes`, a closed set of named shapes Lockout uses, and a
  `ShapeBorder` adapter. A screen never imports the package directly.
- **`NvIconTile`** gains a required shape parameter. At rest it draws that shape. While
  pressed it morphs to a circle with the package's morph on the `springFast` tier, and the
  morph is instant under reduced motion.
- **Quick actions.** Each action gets a fixed shape, assigned once in a single table. The
  same action always wears the same shape on every screen.
- **Different glyphs per tile.** The Material shape set has 35 shapes. Today's quick-action
  grid has eight tiles, so all eight are distinct. The table lives next to the action
  definitions.
- **The cookie shapes.** The four subject-scale elements — hero day marker, session-complete
  badge, progress hero medallion and theme swatch — move from `CookieBorder` to the package's
  cookie shapes, keeping D5's register: 4 rest, 6 training, 9 streak, 12 achievement.
- **`CookieBorder` deletion.** `CookieBorder` is deleted once nothing imports it. A
  pre-rebuild consumer outside the rebuilt screens would keep it alive and be recorded in the
  orphan ledger.
- **Cards and rows unchanged.** Cards, list rows and grouped-list rows stay rounded rectangles
  with their existing rest/active radius morph.

### 5.4 `NvNavigationBar`

A catalog component, consumed in the same task by `lib/widgets/bottom_nav.dart`, which keeps
its public `BottomNav` API and tab behaviour.

- **Size and fill.** The Material 3 Expressive short bar is 64dp tall on `surfaceContainer`,
  which is now tinted by the generated scheme.
- **Indicator.** A pill active indicator (56 × 32) springs between destinations on
  `springDefault`.
- **Icons and labels.** The selected icon switches to its filled variant, and every label is
  always shown.
- **Press feedback.** On a press the indicator squashes and recovers on `springFast`.
- **Accessibility.** Each destination stays a single semantics node with the label and a
  selected state.

### 5.5 Applied to the rebuilt screens

Today, Profile/Settings and About are audited role by role against the generated scheme.

- **Hard-coded roles.** Any place a component hard-codes a role chosen for the old
  fixed-neutral palette is re-pointed. Known example: the selected segment uses
  `secondaryContainer`, which was lavender under the house palette and is now generated.
- **Button hierarchy.** The filled button stays on `primary`. In light this now follows the
  accent, which fixes complaint 1 directly.
- **Tile surfaces.** Today's quick-action tiles currently fill with `inverseSurface`. They move
  to `secondaryContainer` / `onSecondaryContainer` so they read as tinted, with the new shapes.

### 5.6 Guards and device QA

- **Palette tests.** Tests that pinned the old neutral constants are rewritten to pin the
  generator inputs and outputs: the seed, the variant, and a sample of roles against
  `ColorScheme.fromSeed` itself.
- **Contrast matrix.** The 30-combination contrast matrix becomes a test.
- **Contract guard.** The contract guard gains three rules:
  - no import of `material_new_shapes` outside `lib/theme/lockout_shapes.dart`;
  - no `NavigationBar` outside `NvNavigationBar`;
  - no `CookieBorder` in a rebuilt screen.
- **Device pass 1** runs right after the colour engine and style axis land, before shapes and
  the nav bar. It covers all three styles × five accents in light and dark, with screenshots
  saved under `docs/spine/qa/`. The user sees these before the shape work starts.
- **Device pass 2** closes the branch. It covers:
  - quick-action shapes and their press morph;
  - the nav bar indicator;
  - the hero, badge and swatch cookies;
  - text scale 1.0 and 1.5;
  - the task-1 loose ends.
  A human TalkBack listen to the appearance picker and the new nav bar is requested.

---

## 6. Assumptions

- **Scheme generation.** `ColorScheme.fromSeed` with `dynamicSchemeVariant` is available in the
  pinned Flutter 3.47.2. Task 2 confirms it with a test before anything is built on it.
- **Package compatibility.** `material_new_shapes` 1.0.0 supports the pinned Dart 3.13 and
  Flutter 3.47. It requires SDK ^3.6.0 and Flutter >=3.22.0. If it fails to resolve, the task
  stops and reports; it does not hand-port silently.
- **Default style.** A fresh install starts on `system|lime|tonal`.
- **Old screens** look different after this branch, because they inherit the generated scheme.
  That is intended and accepted. Their pre-rebuild hard-coded colours, if any, are recorded as
  tickets for branches 3 and 4, not fixed here.
- **Test floor.** The 890-test serial suite is the floor.

---

## 7. Risks

- **Category colours against tinted surfaces.** `categoryRamp` and the set-state colours were
  tuned against fixed neutrals. A vibrant teal surface may sit too close to a category hue.
  The contrast matrix test catches text pairs; adjacent fills are checked on the device pass.
- **Expressive variant hue shifts.** The `expressive` variant rotates secondary and tertiary
  away from the seed. With lime, that can produce unexpected hues. This is accepted as the
  user's choice to make, and pass 1 shows it.
- **Shape morph cost.** Morphing paths on every press across a grid of eight tiles must stay
  under frame budget on the emulator. It is checked on pass 2, and the fallback is to cache
  the two shape paths per tile.
- **Migration.** A third field on `theme_key` touches the one piece branch 1 said not to touch.
  The migration is exhaustively tested from every historical value, including two-part values
  written by branch 1 builds.
