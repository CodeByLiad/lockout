# Lockout Material 3 Expressive restyle — design

Date: 2026-10-01. Revised 2026-10-06 to adopt the Nuvetrix App Design System.
Stage: FRAME
Supersedes the visual half of the baseline Material 3 contract merged at `b3eebc2`.

## 1. Problem

The branch merged at `b3eebc2` replaced the Jinatra Neubrutalist theme with Material 3. It
delivered *baseline* Material 3, not the Material 3 Expressive direction that
`.spine/config.md` itself named. The delivered UI is correct, accessible and dull: a fixed
shape scale, framework easing with no bounce, a single typeface doing both display and body
work, and six colour schemes that each weld a hue to a brightness.

A second problem surfaced on 2026-10-06. Lockout is a Nuvetrix app, and Nuvetrix now has a
house design system — `docs/design/nuvetrix-app-design-system.md`, vendored into this repo
from the canonical copy. The first draft of this spec was derived from the same WishPlay
prototype the house system was derived from, so the two agree on most things and collide on a
few. Where they collide, the house system wins unless this file records why it does not.

The restyle closes both gaps. It is a visual and interaction change only; no feature behaviour
and no database schema changes.

## 2. Governing documents

1. **`docs/design/nuvetrix-app-design-system.md`** (v1.1) — the house system. Authoritative for
   colour, type, shape, motion, spacing, components, copy and icons across every Nuvetrix app.
   The vendored copy is the one this repo tests against; it is kept byte-identical to the
   canonical file.
2. **This spec** — Lockout's own notes. It records every place Lockout departs from or extends
   the house system, with the reason, as the house system's own precedence rule requires.
3. `D:\Projects\Personal\WishPlay\Assets\WishPlay app prototype.html` — the original UI concept
   reference, now historical. The house system supersedes it as the source of truth. WishPlay
   itself is out of scope and is not Spine-governed.

Two amendments were made to the canonical house system as part of this work, and are present
in v1.1: Lockout's accent is registered in the accents table (§3.3), and an optional monospace
family for columnar numerals is defined (§4, §4.1). Both were filed there before use, per the
house system's instruction to add a missing piece to the document first.

## 3. Deviation register

The complete list of places Lockout does not follow the house system verbatim. Nothing outside
this table may depart from it.

| # | Deviation | Reason |
| --- | --- | --- |
| D1 | JetBrains Mono bundled for columnar numerals | The house system defines no monospace face. Filed upstream as the optional `numericTable` role (v1.1 §4.1) and used only for sets, reps and weight columns. |
| D2 | All five accents are free and user-selectable | §3.4 gates extra accents behind a Pro tier. Lockout is GPL-3.0, fully offline, with no auth, no billing and no entitlement store, so the gate has nothing to attach to. |
| D3 | `Cubic` curves rather than Compose springs | §6 specifies `spring(dampingRatio, stiffness)`, a Compose API with no Flutter equivalent. Settle times are matched instead; see 4.5. |
| D4 | `LockoutSemantics` and `categoryRamp` retained | App-specific colour roles — set state, day category — that the house system does not cover. They sit alongside the house roles, never replacing one. |
| D5 | `CookieBorder` lobe count carries meaning | §5.3 assigns cookie shapes to avatars, badges and placeholder logos. Lockout additionally reads lobe count as register on subject-scale elements; see 7.4. |
| D6 | `steel` as a fifth accent | Not in §3.4's optional set. Required so that `graphite` and `paper` users migrate onto a neutral rather than a hue they never chose. Its lightness is roughly 72%, just under §3.3's 75–85% band; accepted because `steel` is deliberately a neutral rather than an identity hue, and its ink pairing still clears 4.5:1 at about 7.6:1. |
| D7 | Five bottom-navigation tabs | §7.1 caps at four. Consolidating Lockout's navigation is a product decision, not a restyle. **Unresolved — carried to a later branch, not fixed here.** |
| D8 | No all-caps label style | Not a departure but a correction: the first draft of this spec specified a `labelMicro` style at 12px uppercase. §4.2 forbids all-caps labels outright, so `labelMicro` is dropped and `labelSmall` takes its place. Type contrast comes from size alone. |

