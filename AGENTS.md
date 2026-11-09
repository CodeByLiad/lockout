# Lockout project instructions

## Saturday-first reporting follow-up (2026-11-09)

The user clarified their week starts Saturday and explicitly requested publishing
the fix to GitHub. Progress uses Saturday–Friday, matching chart order and an
explicit date range. Preserve stored dates/history and training schedules.
Release v1.4.1+8 reuses the permanent signing key. See
`docs/spine/qa/2026-11-09-saturday-progress-week.md` for validation.

## Current follow-up (2026-11-04)

The user requests required first-launch profile onboarding after seeing height
entry separated from body-weight entry. Required setup is confirmed. Proposed
five-step flow: About you, Measurements, Goal, Activity, Review. Five separate
previews and exact prompts are in `docs/design/onboarding-preview/`; the user
approved them with "Approve and implement" on 2026-11-04. See
`docs/spine/specs/2026-11-04-profile-onboarding.md`.
Preserve and prefill existing user data; do not invent profile defaults or write
an initial measurement before final atomic completion. Implementation is authorized.

The user also reports false video-unavailable notices and exercise labels
straddling filled fields. Both fixes and onboarding are implemented with test-first
regressions; the final serial suite passes 973 tests. The local candidate is
v1.4.0+7. See `docs/spine/qa/profile-setup-verification.md` for evidence and limits.
Notification default-importance behavior was diagnosed, but its channel behavior
has not been changed. The user explicitly requested publishing this follow-up
and updating GitHub's README on 2026-11-04. Release v1.4.0 uses the permanent
v1.3.1 signing key. See the verification receipt for artifact identity.

## Latest user direction (2026-11-03)

The user requests a complete overhaul of the whole APK's UI and flows using
Mobbin, Impeccable and the taste skill, with Material 3 Expressive throughout.
Top-level navigation changes are explicitly approved; the old five-tab
permanence constraint no longer applies. Preserve product capabilities, user
data, offline behavior and the technical rules below.

The user's latest instruction is to generate a picture of every screen BEFORE
starting implementation, so they can review it. Forty separate screen/state
concepts are in `docs/design/overhaul-preview/`, with `index.html` as the gallery
and `screens.json` plus per-image sidecars recording the exact prompts.
The user approved these images on 2026-11-03: "That's great!!!! Proceed then".
Implementation is authorized. Use the approved layouts as the north star;
correct generated calendar labels, illustrative arithmetic and accessibility
issues in real code rather than copying those image defects literally.
The Quick actions-only task and old branch sequencing are superseded by the
whole-app request. See `docs/spine/specs/2026-11-03-whole-app-overhaul-proposal.md`.

Read `CODEX_HANDOVER.md` before making changes. It contains the deviation register,
current work, open design questions, and links to the governing specs. Also read
`.spine/config.md` and `.spine/progress.md` in this checkout; they are git-ignored.
The vision and rules below are preserved from the handover dated 2026-11-03.

## 2. The vision (what the user wants)

These are decisions the user has made. Do not re-open them.

1. **Full Material 3 Expressive, everywhere.** The user said it plainly after rejecting a
   build: "I told you everything material expressive". In practice:
   - The chosen accent **generates the whole colour scheme** (`ColorScheme.fromSeed`) in
     both light and dark. Changing the accent must visibly change the whole app.
   - The user picks the **scheme style** themselves: `tonal | vibrant | expressive`.
     In `expressive`, the primary role stays on the accent hue; secondary/tertiary keep
     the Expressive hue rotation.
   - **Every icon container wears its own distinct Material shape** (from
     `material_new_shapes`), and morphs to a circle when pressed.
   - The bottom bar is the **Expressive navigation bar** (`NvNavigationBar`), not the
     stock `NavigationBar`.
2. **The Nuvetrix house design system still governs** layout, type, spacing, copy and
   components: `docs/design/nuvetrix-app-design-system.md`. Material 3 Expressive wins
   where they conflict, but only through a numbered deviation (see §4).
3. **Screens are rebuilt from scratch, not restyled.** An earlier incremental restyle was
   abandoned because the screens kept looking like the old design in new colours. A
   rebuilt screen composes only from the house catalog in `lib/widgets/house/` (`Nv*`
   widgets) and the theme. It must never import a pre-rebuild widget from `lib/widgets/`.
