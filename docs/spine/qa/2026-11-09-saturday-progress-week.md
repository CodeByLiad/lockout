# Saturday-first Progress week

The user clarified that their reporting week starts Saturday. Progress now filters
completed workouts from Saturday midnight up to, but excluding, the next Saturday.
Its chart runs Sat, Sun, Mon, Tue, Wed, Thu, Fri. An explicit date range appears
below the count, including both years when needed. Month and All time retain their
existing behavior. Stored workout dates, routines and history are unchanged.

For Monday 9 November 2026, the selected week is 7–13 November: a completed workout
dated Sunday 8 November counts. Friday 6 November and Saturday 14 November do not.

## Evidence

- Four behavioral regressions failed before the correction:
  `.spine/saturday-week-behavior-red.log`.
- All 50 targeted tests passed serially:
  `.spine/saturday-week-final-tests.log`. These cover Saturday/Friday boundaries,
  the next Saturday reset, a week crossing New Year, chart order/counts, unchanged
  month totals and a 360dp/1.5x date-label layout, plus existing chart/contract tests.
- Analysis: no errors or warnings, two pre-existing test information notices:
  `.spine/saturday-week-analysis.log`.
- Early API 36 native inspection uses the real ProgressTab with a fixed Monday
  clock and one Sunday example workout in an isolated in-memory database. It never
  opens the existing QA database. Screens in `.impeccable/review/final/`:
  `saturday-week-normal.png`, `saturday-week-large.png`,
  `saturday-week-large-chart-end.png`. These show one workout in 7–13 November,
  Saturday-first buckets and Friday reachable by horizontal scrolling at 360dp
  with 1.5x text. These are test fixtures, not captures of the user's private data.
- No Flutter exceptions appeared in `.spine/saturday-week-runtime.log` during this
  check. Density/font scale returned to normal. The normal debug app entry is
  restored after the temporary QA harness.

This correction targets v1.4.1+8; the user requested GitHub publication after local
review. It is not included in v1.4.0. The native check does not claim physical-device coverage,
TalkBack validation, or changes to the separate Training schedule's weekday order.

## Release artifact

`LOCKOUT-v1.4.1.apk` is version 1.4.1, Android version code 8, 57,529,262 bytes.
SHA-256: `5eba225435893efcccc0388b9d1fbe294c4fc27eaceb9a6846ee9dc4ea6cb373`.
The verified certificate matches the permanent v1.4.0/v1.3.1 certificate:
`5580479C76233D86FD10A50B557F3585127A16C0AF807CF7E2622420F3858C24`.
The release build succeeds (`.spine/release-v1.4.1-build.log`); signature receipt:
`.spine/release-v1.4.1-signature.log`. Existing Android toolchain support notices
remain unchanged. No signing credentials are committed.

Publication target: https://github.com/CodeByLiad/lockout/releases/tag/v1.4.1

The complete v1.4.1 regression suite passed **978 tests serially**:
`.spine/release-v1.4.1-tests.log`. This supersedes the earlier targeted-only
functional receipt. The exact signed APK updated v1.4.0 in place on an isolated
read-only API 36 emulator replica; its saved setup step, age and sex selection
survived. Evidence: `.spine/v1.4.0-draft-saved.xml`,
`.spine/v1.4.1-draft-saved.xml`, `.spine/v1.4.1-age-retained.xml`,
`.impeccable/review/final/v1.4.1-upgrade-draft-retained.png`.
The first input attempt was not confirmed before installation; the repeated
check verified the entered value and saved step before updating. This was a test
input timing issue, not evidence of profile loss. The original QA data was kept
on its separate emulator disk throughout.