## 4. Decisions

Taken during FRAME grilling on 2026-10-06. Each records the alternative that lost, so a later
reviewer can see the choice was made rather than defaulted into.

### 4.1 Authority — governing, with reasoned deviations

The house system governs; section 3 is the exhaustive list of exceptions, each carrying a
reason the house system's precedence rule would accept.

Rejected: adopting it verbatim with no deviations, which would drop the monospace face and the
accent picker and leave the legacy `theme_key` migration without targets. Also rejected:
treating it as advisory, which keeps Lockout's own direction but makes Lockout the one app in
the family that does not look like the family. Also rejected: finishing this branch as
originally drafted and aligning in a later branch, which would ship a typeface, an accent and a
dependency only to delete all three.

### 4.2 Theme model — one palette, two axes

Six authored schemes retire. One Lockout palette gains a real light/dark pair, and the user
chooses along two independent axes:

- **brightness** — `system | light | dark`
- **accent** — `lime | violet | teal | coral | steel`

The third axis in the first draft, Material You via `dynamic_color`, is removed. §2 of the
house system forbids dynamic colour outright, because wallpaper-derived schemes make a family
of apps stop looking like a family. Removing it deletes the `dynamic_color` dependency, the
`DynamicColorBuilder` at `lib/main.dart:25`, the controller's platform-scheme path, and the
error/tertiary harmonisation problem that existed only to keep a destructive confirmation and
a completed set from colliding under a hostile wallpaper.

Rejected: keeping dynamic colour as a recorded deviation, which preserves a shipped feature at
the cost of the exact outcome §2 exists to prevent. Also rejected: keeping the toggle but
harmonising wallpaper onto the house neutrals so only the accent pair moves — more
implementation than the feature is worth, down an untested path.

Accepted cost: users who selected the `dynamic` theme lose a feature they had. They migrate to
system brightness on the lime accent.

### 4.3 Accent set

The house system gives each app one identity accent and lets a Pro tier add more. Lockout
takes an identity accent and makes all five free (D2).

**Lockout's identity accent is Rep lime, `#C2EE7B`, ink `#1F2E00`.** It is registered in the
house accents table. It satisfies §3.3: lightness in the 75–85% band, dark-ink contrast of
roughly 12.8:1 against its own ink, hue 81° — 38° from WishPlay's gold and 89° from teal, the
widest gap open in the family — and it is neither Google Play green nor the reserved Nuvetrix
ultramarine.

`gold #FFB938` is removed from Lockout's set. It is WishPlay's identity accent, and §3.3
forbids a second app from reusing it.

| Accent | Hex | Ink |
| --- | --- | --- |
| `lime` (identity, default) | `#C2EE7B` | `#1F2E00` |
| `violet` | `#B9A8FF` | `#21105E` |
| `teal` | `#6ED6C4` | `#00382F` |
| `coral` | `#FF9E8A` | `#4A0E00` |
| `steel` | `#A9B4C6` | `#1B2430` |

The first draft gave each accent four tones — a solid and a container per brightness. That
table is replaced by the house model's single pair. In light, the accent fills
`primaryContainer` / `onPrimaryContainer` and `primary` is the fixed `#2E2766` for every
accent. In dark, the accent fills `primary` and `primaryContainer` alike.

Rejected: picking a hue closer to the existing family (sky `#7FD4FF`, 29° from teal) or far
outside it (orchid `#FFA6E0`). Lime won on separation plus fit for a training app.

Known consequence, accepted rather than mitigated: in light mode the accent now appears only on
hero cards, the FAB and badges, so the picker reads as a quieter change than four-tone accents
would have given. That is §3.5 working as designed — the accent is for emphasis on two or three
elements per screen — not a defect to engineer around.

