# Independent native finish review

## 1. Disposition

**Fix, then recapture.** The inspected build establishes a coherent native Material 3 Expressive direction: strong display typography, seed-colored task surfaces, shaped actions, four clear destinations, focused workout completion, and credible dark treatment. A rebuild of the overall direction is unnecessary. It is not yet a whole-app shipping pass: accessible action labels, approved composition details, and interactive shape behavior need correction and fresh device evidence.

This review applies to the first inspection captures and source inspected on 2026-11-03. Root reports some changes after those captures; those changes need confirmation captures, not duplicate implementation.

## 2. Scoped evidence

Read AGENTS.md, CODEX_HANDOVER.md, local Spine configuration/progress, PRODUCT.md, the surface direction contract, the whole-app proposal/deviation register, and Impeccable craft-floor/Android references. Latest approved whole-app direction and D15-D18 govern over historical five-tab/fixed-hero instructions. The user-selected generated scheme governs color; illustrative lavender/peach, data values and defective generated dates are not literal implementation requirements.

Independently viewed these actual emulator screenshots in `.impeccable/review/`: today-light, training-light, progress-light, food-light, appearance-light-expressive, today-dark, training-dark, progress-dark, food-dark, settings-dark, routine-light, day-light, exercises-light, workout-light, rest-light, finish-light, saved-light, phone-360-large (all PNG). Capture provenance supplied by root: Android API 36 emulator; ordinary phone width 411dp and stress case 360dp at 1.5x text.

Compared approved concepts 01-today, 02-training, 09-workout, 10-rest-timer, 13-progress, 19-food, 23-settings and 24-appearance. Source inspection covered navigation, representative screen compositions, settings appearance, house buttons, expressive surfaces/fields, grouped rows, set rows, and display-unit conversion. No tests, builds or implementation were performed by this reviewer. Native evidence is used; no HTML/CSS detector or browser measurements are claimed.

## 3. Prioritized findings

1. **P1 — Accessible action label is truncated.** `phone-360-large.png` shows “Start a custom work...” inside the Today hero. `lib/widgets/house/nv_button.dart:166` fixes button height and `:192` limits labels to one line with ellipsis. This violates approved D18 and hides the full next action at the required accessibility size. Minimum touch height should remain, while labels wrap and controls grow. Verify both footer buttons and inline buttons after the shared fix.

2. **P2 — Appearance retains the former compact picker instead of the approved composition.** `appearance-light-expressive.png` and `lib/screens/settings_screen.dart:980` through the appearance builder show a brand row, unlabeled color swatches and a terse Style segmented control. Approved concept 24 supplies a live component preview, visible accent names and descriptive style choices. These omissions make the user's central customization feature harder to understand and miss a specifically approved screen composition. Preserve existing three-axis persistence and generated roles while implementing those presentation elements.

3. **P2 — Training omits the approved schedule overview.** `training-light.png`, `training-dark.png`, and `lib/screens/routines_tab.dart:627` show an active-plan hero with only name, day count and Open plan. Approved concept 02 includes a real weekly overview inside that hero. Restore a truthful schedule representation for weekday plans and an appropriately named cycle representation for rotating plans; do not imply completed workouts from planned days.

4. **P2 — Grouped-row icon containers do not receive the row press state.** `lib/widgets/house/nv_grouped_list.dart:73` tracks `_pressed`, but the leading child at approximately `:100` renders unchanged. Consumers such as `lib/screens/settings_hub.dart:36`, `lib/screens/routines_tab.dart:675` and the Progress rows pass `NvIconBadge` with its default `pressed: false`. The row changes shape, but its icon container cannot morph to a circle when the row is pressed, contrary to the explicit whole-app shape contract. Propagate the containing row's active state to its badge and verify press/release/reduced-motion behavior.

5. **P2 — Progress visualization ignores the selected time range.** `lib/screens/progress_tab.dart:76` computes range-specific totals, but the visualization at approximately `:140` always uses `NvWeekStrip`, which internally starts at the current Monday. Month and All time therefore retain an unexplained current-week visualization, and the approved range-aware training chart is absent. Render actual session aggregation for the chosen range, or explicitly label any separate current-week summary so it cannot masquerade as the selected range. Empty data must remain empty.

6. **P2 — App-authored count and weekday copy remains unfinished.** Captures show “1 days,” “1 completed sets,” “Session saved — 1 sets,” and the day header “SAT - Push.” Relevant source: `lib/screens/routines_tab.dart:263`, `:651`, `:683`; `lib/screens/today_tab.dart:693`, `:737`, `:1259`. Apply singular/plural formatting and normalize stored weekday tags at presentation time. Preserve user-entered names and stored data.

7. **Recapture requirement — Workout capture is stale relative to fixes.** `workout-light.png` contains a duplicate Add exercise control and outlined weight/repetition fields. Root explicitly reports the duplicate removed, `NvSetRow` converted to `NvField`, and the target-summary overflow changed to a Wrap in current source. Current `lib/widgets/house/nv_set_row.dart` confirms `NvField` usage. Do not treat those old pixels as an outstanding implementation request; replace the evidence after the final build.

## 4. Concrete correction list

- Make shared text buttons height-adaptive with complete readable labels at 360dp/1.5x; exercise the workout/footer/rest controls as well as Today.
- Build Appearance's approved live preview, visible accent names, and descriptive style rows using existing theme/controller/catalog behavior.
- Add the Training hero's actual schedule/cycle overview.
- Connect row-press state to shaped leading icon containers.
- Make Progress's training visualization truthful for Week, Month and All time without fabricating sample activity.
- Correct one-day/one-set grammar and displayed weekday capitalization without mutating saved names.
- Capture the corrected Today accessibility view, Appearance, Training, Progress, workout, finish/saved sequence, and at least representative corrected dark views from the installed final build. Inspect them before revising the verdict.

## 5. Remaining verification limits

The eighteen captures do not cover all forty approved screen/state concepts, full editors, food serving/custom-food flow, all settings sections, error/loading/disabled states, imported histories or all accent/style combinations. This report does not certify those surfaces. A screenshot shows layout, not a successful persistence transaction, Back behavior, TalkBack wording, motion quality or keyboard traversal. Press morph findings above derive from source; no motion recording was reviewed.

No physical Android hardware, tablet, IME-open stress capture, TalkBack listening pass, measured contrast matrix or reduced-motion device interaction was independently inspected. Root's serial test/build results and final confirmation captures were pending at review time. Offline behavior, schema retention, migrations, backup roundtrip and unit storage require their functional checks; display-unit source inspection alone is not proof of every flow. No new runtime networking or dependency change is requested by these corrections.
