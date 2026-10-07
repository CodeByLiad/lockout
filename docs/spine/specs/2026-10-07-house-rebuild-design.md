# House rebuild — branch 1 (catalog + two proof screens)

Date: 2026-10-07
Supersedes: §4.6 (two-branch scope) and the plan file of
`docs/spine/specs/2026-10-01-expressive-restyle-design.md`. That spec's deviation register
§3 carries forward and is restated here with D7, D9 and D10 resolved.
Governing document: `docs/design/nuvetrix-app-design-system.md` (Nuvetrix App Design System v1.1).

---

## 1. Why this branch exists

`expressive-restyle-branch-1` replaced the token layer — palette, type, shape, motion — and then
adapted the existing widgets to consume it. The result is an app whose tokens are house-correct
and whose screens still read as the previous design. Three review rounds found the same shape of
defect each time: primitives built with no consumer, shape-as-state constants that never reached
a pixel, a hero card that kept a neutral fill until a device screenshot caught it.

The conclusion recorded in `docs/spine/HANDOFF-2026-10-06.md` is that adapting a screen written
for a different design system preserves that system's decisions in places no token can reach.
This branch rebuilds screen composition from the house component catalog instead, and keeps the
token layer unchanged.

---

## 2. Scope

### In scope

1. The §8 component catalog, built in `lib/widgets/house/`, each component landing in the same
   task as its first real consumer screen.
2. Today, rebuilt from the catalog — both its pre-session and active-session states.
3. Profile / Settings, rebuilt from the catalog and reordered to §12.2 as far as the stack allows.
4. An About screen (§12.3), which the offline/no-auth/GPL stack does support.
5. Bespoke `NvSegmentedButton` and `NvButton`, retiring D9 and D10.
6. Extending `test/expressive_contract_test.dart` to cover the rebuilt screens, including
   widening §10's sentence-case rule to each newly rebuilt file.
7. Two `lockout_qa` emulator passes — one gating Profile/Settings, one closing the branch.

### Out of scope

- Workout, Progress, Food, Log and Body screens. They keep their branch-1 appearance; a visibly
  mixed UI on this branch is the accepted cost, as it was between the planned branches before.
- Welcome (§12.1) and Get Pro (§12.4). Both assume auth, a Pro tier and billing. Lockout is
  GPL-3.0, fully offline, with no account and no entitlement store, so neither screen has
  anything to attach to. They stay unbuilt — a standing decision, not a deferral.
- The database schema, services and business logic. This branch changes composition, not data.
- Any new package dependency. Shape, motion and the bespoke controls stay framework-only.
- The token layer itself (`lib/theme/*`). It is sound and tested; it is consumed, not rewritten.
  `theme_controller.dart`'s migration in particular is not to be touched.

---

## 3. Deviation register (carried forward, three resolved)

| # | Deviation | Status | Reason |
| --- | --- | --- | --- |
| D1 | JetBrains Mono bundled for columnar numerals | in force | The house system defines no monospace face. Filed upstream as the optional `numericTable` role (v1.1 §4.1); used only for sets, reps and weight columns. |
| D2 | All five accents are free and user-selectable | in force | §3.4 gates extra accents behind a Pro tier. Lockout has no auth, no billing and no entitlement store, so the gate has nothing to attach to. |
| D3 | `Cubic` curves rather than Compose springs | in force | §6 specifies `spring(dampingRatio, stiffness)`, a Compose API with no Flutter equivalent. Settle times are matched instead. |
| D4 | `LockoutSemantics` and `categoryRamp` retained | in force | App-specific colour roles — set state, day category — the house system does not cover. They sit alongside the house roles, never replacing one. |
| D5 | `CookieBorder` lobe count carries meaning | in force | §5.3 assigns cookie shapes to avatars, badges and placeholder logos. Lockout additionally reads lobe count as register on subject-scale elements. |
| D6 | `steel` as a fifth accent | in force | Required so `graphite` and `paper` users migrate onto a neutral rather than a hue they never chose. Lightness ~72%, just under §3.3's 75–85% band; its ink pairing clears 4.5:1 at ~7.6:1. |
| D7 | Five bottom-navigation tabs | **resolved — permanent** | §7.1 caps at four. Home, Workout, Progress, Food and Profile are each a daily destination; folding one behind a second tap costs more than the cap buys. Food is already user-disableable, so the cap is met for users who turn it off. No longer deferred. |
| D8 | No all-caps label style | in force | Not a departure but a correction: §4.2 forbids all-caps labels outright, so the draft `labelMicro` style is dropped and `labelSmall` takes its place. |
| D9 | Segmented-control segment shapes not implemented | **retired** | A bespoke `NvSegmentedButton` implements §5.2's inner 8 dp / outer end 22 dp / selected pill directly. The Material `SegmentedButton` limitation that forced D9 no longer applies. |
| D10 | Button press morph does not honour reduced motion | **retired** | `NvButton` reads `MediaQuery.disableAnimations` from its own `BuildContext`, which a context-free `ThemeData` could not. |