### 4.4 Typefaces

Three bundled families under `assets/fonts/`, static instances only, all OFL:

| Role | Family | Weights | Used for |
| --- | --- | --- | --- |
| Display | Bricolage Grotesque | 500, 700, 800 | `displayLarge` through `titleLarge`, and `countdown` |
| Body | Figtree | 400, 500, 600, 700 | `titleMedium` down, all running text |
| Numeric | JetBrains Mono | 400, 700 | `numericTable` only — columnar sets, reps, weights |

Static instances only, because Flutter collapses a variable font to one instance and
`fontWeight` then stops working.

**Correction to the first draft.** It rejected Bricolage Grotesque on the grounds that it ships
variable-only and would need a build-time `fonttools varLib.instancer` step. That is true of
the Google Fonts API but not of the upstream project: `ateliertriay/bricolage` publishes static
TTFs under `fonts/ttf/`, including `BricolageGrotesque-Medium.ttf`,
`BricolageGrotesque-Bold.ttf` and `BricolageGrotesque-ExtraBold.ttf` — exactly the three
weights the house system names. No instancing step is required. Figtree likewise ships statics
upstream at `erikdkennedy/figtree/fonts/ttf/`.

Space Grotesk is therefore not bundled, and Inter is removed. Inter's four files leave
`assets/fonts/`; Bricolage's three and Figtree's four arrive.

Carried cost, which the first draft identified correctly and which still applies: Inter's
metrics are baked into measured layout constants, `LockoutTheme.statTileHeight = 72` among
them, derived from Inter at text scale 1.0 to 1.15. Swapping the body face re-opens every such
measurement. Each measured constant is re-derived under Figtree and re-pinned by its existing
test; this is scoped work in the plan, not a surprise discovered during build.

### 4.5 Motion

`LockoutMotion` exposes three tiers, mapped onto the house system's three kinds (D3):

| Tier | Value | Used for |
| --- | --- | --- |
| `springFast` | `Cubic(0.2, 1.35, 0.3, 1)` at 250ms | Press morphs, chip selection, switch thumb |
| `springDefault` | `Cubic(0.2, 1.35, 0.3, 1)` at 450ms | Sheets, screen transitions, card expand |
| `effects` | `Curves.easeOut` at 200ms, no overshoot | Colour and opacity |

The house system's `spring(0.6, 800)` settles in roughly 250ms and its
`spring(0.7, StiffnessMediumLow)` in roughly 450ms, so the tiers match by settle time even
though the curve form differs. `effects` carries no overshoot because §6 states explicitly that
colour and opacity must not bounce.

Rejected: porting the springs numerically with Flutter's `SpringSimulation` and the literal
damping and stiffness values. Physically faithful, but it replaces plain curves with
physics-driven controllers and makes every shape assertion harder to write and to read.
Also rejected: keeping one 450ms curve for everything, which leaves press feedback visibly
slow and makes colour fades bounce.

Reduced motion collapses all three tiers to an instant state change.

### 4.6 Scope — two branches

**Branch 1, this one: the token layer and two proof surfaces.** The revised contract, the house
palette, the Bricolage/Figtree/JetBrains Mono bundle and type scale, the house shape scale,
`LockoutMotion`, the two-axis theme model and the `theme_key` migration, `CookieBorder`,
`MorphingSurface`, `ConnectedGroup`, the settings theme picker (the one screen the theme model
forces to change), the Today tab as the proof surface, and the contract guard.

**Branch 2, later: propagation and the house component layer** — the §8 component catalog, the
§9.1 icon set, the §10 copy sweep, the About screen, and routines, body, food, log, progress and
profile.

Rejected: building the full component catalog in branch 1, which roughly doubles it while the
six target tabs still cannot adopt it until branch 2. Also rejected: everything except the
standard screens, which is the "bigger and later" failure Spine's governing rule 4 names, and
which the previous branch already paid for once in late cross-module review findings.

