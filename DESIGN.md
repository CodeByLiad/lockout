---
name: Lockout
description: Native Android training tools in user-seeded Material 3 Expressive.
colors:
  rep-lime: "#C2EE7B"
  lime-ink: "#1F2E00"
  violet: "#B9A8FF"
  violet-ink: "#21105E"
  teal: "#6ED6C4"
  teal-ink: "#00382F"
  coral: "#FF9E8A"
  coral-ink: "#4A0E00"
  steel: "#A9B4C6"
  steel-ink: "#1B2430"
  success-light: "#1E6E47"
  success-container-light: "#CDEFD9"
  success-dark: "#7ED3A4"
  success-container-dark: "#0F3D27"
  warning-light: "#8A5A00"
  warning-dark: "#E8C06A"
typography:
  display-large:
    fontFamily: "BricolageGrotesque"
    fontSize: "44px"
    fontWeight: 800
    lineHeight: 1.0454545454545454
    letterSpacing: "-1.32px"
  display-medium:
    fontFamily: "BricolageGrotesque"
    fontSize: "36px"
    fontWeight: 800
    lineHeight: 1.0555555555555556
    letterSpacing: "-1.08px"
  display-small:
    fontFamily: "BricolageGrotesque"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.0625
    letterSpacing: "-0.96px"
  headline-large:
    fontFamily: "BricolageGrotesque"
    fontSize: "28px"
    fontWeight: 800
    lineHeight: 1.1071428571428572
    letterSpacing: "-0.7px"
  headline-medium:
    fontFamily: "BricolageGrotesque"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.1818181818181819
    letterSpacing: "-0.44px"
  headline-small:
    fontFamily: "BricolageGrotesque"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.4px"
  title-large:
    fontFamily: "BricolageGrotesque"
    fontSize: "19px"
    fontWeight: 700
    lineHeight: 1.2105263157894737
    letterSpacing: "-0.19px"
  title-medium:
    fontFamily: "Figtree"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.375
    letterSpacing: "0px"
  title-small:
    fontFamily: "Figtree"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.4285714285714286
    letterSpacing: "0px"
  body-large:
    fontFamily: "Figtree"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.4705882352941178
    letterSpacing: "0px"
  body-medium:
    fontFamily: "Figtree"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.4666666666666666
    letterSpacing: "0px"
  body-small:
    fontFamily: "Figtree"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.3846153846153846
    letterSpacing: "0px"
  label-large:
    fontFamily: "Figtree"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.3333333333333333
    letterSpacing: "0px"
  label-medium:
    fontFamily: "Figtree"
    fontSize: "13px"
    fontWeight: 700
    lineHeight: 1.3846153846153846
    letterSpacing: "0px"
  label-small:
    fontFamily: "Figtree"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.3333333333333333
    letterSpacing: "0px"
  countdown:
    fontFamily: "BricolageGrotesque"
    fontSize: "88px"
    fontWeight: 800
    lineHeight: 0.8181818181818182
    letterSpacing: "-4.4px"
  numeric-table:
    fontFamily: "JetBrainsMono"
    fontSize: "15px"
    fontWeight: 700
    lineHeight: 1.4666666666666666
    letterSpacing: "0px"
rounded:
  button-rest: "999px"
  button-active: "12px"
  button-large-active: "16px"
  row-rest: "8px"
  row-active: "20px"
  chip-rest: "12px"
  chip-active: "999px"
  segment-inner: "8px"
  segment-end: "22px"
  group-end: "26px"
  card: "28px"
  dialog: "32px"
  sheet: "32px"
  field: "16px"
  field-focused: "24px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  screen: "20px"
  card: "16px"
  hero: "22px"
  section: "28px"
  heading: "12px"
  group: "3px"
  scroll-bottom: "128px"
