# Whole-app Material 3 Expressive overhaul

Status: forty screen concepts approved; whole-app implementation complete, with final verification recorded in `docs/spine/qa/overhaul/verification.md`.
Date: 2026-11-03.

## Brief

The user requested a complete overhaul of the APK's UI and flows, explicitly
discarding the current flow as a constraint. Use Mobbin, Impeccable and the taste
skill. This supersedes the narrow Quick actions bento task and the old branch-by-
branch screen order. It does not authorize deleting existing user data, features,
offline operation, or publishing a release.

Retain Flutter, local SQLite, bundled fonts, accent-generated schemes, the three
scheme styles, reduced motion, expressive shapes and the Nv component catalog.
No new dependencies. The house document stays byte-identical.

## Design approval record

1. Resolved: the user explicitly chose "Allow navigation changes (recommended)".
   The handover's five-destination permanence constraint (D7) is superseded.
2. Resolved: the user approved all forty generated concepts on 2026-11-03:
   "That's great!!!! Proceed then". Implementation is authorized.

The approval covers the proposed whole-app flow and visual direction.

The user then instructed: generate a picture of each screen before starting.
Forty separate concepts are saved in docs/design/overhaul-preview/index.html,
with exact prompts and provenance in screens.json and per-image JSON sidecars.
They include full-screen routes, editors, sheets, dialogs, dark-mode examples and
a component state specimen. Approval was recorded after generation and before
Flutter UI implementation began. Example data, calendar labels and
chart arithmetic in generated images require correction in the real implementation.

## Audit findings from source

| Surface | Current behavior | Replacement requirement |
| --- | --- | --- |
| App shell | IndexedStack preserves tabs; selection uses positional indices | Stable destination identity; correct behavior when Food is disabled; system Back follows navigation history |
| Home | Today's workout, exercise preview, numbers and eight small actions in one long page | Short daily launch surface; primary training action in the first viewport; direct food and measurement entry |
| Active workout | Replaces Home's entire body | Dedicated workout experience; leaving the view must not silently discard work; a clear resume entry across destinations |
| Workout Back | TodayTab only intercepts Back while its TickerMode is enabled | Session protection must apply at the shell/route level, including non-Home destinations |
| Routines | Routine cards contain featured cards and a collapsed week; days and forms open in sheets | Clear library -> routine -> day -> exercise flow; visible create/edit actions; short sheets only for bounded choices |
| Routine forms | Blank name returns without feedback; chips uppercase; day count always plural | Inline validation, preserved input, sentence case and correct singular/plural |
| Exercise picker | Catalog search and muscle filters in an older full-height sheet | Search-first selection, consistent filters, clear custom-exercise path; preserve existing search ranking |
| Exercise video | WebView reached by explicit Watch action | Preserve explicit network opt-in, offline explanation and retry/back path |
| Food | Older calories card, three stat tiles, picker then separate entry form | Daily meal journal; search -> serving/macros -> save with clear context; edit/custom/cancel paths remain discoverable |
| Progress | Body and workout history are separate halves of a segmented control | Connect progress summaries to their real histories; accessible date and metric context; clear measurement entry |
| Body | Weight hero, four metrics, then separate sheets for goals, plan, BMI and history | Weight trend and measurement entry lead; contextual goal explanation; avoid a chain of modals |
| History | Uppercase copy and older cards; expansion reveals set details | Scannable workout archive -> readable workout detail; deletion with undo; useful empty state |
| Profile | Entire settings form is embedded in a tab | Overview with grouped destinations; focused appearance, units, goals, reminders and backup screens |
| Appearance | Already has generated schemes and shape morphing | Retain all choices and migration behavior; integrate into the replacement navigation |
| Backup | Existing import/export safety logic and shared import lock | Keep transactions, validation, navigation lock and error recovery intact |

Evidence: lib/screens/main_screen.dart, today_tab.dart, routines_tab.dart,
progress_tab.dart, body_tab.dart, log_tab.dart, food_tab.dart,
profile_tab.dart, settings_screen.dart; lib/widgets/exercise_picker.dart and
food_picker.dart. This is a source audit, not a completed visual QA verdict.

## Proposed task architecture

The main jobs are train, log nutrition, and understand progress. Account settings
are not required because there is no account.