Accepted cost: between the two branches, master carries a visibly mixed UI — Today expressive,
routines still baseline M3.

### 4.7 Plan handling

The untracked 2026-10-01 plan is rewritten in place under the same branch-1 goal. No step of it
was completed and neither it nor the first draft of this spec was ever committed, so nothing is
lost and no superseded document is left in the repo for a later agent to pick up by mistake.

## 5. Migration

Schema stays at version 4. Only the stored `theme_key` setting changes, from a single scheme
key to the pair (brightness, accent). `ThemeController._resolveKey` maps every retired value;
it must never clear the setting.

| Old `theme_key` | Brightness | Accent |
| --- | --- | --- |
| `graphite` | dark | `steel` |
| `paper` | light | `steel` |
| `ember` | dark | `coral` |
| `linen` | light | `coral` |
| `indigo` | dark | `violet` |
| `frost` | light | `teal` |
| `dynamic` | system | `lime` |
| absent, or any unrecognised value | system | `lime` |

`linen` to light + coral is accepted because coral is the only warm accent available, and the
alternative — mapping it to steel — would collapse two distinct old choices onto one new one.

## 6. Colour

`LockoutScheme` is replaced by the house palette plus an accent.

The house neutrals are adopted verbatim for both brightnesses: `surface`, the four
`surfaceContainer` steps, `onSurface`, `onSurfaceVariant`, `outline`, `outlineVariant`,
`primary` / `onPrimary` in light, `secondaryContainer` / `onSecondaryContainer`, `tertiary`,
`tertiaryContainer` / `onTertiaryContainer`, `error`, `errorContainer` / `onErrorContainer` and
`scrim`. Exact values live in the vendored house document and are asserted by the contract
guard rather than restated here, so there is one place to change them.

Two roles are new to Lockout: the custom `success` / `successContainer` pair, `#1E6E47` on
`#CDEFD9` in light and `#7ED3A4` on `#0F3D27` in dark, for completed and approved states.

`LockoutSemantics` and `categoryRamp` survive as Lockout extensions (D4). `categoryRamp` stays
authored rather than derived — the finding that HSL rotation collides same-category days onto
one hue predates this redesign and still holds — but drops from six ramps to two, one per
brightness.

## 7. Shape, type and motion detail

### 7.1 Shape

The house corner scale and shape behaviours govern. Several of the first draft's pairs already
agreed with them and are unchanged.

| Surface | Rest | Active | Source |
| --- | --- | --- | --- |
| Button | full pill | 12dp, scale 97% | House §5.2 — replaces the draft's 24→12 |
| Large button | full pill | 16dp, scale 97% | House §5.2 |
| List row | 8dp | 20dp | Agrees with the draft |
| Group first/last child | 26dp outer corners, 3dp gaps | — | Agrees with the draft |
| Chip | 12dp | full pill | House §5.2 — replaces the draft's 12→19 |
| Segmented control | inner 8dp, ends 22dp | selected segment full pill | House §5.2, new to Lockout |
| Theme swatch | 18dp | 26dp | Lockout extension; the house system does not cover swatches |
| Hero card | `36 / 36 / 36 / 12` bottom-left, static | — | House §5.2 signature shape |

The hero card no longer morphs. The draft gave it a 36→22 pair; the house system makes its
asymmetric outline the family's signature card shape, and a card has no pressed state.

Non-interactive surfaces keep a single radius: dialog 32dp, bottom sheet 32dp top corners,
text field 16dp.

Shape-as-state remains contract for everything that does have an interaction state. A single
fixed radius on an interactive surface is a violation.

### 7.2 Type

The house scale is adopted whole — `displayLarge` through `labelSmall` at the house sizes,
weights, line heights and tracking — plus `countdown` (Bricolage 800, 88/72, -0.05em) and
`numericTable` (JetBrains Mono 500, 15/22). The draft's `heroNumeral` becomes `countdown`, at
800 rather than 700 now that the ExtraBold static is available.