components:
  button-accent-lime:
    backgroundColor: "{colors.lime-ink}"
    textColor: "{colors.rep-lime}"
    typography: "{typography.label-large}"
    rounded: "{rounded.button-rest}"
    padding: "12px 24px"
  button-filled:
    typography: "{typography.label-large}"
    rounded: "{rounded.button-rest}"
    padding: "12px 24px"
  button-tonal:
    typography: "{typography.label-large}"
    rounded: "{rounded.button-rest}"
    padding: "12px 24px"
  button-outlined:
    typography: "{typography.label-large}"
    rounded: "{rounded.button-rest}"
    padding: "12px 24px"
  button-text:
    typography: "{typography.label-large}"
    rounded: "{rounded.button-rest}"
    padding: "12px 24px"
  button-danger:
    typography: "{typography.label-large}"
    rounded: "{rounded.button-rest}"
    padding: "12px 24px"
  field:
    typography: "{typography.body-large}"
    rounded: "{rounded.field}"
    padding: "20px"
  surface:
    rounded: "{rounded.card}"
    padding: "20px"
  grouped-row:
    typography: "{typography.title-medium}"
    rounded: "{rounded.row-rest}"
    padding: "16px"
  navigation:
    typography: "{typography.label-medium}"
  segment:
    typography: "{typography.label-large}"
    padding: "12px"
---

# Design System: Lockout

## Overview

**Creative North Star: "Material 3 Expressive"**

Lockout's built visual system is native Flutter Material 3 Expressive: confident display type, spacious task containers, distinct shaped icon badges and connected rows. The user's chosen accent generates the entire light or dark scheme. Primary, secondary and tertiary containers give different tasks visible character while keeping content readable in rounded rectangles.

The approved forty screen/state concepts establish the composition direction. Their illustrative figures and calendar defects are not product data. This document records the current implementation, rather than proposing a new identity or a web theme. The house system remains immutable; the whole-app deviations govern where it differs.

**Key Characteristics:**

- User-generated color across surfaces and controls.
- Bundled expressive display type with readable body text.
- Shape changes communicate press, selection and focus.
- Real local records determine summaries, schedules and charts.

Authority: `PRODUCT.md`, `AGENTS.md`, `CODEX_HANDOVER.md`, the unchanged `docs/design/nuvetrix-app-design-system.md`, and `docs/spine/specs/2026-11-03-whole-app-overhaul-proposal.md`. The latter's D15 supersedes historical D7's permanent five-tab rule; D16 replaces the fixed signature hero throughout rebuilt screens; D17 permits full-page editors and filled changing fields; D18 allows navigation and controls to grow; D19 records the explicit external source link in About. D1-D14 remain subject to the existing deviation register; D9/D10 are retired.

This extraction includes the source and Today recovery corrections verified on 2026-11-04, plus the final chart-width and finish-review snapshot fixes. First-round emulator evidence lives in `.impeccable/review/`; native confirmation captures live in `.impeccable/review/final/`. Confirmation covers named styles/live preview, the actual schedule strip, range-specific charts, filled workout inputs with one Add exercise action, singular finish/saved copy, and the inspected 360dp large-text phone and measurement-keyboard views. The final independent verdict is **Ship within the reviewed scope. All seven original findings are closed.** The current disposition is recorded in `.impeccable/review/finish-final-disposition.md`; `finish-review.md` and `finish-confirmation.md` retain historical findings and evidence. The final chart captures show all seven weekdays at 411dp and reveal the enlarged weekend labels with horizontal drag at 360dp/1.5x. Display settings were restored after the pass.

Functional verification: the final v1.3.1 serial suite passed all 940 tests (`.spine/release-v1.3.1-tests.log`). Analysis reports two pre-existing test information notices, zero warnings and zero errors. The final APK is 57,066,084 bytes, SHA-256 `9C84D39AB6CDD87D7583703D843EAA5BCFD6B69D64A94776600708E4CE77A4BF`. It uses the permanent release key and was installed and launched on an isolated read-only API 36 replica, preserving the original QA disk. Android displays the approved icon in its round adaptive mask. See `docs/spine/qa/overhaul/release-v1.3.1.md`; the earlier UI-candidate artifact identity remains historical in `verification.md`.