- Today: scheduled session or an actionable rest/empty state; daily food and body
  summaries; a resume workout control when applicable.
- Training: active plan and routine library; routine detail with its days; day
  detail with ordered exercises, warm-up and finisher; explicit start and edit.
- Progress: real workout and body trends with direct links to history and goals.
- Food, when enabled: daily meals, calories and macros; a primary Log food action.
- Personal settings: reachable from a consistent top-level affordance, or kept as
  the fifth tab if the user retains D7.

If navigation changes are allowed, recommend four task destinations with settings
outside the bottom bar. If Food is disabled, three destinations remain. A compact
Material navigation bar serves phones; an expanded navigation rail serves wider
layouts. Labels and exact destination composition remain subject to approval.

## Proposed flows

Training: Today or Training -> workout preview -> start -> log sets and rest ->
finish review -> saved workout detail. Back minimizes the active workout into a
resume control; explicit discard confirms loss. A second start resumes or asks
the user to resolve the existing workout rather than replacing it.

Routine creation: starter or custom -> named routine -> add day -> add exercises
-> review schedule -> activate. A new empty routine always exposes Add day.
Validation explains missing names and invalid values before leaving the form.

Food: Today's Log food or Food -> catalog/custom search -> serving and editable
macros plus meal slot -> save -> updated journal. Cancellation returns to the
previous context without adding a row. The chosen date/meal must not be lost.

Body: Today's Weigh in or Progress -> measurement entry -> save -> updated trend.
Goals and calculated recommendations are explained beside the relevant data;
missing inputs link directly to their focused editor.

Settings: personal settings -> focused category -> save or immediate appearance
update -> return. Backup remains explicit export or validated import; import
continues to block competing writes/navigation while it replaces local data.

## Visual direction constraints

Material 3 Expressive governs native controls and interaction. Use generated
primary, secondary and tertiary containers purposefully, expressive navigation,
large readable headlines, connected list groups, expressive button groups and
distinct shaped icon containers. Press states morph using LockoutMotion; reduced
motion changes instantly. Text and photos never use irregular masks.

Compose rebuilt surfaces from Nv widgets and theme roles. Create missing catalog
components only alongside their first consuming screen. A token-only restyle or
the same old card stack in new colors does not satisfy this brief.

The taste skill is scoped to public websites, so its website-specific imagery
quotas, hero structures and browser checks do not govern this native app. Its
principles of deliberate hierarchy, composition and typography supplement the
user's Material brief. Impeccable's Android guidance supplies native structure.
Project-pinned colors, fonts, shape vocabulary and motion override generic skill
preferences. No stock imagery or invented activity data is needed.

## Mobbin evidence

Available mobile searches support iOS rather than Android. References inform
information grouping and journeys, not copying iOS controls into Android.