Sentence case everywhere; there is no uppercase style (D8). The existing all-caps copy in
branch 2's six tabs is left alone — the copy sweep belongs to that branch — so the contract
guard's case rule is scoped to the files branch 1 restyles and widens later.

`displaySmall` and `headlineSmall` have no house entry: the house scale has thirteen styles and
Flutter's `TextTheme` has fifteen. They are interpolated between their neighbours at the same
family, weight and tracking ratio, and are the only two styles not copied from the document.
Four `ColorScheme` roles are filled the same way — `surfaceContainerLow`,
`surfaceContainerLowest`, `secondary` and the inverse trio — and the inverse pair is set so that
`inverseSurface` is `onSurface` and `onInverseSurface` is `surface`, which is exactly the
snackbar pairing §8 specifies.

### 7.3 Motion

As 4.5. Framework `Durations` and `Easing` tokens are no longer used; `LockoutMotion`'s three
tiers cover fades as well as morphs.

### 7.4 Lobed shapes

Lobed outlines appear only on subject-scale elements, where lobe count reads as register:

| Lobes | Amplitude | Register | Carrier |
| --- | --- | --- | --- |
| 4 | 0.10 | rest | Today hero day marker on a rest day |
| 6 | 0.07 | training | Today hero day marker on a training day |
| 9 | 0.06 | streak | Progress hero medallion |
| 12 | 0.04 | achievement | Session-complete badge |

The theme-picker swatch also takes a lobed outline, as the one place the shape language is
itself the content. This use of lobe count as meaning is Lockout's extension (D5); the house
system's own assignments — 9-sided for avatars and badges, 12-sided for a large profile avatar
— are compatible and are not contradicted.

Repeated small icon containers — the thirteen `radiusPill` circles across `lib/`, among them
the eight action-grid items bound to `categoryAt(0..7)` in `today_tab.dart:588-630` — take one
consistent squircle instead. They do not rotate lobe count, because colour already carries
category and two signals on one axis read as noise. The house system's §5.3 rule that real
content is never clipped into a cookie shape is also in force.

### 7.5 Morph mechanism — framework only

- `Cubic(0.2, 1.35, 0.3, 1)` is a valid Flutter `Curve`; Flutter does not clamp overshoot.
- Radius morph rides `AnimatedContainer` / `TweenAnimationBuilder` over `BorderRadius`.
- Lobed outlines come from a `CookieBorder extends ShapeBorder` with a polar-rose
  `getOuterPath` and real `lerpFrom` / `lerpTo`, unit-testable as pure geometry with no widget
  pumping.

Rejected: an off-the-shelf shape package. This app is GPL-3.0, zero-network and deliberately
dependency-light, and the package's own motion model would still have to be reconciled with the
pinned curves.

Known sharp edge: lerping between two different lobe counts requires sampling both outlines at
the same point count and interpolating vertex-wise. The design avoids needing it — lobe count
is a property of the carrier, not something that animates — and `CookieBorder.lerpFrom` asserts
rather than silently producing a wrong path if a caller ever asks for it.

### 7.6 Spacing

The house values govern where they differ from Lockout's: section gap moves from 24dp to 28dp,
heading-to-content is 12dp, screen margins are 20dp for text and headings and 16dp for grouped
lists and cards, and scrollable screens leave 128dp of bottom padding where a nav bar and FAB
are both present. The 8dp grid, 4dp base and 16dp card padding are unchanged.

## 8. Enforcement

`test/expressive_contract_test.dart` asserts Lockout's resolved theme against the vendored house
document mechanically — palette hexes, the type scale's families, sizes and weights, the corner
scale, and the hero card's asymmetric outline — so drift from the family standard fails a test
rather than a review. The guard reads the vendored markdown; it does not hard-code a second copy
of the values.

## 9. Out of scope