The verdict covers the representative native API 36 emulator evidence reviewed. It does not certify every approved screen/state, physical hardware, tablet behavior, TalkBack listening, a measured contrast matrix or independent motion quality. Passing tests and seven closed findings do not expand that visual-review scope.

The approved profile-setup follow-up extends this same world in local candidate `1.4.0+7`. Its five individually approved concepts are in `docs/design/onboarding-preview/`; the governing flow is `docs/spine/specs/2026-11-04-profile-onboarding.md`. Its independent finish review, `.impeccable/review/profile-setup-finish-review.md`, records **Ship** within the bounded onboarding/field scope. The final serial suite passed 973 tests (`.spine/profile-setup-final-tests.log`); the latest analysis has zero errors/warnings and two baseline information notices (`.spine/profile-setup-final-analysis.log`), superseding the review's earlier three-notice snapshot. The local signed artifact is `.spine/release/LOCKOUT-v1.4.0-preview.apk`; its signature record matches the permanent certificate. This is a local candidate record, not publication. See `.impeccable/review/profile-onboarding-documenter.md` for extraction evidence and limits. This documentation pass ran no tests or builds.

Frontmatter uses the portable format's CSS-length notation. In this native app those lengths represent Flutter logical pixels (dp), not a browser layout or physical display pixels. It contains actual authored seed/semantic values, type, spacing and radii. Generated color roles deliberately have no frozen hex substitute: their native bindings and generator are recorded below and in the sidecar. No CSS implementation or web component library is implied.

## Colors

The palette combines user-selected seed identity with generated Material role families.

### Primary

**Rep lime**, **Violet**, **Teal**, **Coral** and **Steel** are the five free accent choices in `lib/theme/accents.dart`. Rep lime is the fresh-install default. Seed and paired ink values are the frontmatter colors. These are generator inputs, not interchangeable values for `ColorScheme.primary`.

`LockoutPalette.schemeFor` calls `ColorScheme.fromSeed` with the selected seed, effective brightness and style. Tonal maps to `DynamicSchemeVariant.tonalSpot`; Vibrant maps to `vibrant`; Expressive maps to `expressive`. Expressive then pins `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer` and `inversePrimary` to the same seed's tonal-spot scheme. Secondary and tertiary keep their Expressive rotation. This preserves accent recognition on filled primary actions.

Use `primary/onPrimary` for ordinary filled actions and `primaryContainer/onPrimaryContainer` for primary task surfaces. The authored `heroFill/onHeroFill` semantic pair retains the exact seed and paired ink where consumed; the active rebuild generally uses generated role-colored surfaces under D16.

### Secondary

Use generated `secondaryContainer/onSecondaryContainer` for tonal actions and secondary task surfaces. The Expressive navigation indicator and selected segments use this pair. Do not substitute a universal authored secondary accent.

### Tertiary

Use generated `tertiaryContainer/onTertiaryContainer` for complementary task surfaces. It changes with seed, style and brightness. It is not a literal peach or lavender sampled from a concept image.

### Neutral

The scaffold uses `surface`; content uses `onSurface`; supporting text uses `onSurfaceVariant`. `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh` and `surfaceContainerHighest` provide the tonal depth ladder. Borders use `outline` or `outlineVariant`. These roles are all generated, so choosing another accent changes the surrounding app as well as buttons.

`LockoutSemantics` adds authored light/dark success and warning values; the palette's authored success-container values supply chart fill rather than a separate semantic container property. `danger` follows scheme `error`, and `restDay` follows `onSurfaceVariant`. Success is completion, not a general decorative accent. Category colors retain the authored eight-color ramp per brightness to distinguish training categories. The sidecar preserves those categorical values without misrepresenting them as a tonal ramp.

