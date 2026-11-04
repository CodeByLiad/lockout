# Whole-app overhaul verification

Date: 2026-11-04. Branch: `fix/workout-tab-dead-ends`. Changes remain uncommitted.

## Delivered scope

The forty approved concepts informed a native Material 3 Expressive rebuild of
Today, Training and routine/day/exercise editors, live workouts and completion,
Progress and history, Food and its entry flow, body measurements and goals,
Settings and its focused routes, About and the explicit video viewer.
Four task destinations replace the old permanent five-tab arrangement.

Screens compose the Nv house catalog. The chosen accent, brightness and
tonal/vibrant/expressive style generate the app's roles. Shaped icon badges,
press/focus morphs, filled inputs, connected lists and adaptive labels form the
shared components. Bundled fonts, reduced motion and sentence case remain.
The implementation preserves local data, kilogram storage, schema version 4,
theme-key migration and the existing dependencies. Explicit Watch and source
link actions remain external destinations; no background networking was added.

## Regression evidence

Tests were written before their corresponding implementation and run serially
with the required Flutter SDK. New coverage exercises navigation and session
minimize/resume, empty/custom routines, validation and atomic exercise insertion,
food date/portion/edit context, body units, completed-set-only saves, save-failure
retention, history restoration, real period aggregation, recovery states,
adaptive labels and leading-badge morphs. Existing backup, migration, contrast,
theme and storage checks remain in the serial suite.

The last corrections have explicit red/green logs:
`.spine/final-corrections-red.log` and `.spine/final-corrections-green.log`.
They prove that seven week columns fit ordinary phone width, enlarged labels
remain scrollable, and waiting on the finish review preserves its displayed
duration and completion date even across midnight.

Final complete suite: **937 passed**, serial `--concurrency=1`, in
`.spine/overhaul-final-tests.log`. Final analysis:
**0 errors, 0 warnings, 2 pre-existing test information notices** in
`.spine/overhaul-final-analysis.log`. The suite includes all 32 backup-roundtrip
tests. The earlier 1056-test total belongs to the superseded UI contracts;
implementation-specific screen expectations were replaced for the approved
flows while retaining storage/service coverage.

## Reviewable APK

`build/app/outputs/flutter-apk/app-release.apk`, version `1.2.1+4`.
Built with `C:\src\flutter\bin\flutter.bat build apk --release --no-pub`.

- Size: **57,051,572 bytes**.
- SHA-256: `5BE97C81CCC79971CF07EB96744AB63AE0DA98BC3418B353969FB8DB33DE22DD`.
- Build log: `.spine/overhaul-final-apk.log`.
- Successfully installed using replacement, preserving emulator app data.

The emulator's stale transport required a cold boot before the final successful
installation. Its package is `com.jinatra.lockout`. No uninstall or data clear
was performed. The final runtime log `.spine/overhaul-final-runtime.log` contains
engine initialization with no Flutter exceptions.

## Native evidence and limits

Early installed-device evidence is in `early-today.png` and
`.impeccable/review/`. Confirmation captures are in
`.impeccable/review/final/`. The device is the `lockout_qa` API 36 emulator;
ordinary captures use 411dp and 1.0 text scale. The named `360-large` captures
use 360dp and 1.5x text, including a measurement form with its keyboard open.
The final APK's corrected chart is captured in `progress-week-final.png`,
`progress-week-360-large-final.png` and
`progress-week-360-large-scrolled-final.png`: all seven days fit at ordinary
width; enlarged labels retain their size and Sunday is reachable by scrolling.
Other confirmation captures precede only the final chart-width and reviewed
completion-time corrections. Display density and text scale were restored.

Light and dark themes, named accents/style changes, actual schedule and chart
ranges, set entry, rest, finish and saved screens were inspected. A native
workout saved exactly one completed 60 kg × 10 set with 600 kg total volume.
Untouched sets were excluded. These are emulator QA records, not seeded app data.

Independent review records are `.impeccable/review/finish-review.md`,
`.impeccable/review/finish-confirmation.md` and
`.impeccable/review/finish-final-disposition.md`. The final disposition is
**Ship within reviewed scope**: all seven original findings are resolved,
including the fresh normal/large-text chart captures. The final disposition
supersedes the earlier open findings while preserving their provenance.
Their scope is representative
concept comparison and confirmation of seven specific findings; they do not
certify every one of the forty states. No physical device, TalkBack listening
session, tablet or motion recording was certified. Concept images are review
documents rather than shipped raster assets. The asset provenance scan found
zero new rasters requiring prompts. `DESIGN.md` and `.impeccable/design.json`
record the actual native design system.

No commit, push, PR or release publication was performed.