4. **It must feel alive, not dull.** The user's latest complaint was that the Home
   "Quick actions" grid of small icons looks dull. They want bold, expressive
   composition: big shapes, live data in tiles, varied container colours.
5. **Offline and private, always.** No new network calls. No wallpaper/dynamic colour —
   the seed is always the user's chosen accent.

---

## 3. Rules to follow

### Process

- **Raise conflicts before you build.** If a design doc, spec or contract contradicts what
  the user asked for, stop and ask. Never quietly resolve it in the doc's favour. This
  exact failure caused the branch-1 rejection.
- **Ask framing questions before a new feature**, one at a time, each with your
  recommended answer. Get approval on the design before writing code.
- **Test first.** Write the failing test, then the code.
- **Run the device pass early, not as a final gate.** 695 green widget tests once missed an
  all-caps caption and a hero card with the wrong fill; the first emulator screenshot
  showed both. Tests prove geometry and state. Only a screenshot proves it looks right.
- **Commit messages:** Conventional Commits, lower-case scope, imperative and plain, for
  example `fix(today): add a way to leave a live session`.
- **Only commit, push, open PRs or publish releases when the user asks.**

### Toolchain

- Flutter 3.47.2 / Dart 3.13.2. The SDK is **not on PATH**. Use
  `C:\src\flutter\bin\flutter.bat` by absolute path.
- Tests **must run serially**: `C:\src\flutter\bin\flutter.bat test --concurrency=1`.
  Suites share one sqflite file; parallel runs give about 10 false failures.
  Last full run: 1056 tests, all passing. `flutter analyze` baseline: 3 issues.
- Smoke test for storage: `flutter.bat test --concurrency=1 test/backup_roundtrip_test.dart`.
- Device QA: Android emulator `lockout_qa` (API 36). Build with `flutter build apk`
  (`--debug` or `--release`), install with `adb install -r`. In Git Bash, screenshots need
  `MSYS_NO_PATHCONV=1` and a `//sdcard/` path, or adb rewrites the path.
  Also check at 360dp width with 1.5x text scale — that is where labels clip.

### Code and design contract

- Colour, type and shape resolve through `Theme.of(context)` / `ColorScheme`. Never a
  hard-coded `Color(0x...)`, never `Colors.white/black/grey`, never a static token class.
- **Sentence case everywhere.** No all-caps text, no uppercase label style.
- **Shape is a state.** Every interactive surface has a rest shape and an active
  (pressed/selected) shape, and animates between them. A single fixed radius on an
  interactive surface is a violation. The hero card is the one exception (fixed signature
  outline: 36dp on three corners, 12dp bottom-left).
- Real content (text containers, images) is never clipped into an irregular shape. Cards
  and list rows stay rounded rectangles.
- Motion comes from `LockoutMotion`: `springFast` (250ms), `springDefault` (450ms),
  `effects` (200ms ease-out, no overshoot). Reduced motion makes all three instant.
- Fonts are bundled, static instances only: Bricolage Grotesque (display), Figtree (body),
  JetBrains Mono (columnar numbers only). No `google_fonts` — it fetches over HTTP.
- No new package dependencies. The one exception is `material_new_shapes`, imported only
  by `lib/theme/lockout_shapes.dart`.
- Keep the token layer: `lib/theme/` (`palette.dart`, `accents.dart`, `scheme_style.dart`,
  `lockout_shapes.dart`, `lockout_motion.dart`, `lockout_semantics.dart`,
  `theme_controller.dart`).
- `theme_key` is stored as `brightness|accent|style`. Old keys migrate in
  `ThemeController._resolve`; never clear the setting to "fix" it.
- Database: sqflite, schema version 4, `lib/services/database_service.dart`. Migrations use
  the idempotent add-column helper, never a destructive recreate.
- Contract guards live in `test/expressive_contract_test.dart`. Widen them to cover every
  file you rebuild.
- A new `Nv*` catalog widget is written in the same task as its first real consumer screen.
  No widgets without a consumer.

---