**The Chosen seed Rule.** Generate the whole scheme from the user's accent, brightness and style; resolve color through the current theme.

Persist the three independent axes as `brightness|accent|style`. Brightness is System, Light or Dark; the defaults are System, Rep lime and Tonal. Existing theme keys migrate in `ThemeController._resolve`; changing presentation must never erase a saved setting.

## Typography

**Display Font:** Bricolage Grotesque, bundled static instances (500/700/800).
**Body Font:** Figtree, bundled static instances (400/500/600/700).
**Label/Mono Font:** JetBrains Mono, bundled static instances (400/700), reserved for columnar numbers.

Bricolage gives the primary task a strong, friendly silhouette; Figtree keeps controls, supporting copy and longer explanations comfortable on a phone. No web-font fallback or runtime font download is part of the native system. Flutter uses its platform glyph fallback only when a bundled face lacks a glyph.

### Hierarchy

The frontmatter records the complete implemented `TextTheme`. Display large/medium support major metrics and page headings; headline styles organize task sections; title styles label cards and grouped rows; body styles carry instruction and context; label styles describe controls. `displaySmall` and `headlineSmall` are the implementation's interpolated slots.

`countdown` is the exceptional single hero number, at most one per screen. `numeric-table` captures the explicit table rhythm; the native numeric helper intentionally leaves leading unset unless a caller requests table leading, so an enlarged metric does not inherit table spacing. Body small and label small use `onSurfaceVariant`; other styles default to `onSurface` unless the containing role supplies contrasting ink.

**The Sentence case Rule.** Use sentence case for app-authored text; preserve user-entered names and normalize stored weekday tags only for presentation.

## Layout

The native spacing vocabulary follows a 4dp base and 8dp grid, with named exceptions for section rhythm, connected groups and heading gaps. Use the frontmatter spacing values through `LockoutTheme`, rather than creating another token class. Text/heading margins are normally screen padding; grouped lists/cards retain their contextual card margins. `NvPage` uses safe-area-aware scrolling with screen padding at the top and sides and xl bottom padding. Screens with both navigation and a floating action use the larger scroll-bottom allowance.

Task containers use varied scale and primary/secondary/tertiary roles. `NvActionCard` uses a shaped icon, title and live supporting value. `NvHeading` applies section and heading spacing. Avoid a universal fixed-height card grid: content and text scaling determine height.

Navigation has Today, Training, Progress and optional Food; Settings is a focused pushed route. `NvAppNavigation` defines the visible destinations; `MainScreen` coordinates task state and the live session route. Contextual rest controls remain a bottom sheet; routine/day/exercise, food and other substantial editors use focused pages. Back minimizes a live workout; discarding logged work is explicit.

There are no web breakpoints. Native constraints and text scaling drive adaptation: three-or-more segmented options stack vertically when a scaled 15dp label exceeds 20dp; navigation labels allow two lines and the bar grows; text buttons wrap and grow from minimum target height. Required stress evidence is a 360dp phone at 1.5x text, alongside normal phone captures. Fixed control-height and nav-height constants elsewhere in theme compatibility APIs do not override D18.

Required profile setup uses a safe-area Column: the setup header stays above an Expanded scrolling body, and an intrinsic-height action footer stays outside that scroll view. Keyboard insets reduce the available body space while the footer remains reachable above the keyboard. Header, body and footer retain 20dp horizontal margins; their native vertical paddings are 16/12dp, 12/24dp and 12/16dp respectively. Paired footer actions use Back at flex 2, a 12dp gap, and the primary action at flex 3; wrapping labels can grow the footer. The body can scroll independently at large text sizes rather than compressing its type.

## Elevation & Depth

Depth is mainly tonal layering, with no surface tint overlay. The theme clears `surfaceTint`; app bars have zero elevation and zero scrolled-under elevation. Theme defaults retain card elevation 1 and dialog/bottom-sheet elevation 6, while the active `NvSurface` and `NvInfoCard` implementations use tonal fill without custom box shadows. These native elevation numbers are not CSS shadow recipes.

