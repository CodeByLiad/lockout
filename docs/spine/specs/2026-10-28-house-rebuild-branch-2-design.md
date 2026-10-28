# House rebuild — branch 2 (Workout)

Status: approved 2026-10-28. Branch: `house-rebuild-branch-2`, cut from `master` at `7fcce7f`
(branch 1 merged via PR #2).

Governing documents: `docs/design/nuvetrix-app-design-system.md` (the house system) and
`docs/spine/specs/2026-10-07-house-rebuild-design.md` (branch 1). Everything branch 1's spec
established stays in force unless this document says otherwise: the deviation register (§3), the
consumer-pulled catalog rule, the contract guard, the orphaned-widget ledger and the device QA
gate.

---

## 1. Why this branch exists

Branch 1 rebuilt the catalog, Today, Profile/Settings and About. Five screens kept their old
look: Workout, Progress, Body, Log and Food. They are split across two branches so each stays
about the size of branch 1 (51 commits, three review rounds for two screens). This branch takes
Workout, the core daily flow and the largest file. Branch 3 takes Progress, Body, Log and Food.

---

## 2. Scope

### In scope

1. **Branch 1 loose ends, as task 1.** They touch screens that are already rebuilt, so Workout
   starts from a clean base.
   - Sentence case: "Today · WED" (the weekday abbreviation), "Custom Session", and the
     activity-level names ("Lightly Active", "Moderately Active", and the rest of that list).
   - Heading size: "Training" renders in a smaller style than "Activity level" directly below
     it. Section headings in Settings use one style.
   - The disabled end of `NvIconButton` keeps its full `surfaceContainerHigh` fill and reads as
     pressable. A disabled icon button must look disabled.
   - Round-3 Minors 3–7 and 9–11 from `.spine/final-review-findings-6.md`.
2. **Workout, rebuilt** (`lib/screens/routines_tab.dart`), including the day sheet and the four
   forms: new routine, day, warm-up/finisher item and exercise.
3. **The exercise picker** (`lib/widgets/exercise_picker.dart`), rebuilt. Today is already
   rebuilt but still imports the old picker; it moves to the new one.
4. **The exercise video screen** (`lib/screens/exercise_video_screen.dart`), rebuilt.
5. **New catalog components**, each in the same task as its first real consumer:
   `NvFilterChip` and `NvSearchField`, plus any other §8 component the screens above need.
6. **The contract guard** (`test/expressive_contract_test.dart`), widened to every new or
   rebuilt file: sentence case, catalog-only composition and the framework-button ban.
7. **Two `lockout_qa` device passes**: one on the rebuilt Workout screen with real routines,
   before the sheets and forms are dispatched, and one closing the branch.

### Out of scope

- Progress, Body, Log, Food and the food picker. These belong to branch 3.
- The app shell: `bottom_nav.dart`, `main_screen.dart`, `profile_tab.dart`. These also belong
  to branch 3.
- The database schema, services and business logic. This branch changes composition, not data.
- Any new package dependency.
- The token layer (`lib/theme/*`).

---

## 3. Deviation register

Carried forward unchanged from branch 1 §3 (D1–D8 in force, D9 and D10 retired). This branch
adds none. D4 (`categoryRamp`) is what colours the day rows.

---

## 4. Approaches considered

### A. Rebuild in place (rejected)

Rewrite `routines_tab.dart` where it stands. This is the simplest option, but it leaves about
1,500 lines and five classes in one file, and every review reads the whole file.

### B. Parallel screen, swap at the end (rejected)

Build a new Workout screen alongside the old one and switch `main_screen` over at the end. The
two copies drift while the branch is open, and every behaviour fix has to land twice.

### C. Split while rebuilding (recommended)

Move Workout into `lib/screens/workout/` as it is rebuilt:

- the tab;
- the day sheet;
- the forms.

`lib/screens/routines_tab.dart` stays only as a thin export, so `main_screen.dart` and the
tests keep compiling until branch 3 touches the shell.

`RoutinesTabState`'s data loading and database calls move unchanged. Only the composition is
rewritten.

---

## 5. Design

### 5.1 Workout screen

Top to bottom:

1. **Header.** The "Workout" title (house `displayMedium`, as on Profile) and a `+ New` `NvButton`.
   `+ New` keeps today's starter-split flow.
2. **Active routine.** An `NvHeroCard` with accent fill and the signature corners. It does not
   morph. It shows:
   - the routine name;
   - then `NvStatusBadge`s in sentence case: "Weekday", "3 days", "Active". These replace the
     all-caps `Chip`s.
   - A trailing `NvIconButton` (⋮) opens an action `NvSheet` with add day and delete.
   The house prefers sheets over pop-up menus, so `PopupMenuButton` goes.
3. **"Week".** The active routine's training days as a connected group (`NvGroupedList`), always
   open. Each row has:
   - the weekday;
   - a 40dp `NvIconTile` in that day's `categoryRamp` colour (one squircle, no lobes);
   - the day name and the exercise count.
   Today's row carries an `NvStatusBadge` "Today". Tapping a row opens the day sheet. This
   replaces the `ExpansionTile` "Full week (n)".
4. **"Other routines".** The remaining routines as a connected group. Each row's ⋮ opens an
   `NvSheet` with "Set as active" and "Delete".
5. **No routines.** `NvEmptyState`: a headline, one sentence, and a "New routine" button that
   starts the same flow as `+ New`.

The duplicated "Today" featured-day block (`_buildFeaturedDay`, `_buildNothingScheduledCard`) is
removed: Home owns today. An active routine with no days shows an inline sentence under "Week"
and an "Add day" button in place of the group.

Spacing follows branch 1's contract: screen margin 20 for text and headings, 16 for groups and
cards, section gap 28, heading-to-content 12, and 128 bottom padding because the screen carries
the nav bar.

### 5.2 Day sheet

`NvSheet` titled with the day's tag and name. Exercises, warm-ups and finishers are each a
connected group with an add action. Editing a day uses an `NvButton`. Deleting a day uses the
house dialog (`NvDialog`), the only sanctioned dialog. The existing rule holds: every mutation
reloads routine data itself, so closing the sheet does not reload.

### 5.3 Forms

The new-routine, day, item and exercise forms become `NvSheet` bodies:

- `NvTextField` for text, with the label above the field;
- `NvSegmentedButton` for 2–4 exclusive options;
- the new `NvFilterChip` for the weekday and other multi-option rows: 38dp, a 1dp
  `outlineVariant` border, and when selected a `secondaryContainer` fill, a check icon and a full
  pill.
- Chip rows scroll horizontally and never wrap.
- Each chip animates 12 to pill on the `springFast` tier, following shape-as-state.

### 5.4 Exercise picker

- The new `NvSearchField`: a 58dp pill, `surfaceContainerHigh` fill, a leading search icon and a
  trailing clear button.
- Results as connected groups.
- Today's call site moves over in the same task, so no screen imports the old picker after it.

### 5.5 Exercise video screen

- Rebuilt with house cards.
- The offline notice becomes an info card.
- The unusable-link notice becomes a TBA card (transparent, dashed `outlineVariant` border),
  since that is what the house prescribes when data is not available.
- The runtime stays zero-network: the screen still only hands a link to the OS.

### 5.6 Contract guard

`test/expressive_contract_test.dart` gains every file under `lib/screens/workout/`, the rebuilt
picker and the video screen. The same rules apply as for branch 1's rebuilt files:

- sentence case;
- imports only from `lib/widgets/house/` and the theme;
- no framework `ElevatedButton`, `TextButton`, `OutlinedButton`, `FilledButton` or `IconButton`;
- no `Chip`, `ChoiceChip`, `PopupMenuButton` or `ExpansionTile`.

### 5.7 Device QA

The emulator is `lockout_qa` (API 36, release APK).

- **Pass 1** runs on the rebuilt Workout screen with at least two routines and a week of days.
  It runs in light and dark, at text scale 1.0 and 1.5, before the day-sheet and form tasks are
  dispatched.
- **Pass 2** closes the branch. It covers:
  - every sheet and form;
  - the picker from both Workout and Today;
  - the video screen;
  - the task-1 loose ends.
- A TalkBack listen to the appearance picker is still owed to a human from branch 1. It is asked
  for again at pass 2.

### 5.8 Orphaned widgets

Each rebuilt task records the widgets it stops using in `docs/spine/orphaned-widgets.md`.

- A widget whose last consumer goes on this branch is deleted on this branch.
- Expected: `day_block.dart`, `week_day_row.dart`, `today_day_card.dart` and
  `exercise_picker.dart`.
- `lockout_card.dart`, `lockout_field.dart` and `sheet_scaffold.dart` are still used by branch-3
  screens, so they are recorded but not deleted.

---

## 6. Assumptions (stated rather than asked)

- Starter-split creation, set-as-active and delete keep their current behaviour and copy, except
  where sentence case changes the copy.
- Rename is not offered: `DatabaseService` has no routine-update method, and this branch adds no
  service method. Rename is a ticket for a later branch.
- Day rows show the weekday that `ScheduleService` already derives from the routine's schedule.
  A day with no weekday (a non-weekday schedule) shows its tag instead.
- The 890-test serial suite is the floor. Every task adds guards that go red against pre-rebuild
  code.

---

## 7. Risks

- **Today regresses through the picker.** Today is rebuilt and green, and it now consumes a new
  picker. The picker task re-runs Today's suite and its device flow.
- **Split moves hide behaviour changes.** Moving code across files makes diffs hard to read. The
  split lands as its own task with no behaviour change, before the rebuild tasks. Reviewers can
  then read moves and rewrites separately.
- **The hero card on a day-less routine.** A new routine with no days must still read as active.
  It is covered by its own widget test and device check.