---

## 4. Approaches considered

### A. Theme harder (rejected)

Keep every existing screen widget and push the remaining house rules through `ThemeData`,
extensions and wrapper widgets. This is what branch 1 did. It is cheapest and it is the approach
whose failure produced this document: a theme cannot reach composition — which elements exist,
their order, their grouping, which one is subject-scale.

### B. Catalog-first, screens later (rejected)

Build the full §8 catalog standalone against a widget gallery, then rebuild screens on later
branches. Clean separation and a tidy diff, but a gallery is not a consumer: it exercises each
component in isolation and never asks whether the component is the right one for a real surface.
This is precisely how `MorphingSurface` and `ConnectedGroup` shipped with no consumer.

### C. Catalog pulled through by real screens (recommended)

Rebuild Today and Profile/Settings from scratch against §8 and §12, and let each screen's real
needs pull the catalog components into existence. A component is written in the same task as its
first consumer and is never merged without one. Today proves the catalog against a dense,
stateful, numeric surface; Profile/Settings proves it against §12's prescribed structure and
exercises every control type.

The cost is that the catalog arrives in the order the two screens happen to need it, so a later
screen may still find a gap. That is acceptable: a gap found by a real screen is cheap, and a
component built for no screen has already proven expensive here.

**Recommendation: C.**

---

## 5. Design

### 5.1 Baseline and branch

A new branch stacks on `expressive-restyle-branch-1` at `811fdce`. Branch 1 does not merge on its
own; the eventual whole-branch review and merge covers both. This keeps the token layer, the
contract guard, the vendored house document and the 695-test baseline intact, and avoids spending
a full review cycle certifying screens this branch is about to replace.

`.spine/frame-approved` is re-stamped to the new branch name on approval of this spec, since
switching branch after approval is a genuine re-approval event.

### 5.2 Component catalog — `lib/widgets/house/`

Each row names the component, its house section and the task that first consumes it. No component
lands without the consumer in the same task.

| Component | House ref | First consumer |
| --- | --- | --- |
| `NvButton` — Filled, Accent, Tonal, Outlined, Text, Danger | §8 Buttons | Today pre-session (Accent: start session) |
| `NvIconButton` | §8 Buttons | Today active session (close / back) |
| `NvSegmentedButton` | §5.2, §8 | Profile/Settings — brightness control |
| `NvGroupedList` / `NvListItem` | §5.2, §8 Lists | Profile/Settings — every settings row |
| `NvStatusBadge` | §8 Lists | Today — set state badge |
| `NvHeroCard` | §8 Cards | Today — the day marker |
| `NvInfoCard` | §8 Cards | Today — leg-safety notice |
| `NvTbaCard` | §8 Cards | Today — no routine scheduled |
| `NvTextField` | §8 Inputs | Today active session — the number stepper's field |
| `NvSwitch` | §8 Inputs | Profile/Settings — every toggle |
| `NvBottomSheet` | §8 Overlays | Today — finish-session summary |
| `NvDialog` | §8 Overlays | Profile/Settings — destructive data confirmations |
| `NvSnackbar` | §8 Overlays | Today — set logged |
| `NvWavyProgress` | §8 Progress | Today — session progress and rest bar |
| `NvEmptyState` | §8 Empty states | Today — no routine yet |

