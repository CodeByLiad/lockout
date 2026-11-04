# Profile setup follow-up verification

Release: **1.4.0+7**, 2026-11-04. Publication and GitHub README updates explicitly
requested after local review. Five onboarding concepts and required setup were
approved before implementation. Release: https://github.com/CodeByLiad/lockout/releases/tag/v1.4.0

## Behavior delivered

- Required About you, Measurements, Goal, Activity and Review pages. New values
  are blank, existing values prefill, Back retains inputs, interrupted drafts resume.
- Drafts are isolated from active calculations. Finish atomically saves profile,
  completion and a real weigh-in; retry and unchanged edits avoid duplicates.
  Changed weights append history. Baseline checks reject stale drafts after restore.
- Complete legacy profiles enter directly; incomplete profiles finish missing fields.
  Saved height alone is preserved, while the database's untouched height seed is
  not presented as a new user's real measurement.
- Restore backup is available before setup. Profile & goals later opens the same
  editor. Units contains preferences; nutrition settings retain calculated targets,
  manual fallback and the optional Food destination.
- Exercise labels remain inside filled surfaces at rest and focus. Video errors
  only replace the page for confirmed main-frame failures; resource failures no
  longer falsely replace a working page. Explicit external opening has safe retry.
- Existing dependencies, schema version 4, local storage and planner formulas remain.
  Notification channel importance is unchanged; popup behavior is a separate issue.

## Automated evidence

All **973 tests passed serially** with the absolute Flutter SDK path and
`--concurrency=1`: `.spine/profile-setup-final-tests.log`.
The full suite includes backup round-trip and migration checks. New regressions
exercise gating, draft recovery, kg/lb and height conversion, save rollback/retry,
restore, legacy migration, history preservation and all five pages at 360dp with
1.5x text and a 300dp keyboard inset. Field bounds and video fallback have focused
tests. The initial full run caught NumericGuard contract reuse; corrected and
included in the final full pass.

Analysis: zero errors, zero warnings, two pre-existing test information notices:
`.spine/profile-setup-final-analysis.log`.

## Native inspection

Early debug device pass used lockout_qa API 36 with existing data retained.
Actual captures are in `.impeccable/review/final/`:

- `onboarding-early-about.png`, `onboarding-early-measurements.png`,
  `onboarding-early-goal.png`, `onboarding-early-activity.png`,
  `onboarding-early-review.png`: all five pages at normal density.
- `onboarding-stress-review.png` and `onboarding-stress-review-bottom.png`:
  360dp / 1.5x text, readable review and reachable fixed Finish action.
- `profile-editor-dark-stress.png` and
  `profile-measurements-dark-stress-keyboard.png`: dark theme, 360dp / 1.5x text,
  real keyboard, readable field and visible Back / Review changes actions.
- `onboarding-completed-today.png`, `onboarding-restart-completed.png`,
  `profile-save-returned-settings.png`: completion, direct entry after restart,
  and unchanged profile save returning to Settings.
- `reported-fields-fixed.png`: exercise fields with labels inside the fill.

Independent Impeccable review returned **ship** within the inspected scope:
`.impeccable/review/profile-setup-finish-review.md`. It does not certify every app
state, physical devices or TalkBack. The video recovery is covered by source and
regression tests; the user's particular network/WebView failure is not reproduced.

## Signed local artifact

`.spine/release/LOCKOUT-v1.4.0.apk`, 57,529,262 bytes (identical to the tested preview).
SHA-256: `A521FF4F88D65614DB628A733FDE2F6799506DF070D3891C13FBC2C779E46F8B`.
Certificate SHA-256:
`5580479C76233D86FD10A50B557F3585127A16C0AF807CF7E2622420F3858C24`.
This matches the permanent v1.3.1 release key. Private credentials remain outside
source control. Build: `.spine/profile-setup-release-build.log`; signature:
`.spine/profile-setup-signature.log`. Flutter reports future Android build-tool
support notices; the release build succeeds without new dependencies.

The exact signed APK was installed and launched on an isolated read-only API 36
emulator replica. `onboarding-signed-release-fresh.png` shows the fresh first step
with blank age and unselected sex, and the app gated before setup. The original
QA emulator disk/data was preserved. No Flutter exceptions appeared in
`.spine/profile-setup-release-runtime.log` during this launch smoke check.

v1.3.1 permanent-key users can update in place. Earlier differently signed builds
require their existing backup/reinstall/restore procedure.