- Any database schema change. Schema stays at version 4.
- Any feature behaviour change: no new screens, no changed calculations, no changed navigation.
- The house component catalog (§8), icon set (§9.1) and copy sweep (§10) — branch 2.
- The house standard screens (§12). Welcome and Get Pro contradict the offline, no-auth, GPL
  stack outright and will not be built at all; About is feasible and deferred to branch 2.
- Bottom-navigation tab consolidation (D7).
- Branch 2's screens — routines, body, food, log, progress, profile.
- New package dependencies. `dynamic_color` is removed and nothing replaces it.
- The WishPlay project itself, and the Nuvetrix company brand, which §13 keeps out of app UI.
- Animating between two different lobe counts.

## 10. Testing

- `CookieBorder` geometry as pure unit tests: closed path, correct lobe count by extremum
  counting, amplitude bounds, and `lerpFrom` asserting on a lobe-count mismatch.
- Contrast guarantees across ten combinations (2 brightnesses x 5 accents): every
  `categoryRamp` entry at >= 3.0, every accent's ink-on-accent pairing at >= 4.5 per the house
  system's §3.3 rule, and the snackbar pairing at >= 4.5. The snackbar assertion changes target:
  the house system's §8 specifies an `onSurface` background with `surface` text, so the existing
  `inversePrimary` assertion is retargeted rather than kept.
- Migration test per old `theme_key`, including a junk value and an absent setting.
- Golden-free widget tests for the morph: pump, assert the rest radius, press, pump past the
  curve, assert the active radius.
- Re-pinned measured constants under Figtree, `statTileHeight` first, at text scale 1.0 to 1.15.
  `measured_constants_test.dart` lays out the real content at each scale and fails with the
  height actually needed, so the constants are measured rather than guessed.
- The contract guard of section 8.
- A guard asserting `dynamic_color` is absent from `pubspec.yaml`, replacing the existing
  assertion at `test/fonts_bundled_test.dart:50` that it is present.
- The full suite stays serial: `C:\src\flutter\bin\flutter.bat test --concurrency=1`.
  Baseline to hold or beat: 586 passing at `0a2ae73`.
- Browser QA is not applicable; this is an Android APK. The equivalent live pass is a real
  device or emulator run of the Today tab and the settings picker across all five accents in
  both brightnesses, plus one pass with the OS "remove animations" setting on.

## 11. Risks

1. **Mixed UI on master between branches.** Accepted in 4.6; branch 2 should follow promptly.
2. **Retiring six schemes is user-visible.** Mitigated by the migration table, but a user who
   liked `indigo` specifically gets dark + violet, which is close rather than identical.
3. **Losing Material You is a removed feature.** Users on the `dynamic` theme are migrated
   silently to system + lime. No in-app notice is planned; the release note carries it.
4. **Swapping the body face re-opens measured constants.** `statTileHeight` already showed that
   measured constants break at scale 1.15. Every such constant is re-derived under Figtree and
   re-pinned; this is the largest single source of unplanned work in the branch.
5. **The 88px `countdown` style and large text settings.** It needs the same treatment as
   `statTileHeight` and its own pinned test.
6. **Spring overshoot and reduced motion.** `MediaQuery.disableAnimations` must collapse all
   three motion tiers to an instant state change, or the direction becomes an accessibility
   regression.
7. **Font licence files.** Bricolage Grotesque and Figtree each need their OFL text shipped
   alongside the TTFs, as Inter and JetBrains Mono already do.

## 12. Assumptions carried rather than grilled

Each is above 90% confidence; stated here so they are visible rather than silent.

- Brightness defaults to `system` on a fresh install, and the accent defaults to `lime`.
- The app name stays LOCKOUT. The house system's §9.1 icon set is branch 2 work, so no icon or
  branding file changes in this branch.
- The vendored house document is the test fixture; keeping it in step with the canonical copy is
  a manual step, not an automated sync.
- The existing serial test constraint and the sqflite boot assertion are unchanged.