Motion is shared through `LockoutMotion`: fast press/selection changes, default transitions/expands, and non-overshooting color/opacity effects. Exact durations and curves are in the sidecar. Reduced motion makes interaction transitions immediate. The wavy progress indicator alone has ambient drift; reduced motion stops its ticker.

## Shapes

**The Shape is a state Rule.** Interactive surfaces carry distinct rest and active shapes; irregular geometry belongs to icon containers, never to text or images.

Buttons morph from a pill to button-active radius (large buttons use button-large-active) with a 0.97 press scale. Rows morph from row-rest to row-active; connected groups keep group-end outer corners and group gaps. Segments use segment-inner/segment-end at rest and a selected pill, with separate pressed/focused rounding. Noninteractive status badges retain their chip outline; they are not fabricated filter controls.

`NvSurface` uses a contextual rounded rectangle (card radius by default, with larger task surfaces at 32 or 36dp), changing to 16dp when pressed/selected. A focus ring uses `primary` at 2dp. `NvField` changes from field to field-focused radius while retaining the text rectangle.

`NvIconBadge` uses `LockoutShapeBorder`, a distinct assigned `LockoutShape`, and a press morph toward a circle. `NvPressState` carries surrounding row/surface press and focus into badges. Only `lib/theme/lockout_shapes.dart` imports `material_new_shapes`.

The fixed signature outline (36dp on three corners, 12dp bottom-left) remains a compatibility token, not the universal rebuilt hero. `NvHeroCard`, `NvIconTile` and `NvEmptyState` are retained under `lib/widgets/legacy/` without active screen consumers.

## Components

### Buttons

`NvButton` is tactile, shape-changing and content-sized. Its variants bind native roles as follows: filled = `primary/onPrimary`; tonal = `secondaryContainer/onSecondaryContainer`; outlined = no fill, `onSurface`, `outline` border; text = no fill, `primary`; danger = no fill, semantic `danger`, `outlineVariant` border. Accent is specifically the inverted `onHeroFill/heroFill` pair for a semantic hero-fill background.

Labels wrap and controls grow; ordinary buttons have a minimum 48dp target and large buttons a minimum 60dp target, with label-large type and the frontmatter padding. Pointer press and keyboard focus activate the morph. Disabled text buttons use `surfaceContainerHighest/onSurfaceVariant`. `NvIconButton` has a required tooltip and uses a 48dp target; disabled fill/glyph use `onSurface` at 12%/38%. `NvSaveButton` blocks duplicate saves and retains input on failure.

### Chips

`NvSegmentedButton` provides actual single-selection controls, with selected `secondaryContainer/onSecondaryContainer`, unselected `surfaceContainer/onSurfaceVariant`, explicit selection semantics and 2dp primary focus rings. `NvStatusBadge` communicates neutral/accent/success status without implying tap behavior. Do not invent a chip variant absent from the catalog.

### Cards / Containers

`NvSurface` maps `NvTone.primary/secondary/tertiary` to their generated container pairs and `NvTone.surface` to `surfaceContainerLow/onSurface`. `NvInfoCard` uses `surfaceContainer` and card corners, with screen padding. `NvGroupedList/NvListItem` form connected rows at least 72dp tall, with title-medium, optional body-small support, card padding and inherited press for leading badges.

`NvEmpty` is a useful empty state with a shaped badge, honest explanation and optional action. `NvTbaCard` retains its dashed outline for unavailable information; it does not imply data exists.

### Inputs / Fields