Three §8 components have **no consumer on these two screens and are therefore not built here**:
filter chips (neither Today nor Settings filters anything), the search field (the only search
surfaces are the food and exercise pickers, both out of scope), and the M3 Expressive loading
indicator (§8 forbids a spinner for local data, and all of Lockout's data is local). Recording
them as deliberately absent is the rule from §4 working: a component with no consumer does not
get written.

Existing widgets that the rebuilt screens no longer reach (`lockout_card`, `calm_row`,
`morphing_surface`, `connected_group`, `hero_card`, `today_day_card`, `stat_tile`, `action_grid`,
`home_hub`, and others) are **not deleted on this branch** — the five out-of-scope screens still
consume them. Each rebuilt screen's task ends by listing which widgets it orphaned; deletion
happens on the branch that removes the last consumer.

Catalog components read colour, type, shape and motion through `Theme.of(context)` and
`LockoutMotion` only. No compile-time colour constant, no static token class.

### 5.3 Today, rebuilt

Today is the live-session surface and carries two states.

**Pre-session.** Today currently composes a single `HomeHub` widget — an eyebrow, title, subtitle,
two hero buttons, a summary strip, an eight-tile quick-action grid and three shortcut rows. The
rebuild replaces `HomeHub` entirely rather than restyling it:

- A large title (`displayMedium`, §7.1 — no top app bar), the day name, with the weekday as
  supporting text. Sentence case throughout (§10, D8) — the `'QUICK ACTIONS'` caption the device
  pass caught is one of the strings this removes.
- `NvHeroCard`: accent fill, signature asymmetric outline (36/36/36/12 bottom-left), 22 dp
  padding, carrying the one big number in `countdown` style with its unit label (the day's set
  count), the day's title, and `NvWavyProgress` when a session is partly done. The day marker is
  the one subject-scale element here and takes a 4-lobe `CookieBorder` on a rest day, 6 on a
  training day (D5's register).
- One `NvGroupedList` of the day's exercises — 3 dp gaps, 26 dp outer corners, 8 dp inner, pressed
  item 20 dp — replacing the current stack of uniform cards.
- One accent `NvButton` ("Start session") and one tonal `NvButton` ("Custom session"), honouring
  §8's one-filled-or-accent-button-per-screen rule.
- The quick-action grid stays as a product feature but is rebuilt as a grid of §8 icon tiles —
  40 dp tile, 14 dp corners, one consistent squircle across all eight. Lobe count does **not**
  rotate across them: colour already carries category, and two signals on one axis read as noise.
- The three rest/empty/unscheduled states map to `NvEmptyState` (no routine yet), `NvTbaCard`
  (training day with no exercises) and a plain rest-day hero, rather than muted placeholder text.

**Active session.** The session header carries `NvWavyProgress`. Each exercise is an
`NvGroupedList` of set rows; a set's state reads through `NvStatusBadge` plus `LockoutSemantics`
(D4), with numerals in the `numericTable` role (D1). The number stepper rebuilds on `NvTextField`
and `NvIconButton`. The rest bar uses `NvWavyProgress` — the only ambient motion on the screen.
The finish summary becomes an `NvBottomSheet` (32 dp top corners, drag handle, 24 dp side padding).

Screen margins: 20 dp for text and headings, 16 dp for the grouped lists and cards. Section gap
28 dp, heading-to-content 12 dp, 128 dp bottom padding (nav bar plus FAB present).

### 5.4 Profile / Settings, rebuilt

§12.2 prescribes an order. Three of its entries assume a stack Lockout does not have, so the order
is followed with those omitted — this is an application of D2, not a new deviation:

| §12.2 entry | Lockout |
| --- | --- |
| 1. Header: large cookie avatar, name, email, Pro badge | Header with a 12-lobe `CookieBorder` avatar (§5.3) and the app identity. No name or email — there is no account. |
| 2. Sign-in card (guests only) | Omitted — no auth. |
| 3. Pro card (free users only) | Omitted — no Pro tier (D2). |
| 4. Look and feel: brightness segmented control, accent swatches | Built. `NvSegmentedButton` for Light/Dark/System; five accent swatches, all free (D2), each morphing 18→26 dp on selection, each a subject-scale element eligible for a lobed shape. |
| 5. App-specific settings | Units, Training, Food, Notifications, Data — each an `NvGroupedList`, replacing today's five cards. |
| 6. Account list | Reduced to what exists: About, and the data actions (export, import, clear). No Synced status, no Redeem a code, no Admin panel, no Sign out. |

Destructive data actions confirm through `NvDialog` (§8: dialogs only for destructive
confirmations); everything else that needs a choice uses `NvBottomSheet`.

**About** (§12.3) is built as a pushed screen with a simple top bar: "Made by Nuvetrix", the
version number, and the licence. The house text calls for links to the privacy policy and terms on
the Nuvetrix website; Lockout renders them as text rather than live links, because the app is
zero-network at runtime and a dead link is worse than none.

### 5.5 Bespoke controls (D9, D10)

`NvSegmentedButton` is written against `ShapeBorder` and `AnimatedContainer` directly: inner
segments 8 dp, outer ends 22 dp, the selected segment a full pill, morphing on the `springFast`
tier. `NvButton` is pill at rest, 12 dp pressed (16 dp for the large/accent variant), with a 97%
scale, on `springFast`. Both read `MediaQuery.disableAnimations` from their own context and
collapse to an instant state change when reduced motion is on. This closes D9 and D10 together.

### 5.6 Contract guard

`test/expressive_contract_test.dart` is the main defence and is extended, never weakened:

- §10's sentence-case rule widens from its current file list to every file this branch rebuilds.
- A new assertion: no rebuilt screen file imports a retired widget from `lib/widgets/` directly —
  rebuilt screens compose from `lib/widgets/house/` and the theme only.
- A new assertion: every `lib/widgets/house/` component resolves colour through
  `Theme.of(context)`, with no `Color(0x…)` literal and no reference to a static token class.
- A new assertion: every interactive house component declares both a rest and an active radius
  (shape-as-state), and the hero card declares the signature outline and does not morph.

The guard asserting something false is the failure that has recurred on this branch family. Each
new assertion must be proven to fail against the pre-rebuild code before it is accepted.

### 5.7 Device QA gate

A `lockout_qa` emulator pass (Android 16 / API 36, 1080×2400, density 420) runs on Today with
screenshots **before any Profile/Settings task is dispatched.** It is a hard gate, not a
checkpoint: Profile/Settings does not start until Today has been looked at on a device. A second
full pass closes the branch before the whole-branch review.

Both passes check the thing tests cannot: that the screen reads as the house design, not as the
old design wearing house tokens. Screenshots are saved outside the scratchpad this time, under
`docs/spine/qa/2026-10-07/`, so they survive the session.

---

## 6. Assumptions (not grilled — stated rather than asked)

1. Welcome and Get Pro stay unbuilt permanently, per §2's out-of-scope reasoning.
2. The copy sweep (§10) widens only to files this branch rebuilds; the six tabs carrying
   remaining all-caps copy are fixed on the branch that rebuilds them.
3. The token layer stays as-is. Any change to it is a finding against this spec, not a task.
4. Material Symbols Rounded at 24 dp, weight 400, grade 0 remains the icon set (§9); filled
   variant on the active nav tab only. No emoji.
5. Serial test runs (`--concurrency=1`) remain mandatory; the 695-test baseline must not regress.

---

## 7. Risks

- **The catalog arrives in two screens' order.** A later screen may find a gap. Accepted; see §4.
- **One large eventual merge.** Stacking on branch 1 means the Gate D review spans both branches.
  Mitigated by the per-task review loop and the two device passes.
- **Orphaned widgets accumulate.** Five screens still consume the old widgets, so `lib/widgets/`
  grows before it shrinks. Each task records what it orphaned so the later branch can delete
  cleanly.
- **Bespoke controls are new surface area.** `NvSegmentedButton` and `NvButton` replace
  framework widgets that handled focus, keyboard and semantics for free. Each needs explicit
  semantics, focus and reduced-motion tests, not just a visual one.
