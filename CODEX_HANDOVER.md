# Lockout — handover to Codex

Date: 2026-11-03. Written by Claude Code at the end of its sessions on this repo.
Read this whole file before you change anything. Then save the "Vision" and "Rules"
sections into your own memory (or `AGENTS.md`) so they survive between sessions.

---

## 1. What Lockout is

An offline-first strength training tracker for Android, built with Flutter.
Routines, live workout sessions, nutrition, body metrics and backups, all in a local
SQLite database. No account, no analytics, no ads, no server. The only network use is
opening YouTube form videos in a WebView when the user taps **Watch**.

Repo: github.com/CodeByLiad/lockout. Main branch: `master`. Licence: GPL-3.0-or-later.

---

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

## 4. Deviations from the house system

The house doc is vendored byte-identical and is never edited. Lockout departs from it only
through numbered entries. Add a new entry (D15, ...) to the current spec if you need one.

| ID | Deviation |
|---|---|
| D1 | JetBrains Mono bundled for sets/reps/weight columns |
| D2 | All five accents are free (no Pro tier) |
| D3 | `Cubic` curves instead of Compose springs, settle times matched |
| D4 | `LockoutSemantics` and `categoryRamp` kept for set state and day category |
| D5 | Cookie lobe count carries meaning on subject-scale elements |
| D6 | `steel` is a fifth accent |
| D7 | Five bottom-nav tabs (Home, Workout, Progress, Food, Profile) — permanent |
| D8 | No all-caps label style |
| D11 | Generated tonal scheme from the accent seed, not the shared house neutrals |
| D12 | Third theme axis: scheme style `tonal / vibrant / expressive` |
| D13 | A distinct Material shape per icon container |
| D14 | `material_new_shapes` dependency |

D9 and D10 are retired. Full text: `docs/spine/specs/2026-10-07-house-rebuild-design.md` §3
and `docs/spine/specs/2026-10-28-expressive-foundation-design.md` §3.

Accents: Rep lime `#C2EE7B` (default), violet, teal, coral, steel. Brightness:
system / light / dark.

---

## 5. Where things stand

### Branches

- `master` — includes branch 1 (house catalog, Today, Profile/Settings, About), merged via
  PR #2.
- `house-rebuild-branch-2` — the Material 3 Expressive foundation: generated scheme, style
  axis, per-icon shapes with press morph, `NvNavigationBar`, branch-1 loose ends. Final
  review passed, pushed to origin, version 1.2.0+3. **The PR was never opened** (the tool
  was blocked). Check with `gh pr list` before you assume.
- `fix/workout-tab-dead-ends` — **current branch**, cut from branch 2, version 1.2.1+4.
  Not pushed. Fixes:
  - an empty routine had no "Add day" button;
  - routine cards had no gap between them;
  - a custom session trapped the Home tab (now has a Leave button and system-back
    handling).
  All verified on the emulator.
- `expressive-restyle-branch-1`, `feat/ui-v2` — abandoned. Do not build on them.

Uncommitted changes in `linux/`, `macos/`, `windows/` generated plugin files are tool noise.
Leave them out of commits.

### Next task: Quick actions bento redesign (on `fix/workout-tab-dead-ends`)

The user approved a v1.2.1 release, but wants the Home Quick actions grid redesigned first.
Today it is 8 `NvIconTile`s, about 56dp, 4 columns, one muted tone.

Chosen direction: **bento**.
- Two wide hero cards first: **Log food** (live hint, for example "2200 left") and
  **Weigh in** (live hint, for example "82.5 kg"). Each has a big Material shape bleeding
  off a corner.
- Smaller square tiles for the rest: Workout, History, Custom, Streak, Plan, Exercises.

Open questions — ask the user these before building (my recommendation in brackets):
1. Six small tiles as 3x2 or 4+2? [3x2: no orphan row, more room for labels at 360dp
   and 1.5x text.]
2. When the Food tab is turned off, does Weigh in go full width? [Yes.]
3. Vary container colour per tile across primary / secondary / tertiary containers?
   [Yes — that is the "not dull" fix.]
4. Keep the press morph? [Yes.]

Code to touch: `lib/screens/today_tab.dart` (`quickActionShapes` ~line 122,
`_quickActionTile` ~686, the `GridView` ~820, `_quickActions` ~1005) and
`lib/widgets/house/nv_icon_tile.dart`.

Then: tests first, a device pass (including 360dp at 1.5x text), push the branch, open the
PR, and publish a GitHub release with the v1.2.1 APK. **Still unanswered:** does this go
in its own PR or get folded into the branch-2 PR? Ask.

### After that: branch 3 (Workout rebuild)

Spec: `docs/spine/specs/2026-10-28-house-rebuild-branch-3-workout-design.md`. It predates
the Expressive foundation, so re-frame it with the user before starting. Scope: rebuild
`lib/screens/routines_tab.dart` (with the day sheet and its four forms),
`lib/widgets/exercise_picker.dart` and `lib/screens/exercise_video_screen.dart`, add
`NvFilterChip` and `NvSearchField`, and run a colour-role audit like
`docs/spine/qa/2026-10-29-branch2-role-audit.md`.

Known bugs to fold into branch 3:
- On a non-Home tab, system back during a live session exits the app and loses the session.
- The day-count chip says "1 DAYS" (plural and all-caps).
- Saving a routine with an empty name gives no feedback.
- Chips are all caps (`WEEKDAY`, `ACTIVE`, from `.name.toUpperCase()`).

### Branch 4

Progress, Body, Log and Food. Not framed yet.

### Open tickets

- A human TalkBack listen to the appearance picker (never done).
- `NvHeroCard.progress` contrast.
- Keyboard/focus affordance on quick-action tiles and nav destinations.
- Tooltips on nav destinations.
- `navigationBarTheme` in `lockout_theme.dart` is dead code, still read by a test.

---

## 6. Where to read more

- `docs/design/nuvetrix-app-design-system.md` — house design system.
- `docs/spine/specs/` — approved designs per branch. The newest one wins.
- `docs/spine/plans/` — task plans.
- `docs/spine/qa/` — device QA reports and screenshots.
- `docs/spine/HANDOFF-2026-10-06.md` — why the incremental restyle was abandoned.
- `.spine/progress.md` (git-ignored, local only) — detailed task log and review notes.
- `.spine/config.md` (git-ignored) — the full pinned contract this file summarises.
- `README.md` — features as the user sees them.