`NvField` is the active filled native text form field: `surfaceContainerHigh`, body-large value text, field-to-focused radius, and error-role strokes/messages. Its label always floats **inside** the fill using `FloatingLabelBehavior.always` and `UnderlineInputBorder`; it does not straddle a notched outline. The border's rounded fill still morphs from 16dp to 24dp on focus. Rest has no stroke, focus has a 2dp primary underline, error has an error-role underline, and focused error uses 2dp. The floating-label style resolves from theme body-large, with `onSurfaceVariant` at rest, `primary` in focus and `error` on error; Flutter's floating-label layout renders it at a nominal 12sp before user text scaling, rather than displaying the full body-large size. This framework label treatment does not add a new global typography token. Normal padding is screen padding; compact set fields use 10dp horizontal and 12dp vertical padding. Error text may occupy up to six lines. `NvSetRow` uses compact fields for workout numbers rather than outlining a separate legacy input design.

### Navigation

`NvNavigationBar` is the custom Expressive bar, rather than stock `NavigationBar`. It uses `surfaceContainer`, a 56x32dp secondary-container pill, filled selected icons and label-medium labels. Its nominal minimum height is 64dp plus the safe area; content may enlarge it. The indicator slides with spring-default timing, squashes to 85% width while pressed and recovers with spring-fast timing. Destinations expose labels, selected state, tap action, tooltips and keyboard focus.

### Live preview and truthful activity

Appearance shows a live component preview, visible accent names and descriptive style rows. Those controls immediately use the existing three-axis controller; a descriptive style choice is not a new theme model.

Today resolves distinct next-action states from the active routine and schedule, within the same primary-container surface:

- No active routine: “Train on your terms,” a Create routine action, and an explicit custom-workout alternative.
- Active routine with no days: “Build your training week,” setup guidance naming that routine, and Open plan.
- Active routine with days but a weekday gap or explicit rest day: “Recovery day,” recovery guidance, and View training plan. A weekday gap does not masquerade as a missing routine.
- Scheduled training: the actual day name and exercise/set counts; Start workout appears only when that non-rest day has exercises. A training day without exercises instead offers Add exercises.

The explicit custom-workout alternative remains available, and an existing live session offers Resume workout. Scheduled-session startup independently rejects a missing day, an explicit rest day or an empty exercise list. Stale exercise records attached to a rest day cannot turn recovery into scheduled training. These states are based on actual plan data, without clearing or rewriting the routine to fix presentation.

Training's `NvWeekStrip` represents the real weekday schedule; rotating plans show a named training cycle. Planned and completed states have distinct semantics. Progress's `NvActivityChart` uses selected-period aggregation (daily week, seven-day groups within the month, and years for all time) and count labels. The Progress week runs Saturday through Friday, with chart buckets ordered Sat, Sun, Mon, Tue, Wed, Thu, Fri. Show the actual date range below the weekly workout count; include both years when a week crosses New Year. Exclude dates before Saturday and on or after the next Saturday. This user-requested reporting boundary does not change stored dates or training schedules. Chart width is the larger of available width and bucket count multiplied by three times the user's scaled 12dp label size. The week therefore fits an ordinary phone; enlarged labels or more buckets can scroll horizontally. `NvTrend` draws actual body measurements and explains when a second measurement is needed.

The finish review snapshots completion time when opened. Save persists the displayed duration and that completion date even if the user waits or crosses midnight before saving. Keep training dismisses the review and continues the session; opening a later review takes a fresh snapshot. Review time does not silently extend a workout the user has already chosen to finish.

**The Truthful visualization Rule.** Show actual records for the selected period and describe missing data instead of inventing sample activity.

Display units convert values at input and presentation boundaries; weights remain stored in kilograms. These native patterns preserve offline behavior and require no schema or dependency changes. Explicit Watch and About source-link actions are user-triggered external destinations, not permission to add background requests.

### Profile setup and unified editing

`NvSetupHeader` uses the approved monochrome dumbbell asset (`assets/branding/exports/monochrome/192.png`) at 32dp, tinted with generated `primary`, beside headline-small “Lockout” and a label-large step count. Below a 16dp gap, five equal 6dp-high rounded segments have 6dp gaps and 8dp corners. Current and preceding segments use `primary`; remaining segments use `surfaceContainerHighest`. The color changes use the effects motion tier and become immediate under reduced motion. Decorative logo/duplicate count semantics are excluded; the progress row announces “Step n of 5” once.

