# Bounded native finish confirmation — 2026-11-04

## 1. Disposition

**Fix and recapture one bounded item.** Six original findings are resolved. Finding 5's data aggregation is resolved, but its new weekly chart leaves Sunday partly offscreen at normal 411dp width without a clear scrolling affordance. Treat that as the remaining material correction within the existing chart finding. No fresh whole-app defect hunt was performed. No rebuild of the design direction is requested.

## 2. Scoped evidence

Read the original finish-review.md and current source for the seven findings: shared buttons, grouped rows/press inheritance, expressive badges and fields, Appearance, Training, Progress/activity chart, Today completion copy and day presentation. Read the end of `.spine/overhaul-verified-tests.log`: 934 passed. Read `.spine/overhaul-verified-analysis-final.log`: two test information notices, zero warnings/errors. Examined the focused review test's actual badge press-progress assertion and range-aggregation assertion. Root reports these tests and three recovery regressions were red before their fixes. This reviewer did not execute tests or builds.

Independently viewed the installed-release screenshots under `.impeccable/review/final/`: phone-360-large, appearance-top-light, appearance-styles-light, appearance-top-dark, training-light, training-dark, progress-week-light, progress-month-light, progress-all-light, progress-dark, workout-light, workout-keyboard, rest-light, finish-light, saved-light, day-light, measurement-keyboard-360-large (PNG). Root supplies provenance: API 36 emulator, 411dp/1.0 text normally; named 360 stress captures use 360dp/1.5x. These are native captures, not browser renders. Other final captures were inspected by root, not independently claimed here.

Root reports release APK 56,986,036 bytes, SHA256 `A2ABBA34BC8AAAC01F01CE1B80BBD876B430581F6135AE5C7F0949E531376B10`, installed with replacement preserving data; runtime log has no Flutter errors. Build/hash/install provenance is supplied by root rather than independently recomputed by this reviewer.

## 3. Original finding status

1. **Resolved — Accessible button label.** `nv_button.dart` now uses a minimum height and unrestricted wrapping text. `phone-360-large.png` displays the complete “Start a custom workout” over two lines. The measurement keyboard stress capture also displays its complete Save action above the IME.

2. **Resolved — Appearance composition.** Current Appearance source and light/dark captures provide a real theme-role component preview, visibly named five accents and three described style rows with explicit selection. The preview uses the existing generated roles, preserving the user's chosen scheme rather than literal concept colors. Root additionally supplies actual tonal/vibrant/teal change captures.

3. **Resolved — Training schedule.** Light/dark captures display the active plan's seven-day overview. Source excludes rest days from planned-day markers and separately labels rotating plans as a Training cycle. Planned dumbbell markers do not falsely claim completion.

4. **Resolved — Grouped badge morph.** `nv_grouped_list.dart` wraps the leading child in `NvPressState(active: _pressed || _focused)`; `NvIconBadge` consumes that inherited state. The focused regression asserts actual shape progress reaches 1 while pressed, and the passing serial suite includes it. Static images do not independently certify motion timing or perceived smoothness.

5. **Partially resolved/open — Progress chart.** Current source and three range captures show daily, week-bucket and year aggregation respectively. Counts and labels follow the selected period, closing the original misleading range issue. However, `progress-week-light.png` cuts Sunday at the right edge even at 411dp/1.0. The chart's minimum 52dp columns create unnecessary horizontal scrolling for seven noninteractive bars. This is a material completeness/readability issue for the approved week overview, not a request to shrink touch targets. Month and All time fit in their captures.

6. **Resolved — Singular and weekday copy.** Training says “1 day.” Finish and saved views say “1 completed set,” snackbar says “1 set,” and day title is “Sat · Push.” Source formats these display strings without modifying stored names. The completed device example shows one 60 kg × 10 set and 600 kg volume, with untouched sets excluded from completion.

7. **Resolved — Stale workout evidence.** New release captures replace the duplicate-action/outlined-field evidence: workout has one Add exercise footer control and filled set inputs. IME capture shows the focused field and numeric keyboard. Rest/finish/saved captures document the updated sequence. The target-summary source is wrapping rather than the old fixed row.

The supplementary recovery distinction is consistent with the inspected Today accessibility capture (“Recovery day,” View training plan, optional custom workout). Root reports explicit no-routine/empty-plan/recovery/scheduled-training regression coverage and stale-rest-start protection; this bounded review does not expand it into certification of every training state.

## 4. Remaining concrete correction

Make all seven week columns fully readable at ordinary phone width using available width and actual label requirements. Noninteractive bars do not need a 52dp touch-target minimum. Retain horizontal scrolling when enlarged labels genuinely require it, with an understandable affordance. Recapture Week on the installed corrected build at normal 411dp and the required 360dp/1.5x case; preserve readable labels rather than scaling text down. Then close finding 5 in this confirmation. No other correction is requested by this bounded pass.

## 5. Verification limits

This is confirmation of seven findings, not proof of all forty approved concepts or every editor/error/loading/disabled state. No physical device, tablet, TalkBack listening session, motion recording or contrast matrix was independently reviewed. Functional evidence is the cited root-run test suite and supplied device sequence; screenshots alone do not certify all persistence, offline, backup/migration or navigation paths. Several Progress captures precede the new 600 kg device workout, so their earlier 0 kg value is not evidence of lost saved volume. Final release evidence must be tied to any subsequent chart correction rather than reusing the prior APK identity without rebuilding.