- [Centr daily plan](https://mobbin.com/screens/781957fc-8d0b-4687-82b7-ec9b92c97e21):
  today's training dominates the first view; nutrition follows as a separate task.
- [Withings daily trends](https://mobbin.com/screens/4f910ac9-dadf-443e-a79c-9bfc293ee5af):
  measurements and trends are reachable from a daily overview.
- [Bevel fitness flow](https://mobbin.com/flows/56e193d6-9518-4ef8-93de-0fbe3872d4d4):
  groups strength progression and workout templates in the fitness destination.

Searches: fitness app home screen; fitness app workout tracking. Returned preview
images were inspected. These sources are reference evidence, not visual approval.

## Implementation and acceptance plan

1. Resolve navigation conflict; capture product truth in PRODUCT.md; approve the
   replacement direction and record deviations where the existing spec changes.
2. Write failing behavioral tests before each implementation slice. Run all tests
   serially with C:\src\flutter\bin\flutter.bat test --concurrency=1.
3. Rebuild the shell and workout lifecycle first: Back, minimize/resume, safe
   switching, Food visibility and prevention of accidental session replacement.
4. Rebuild Today, training library/details and exercise selection/editing.
5. Rebuild nutrition and its picker/editor; Progress, history and measurements;
   personal settings and all secondary surfaces, including About and video states.
6. Extend expressive contract guards to every rebuilt screen and component.
7. Verify empty, populated, invalid, loading, failure, undo, keyboard and reduced-
   motion states. Cover a full routine -> session -> history journey, a food
   entry and a body measurement with real database reads.
8. Device QA early and after the full build: light/dark, each scheme style,
   changing accent, 360dp at 1.5x text, keyboard insets and Android system Back.
   Use real emulator screenshots; no web rendering as native evidence.
9. Run the serial suite, analyzer and storage round-trip. Have the finished native
   screens reviewed against the approved direction and document the built system.
10. Build a reviewable APK. Do not commit, push or publish without a user request.

## Initial verification status

- Working branch: fix/workout-tab-dead-ends. Existing platform-generated file
  changes and the uncommitted handover/instructions must be preserved.
- No emulator was running at audit start. Started lockout_qa headlessly; it booted
  successfully as emulator-5554. Opened the existing v1.2.1+4 install and captured
  docs/spine/qa/whole-app-baseline/phone.png. This is baseline evidence only.
- Serial storage smoke test passed: 32 tests in backup_roundtrip_test.dart.
  No new UI code has been written.
## Approved direction and implementation (2026-11-03)

The user approved all forty screen/state concepts: “That's great!!!! Proceed then”.
The four task destinations are Today, Training, Progress and optional Food.
Personal settings are focused routes reachable from each destination. This section
supersedes the earlier pending-review language and initial verification snapshot.

### Additional house-system deviations

D1–D14 remain recorded in CODEX_HANDOVER.md. The approved whole-app concepts add:

| ID | Approved change | Reason and boundary |
| --- | --- | --- |
| D15 | Four task destinations; settings leave the tab bar | The user explicitly allowed navigation changes for the full flow overhaul. Food visibility remains configurable. |
| D16 | Role-colored expressive surfaces replace the fixed signature hero throughout rebuilt screens | Approved concepts use primary, secondary and tertiary containers at task scale. All values still resolve from the chosen seed, style and brightness. Content stays in rounded rectangles. |
| D17 | Full-page editors and filled, shape-changing fields | Approved concepts replace nested sheets and outlined form stacks. Rest remains a contextual bottom sheet. Food has one portion editor after catalog selection rather than two serving confirmations. |
| D18 | Navigation and controls grow for accessibility | User text scale takes precedence over a fixed control height or one-line label. Targets remain at least 48dp. |
| D19 | Explicit external source-code row in About | The approved About concept includes a user-triggered source link. No background networking is added; training, food, measurements and backups remain local. Video loads only after Watch. |

### Built flow

- Today presents the scheduled workout or a useful setup state, with food and
  measurement actions, a real weekly strip, recent activity and exploration.
- Training opens routines and days as routes; empty routines always expose Add
  day. Exercise selection supports multiple additions in one atomic write.
- Workout logging has a focused route, direct set inputs, wall-clock timers,
  contextual rest, minimize/resume, explicit discard, finish review and saved
  confirmation. Only completed sets are archived in one transaction.
- Progress combines period totals, real weight trends and focused history,
  measurements and goals. Measurements and food support root-overlay undo.
- Food preserves the selected date and meal slot, supports catalog or custom
  entry and edits an existing row without creating a duplicate.
- Settings separates appearance, units, profile/goals, training, reminders,
  backup/restore and About. Restoring a backup is unavailable during live training.

No dependencies or database schema changes were introduced. Weight preferences
convert display/input while storage remains kilograms. Appearance migration and
backup validation retain their existing service contracts. Preview rasters are
review artifacts and are not Flutter app assets.

### Regression migration

Tests tied to the discarded five-tab layout, expandable routine cards, old
WeightCard/ProgressHero widgets, duplicate food-serving sheets and the giant
workout countdown were replaced with behavior checks for the approved routes.
Data/service tests remain. New coverage reads the real test database after
routine, exercise, food, measurement and session writes; checks retry after a
rejected workout transaction; verifies wall-clock timer suspension; and checks
undo restores record and set identities. Legacy catalog primitives are retained
under lib/widgets/legacy for compatibility tests, outside the active Nv catalog.
The active-catalog guard follows imports from shipping screens transitively.

Native evidence is in .impeccable/review. Final counts, review findings and APK
location are recorded in docs/spine/qa/overhaul/verification.md when verified.