`ProfileGate` requires a valid saved profile before the task shell is shown. The five steps are About you, Measurements, Goal, Activity and Review. Introductory shaped badges are 72dp, headings use display-small, and explanatory copy uses body-large. A new profile starts with missing values empty and no silently selected sex; existing valid fields and the latest real measurement prefill setup. The first page offers Restore backup, with an explicit replacement confirmation. No Skip action, account request or early notification prompt is introduced.

Continue validates the current step. Back and interruption retain local raw-input drafts; draft values do not change active calculations. Review uses connected rows with direct Edit actions; editing a section returns through Review changes. Calculated nutrition targets and the existing planner's limiting/explanation behavior appear after completion, not as invented pre-save preview numbers. Busy state disables input/actions and shows the house wavy progress indicator; failure retains input with a visible explanation and reload/retry path.

Finish setup and Save profile call the same validated atomic completion service. It checks that the active baseline has not changed, writes profile values/unit preferences/completion together, adds the initial or changed weight measurement only when needed, and removes setup/edit drafts in the same transaction. Existing measurement history stays intact. Raw input is converted to stored kilograms/centimeters at completion, while interrupted drafts retain the chosen units. A conflicting restore or saved-profile change requires reload instead of silently overwriting the newer state.

The later Profile route uses the same editor, opening at Review with Save profile. Units contains weight/height **preferences** and an Edit profile entry; actual weight and height are entered together in Profile. These are native data-entry conventions, not a new palette or component family.

### Video recovery

The exercise-form WebView presents “Video unavailable” only after a resource error explicitly identifies the main frame (`isForMainFrame == true`). A blocked image, ad/script failure or unknown frame classification does not replace a usable page. The failure copy does not infer that Wi-Fi is off. Try again/Reload retains the in-app path; an explicit Open in YouTube or Open video link action invokes the existing external launcher, catches launch failure and keeps recovery available. External launching is never automatic. Invalid links have a separate Link not usable state. Training data remains locally available throughout.

## Android identity

The user approved **The last rep**, the angled dumbbell in icon exploration 03,
on 2026-11-04. A flat vector reconstruction uses Rep lime and dark ink. It is a
fixed launcher identity; the user-selected accent still generates the in-app
scheme. The master and five SVG/95 PNG variants live in `assets/branding`.
Legacy density icons, round/adaptive launchers and the Android 13 monochrome
layer share its geometry. The actual foreground passes the circular safe-zone
test. `tools/generate_brand_assets.py` regenerates these assets and provenance.

The private permanent signing key and recovery Markdown stay outside Git.
`docs/releasing.md` documents fail-closed local official release signing; the
unchanged CI workflow produces debug-signed test artifacts without the private key.

## Do's and Don'ts

### Do:

- **Do** compose rebuilt screens from the Nv house catalog and current theme.
- **Do** use the five chosen seeds and the three persisted scheme styles.
- **Do** allow labels and control heights to grow at large text sizes, with touch targets at least 48dp.
- **Do** propagate a containing row's press/focus state to its shaped icon badge.
- **Do** preserve local data, kilogram storage and conversions at the display/input boundary.
- **Do** confirm native appearance with fresh device captures after implementation changes.

### Don't:

- **Don't** freeze generated primary, secondary, tertiary or surface roles into a replacement palette.
- **Don't** add wallpaper colors, downloaded fonts, decorative stock imagery or background networking.
- **Don't** clip real content into a Material icon silhouette.
- **Don't** import compatibility-only legacy widgets into rebuilt screens.
- **Don't** treat approved concept arithmetic or stale captures as proof of the shipped behavior.
- **Don't** mark the finish review passed while its confirmation captures are pending.
