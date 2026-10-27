# LOCKOUT

An offline-first strength training tracker for Android, built with Flutter.

Routines, workout logs, nutrition and body metrics live in a local SQLite database on your device. No account, no analytics, no ads, no server. The network is used for exactly one thing: streaming exercise form videos from YouTube when you tap **Watch**.

Interface follows the Nuvetrix App Design System — Material 3 Expressive, shape as a state, spring motion and Bricolage Grotesque/Figtree/JetBrains Mono bundled with the app — with a brightness and an accent the user picks independently.

---

## Features

### Routines
- Build a training week and pin each day to a weekday, or run a rotating cycle that advances one slot per calendar day.
- Four starter splits — Push/Pull/Legs, Upper/Lower, Full Body 3x, 5-Day Body Part — each arriving pre-loaded with warm-ups, numbered exercises and a conditioning finisher.
- Every day carries a focus subtitle, an optional caution note, and can be marked as an explicit rest day.
- Tap any exercise to edit sets, rep range, working weight, rest interval and cues.

### Exercise catalog
- **175 exercises** across 13 muscle groups, searchable by name, muscle or equipment.
- Each resolves to a YouTube search biased toward 3D / animated form demonstrations, opened in an in-app WebView. Queries are used instead of hardcoded video IDs so links never rot; pin a specific URL per exercise if you prefer.
- Anything missing can be added as a custom exercise.

### Live sessions
- Today's workout is resolved from the active routine — no manual selection.
- Per-set weight and rep steppers, a running volume total, session elapsed timer, and a rest timer that starts automatically when a set is logged.
- The header shows your last performance for that exercise, pulled from history.
- Finishing archives the session and every completed set. Nothing is written for sets you did not do.

### Nutrition
- **431 foods** across 28 categories — Western, Italian, Chinese, Japanese, Korean, Thai & SE Asian, Mexican, Middle Eastern, Mediterranean, South Asian, Bengali, and the usual building blocks.
- Every entry lists the ingredients its figures assume, so you can see what you are agreeing to before logging it. Search matches ingredients too.
- Serving-size stepper scales macros; every field stays editable, because a catalog figure is a starting point rather than a fact.
- Entries group under Breakfast / Lunch / Dinner / Snacks with per-meal subtotals.

### Body and goals
- BMI computed from weight and the height stored in Settings, with the arithmetic shown on screen. Waist is tracked separately and plays no part in it.
- Daily calorie target is **calculated, not guessed**: Mifflin–St Jeor BMR → activity multiplier → TDEE → the deficit or surplus your goal and timeframe require. Macros follow (protein prioritised in a deficit, fat at 25% of intake, carbs take the remainder).
- Safety rails: pace is capped at 1%/week loss and 0.5%/week gain, intake never drops below 1500 kcal (male) or 1200 kcal (female). When a goal is clamped the app says so and gives a realistic timeframe instead of silently rewriting it.
- Recommends a training split from your goal direction and available days, with the reasoning shown, and can create it in one tap.

### Accountability
- Daily training reminder at a time you choose, naming the day and exercise count actually scheduled.
- Optional 21:00 streak warning that reads your real streak.
- Permission is requested before the toggle flips — deny it and the switch refuses rather than claiming reminders are on.
- Scheduled inexactly on purpose: exact alarms require the restricted `SCHEDULE_EXACT_ALARM` grant, which a training nudge does not justify.

### Backup
- Export writes all ten tables — routines, days, warm-ups, exercises, finishers, sessions, sets, meals, body entries and settings — to a single JSON file.
- Import validates the entire document before writing a single row, then restores inside one transaction. A malformed file leaves your data untouched.

### Themes
Lockout follows the Nuvetrix App Design System, vendored at `docs/design/nuvetrix-app-design-system.md`. Appearance has two independent axes, applied instantly and persisted:

| Brightness | Accent |
|---|---|
| System | Rep lime (default) |
| Light | Violet, Teal |
| Dark | Coral, Steel |

Rep lime `#C2EE7B` is Lockout's registered identity accent. The accent is for emphasis, so in light mode it fills hero cards, the FAB and badges while filled buttons stay the house indigo; in dark mode it carries `primary` as well.

Every foreground role is contrast-checked against the surface it sits on, across all ten brightness-and-accent combinations, and each brightness carries an eight-colour category ramp plus semantic success, warning, danger and rest-day tones. The six colour schemes earlier versions shipped, and the palette keys before them, both migrate onto the nearest accent at their original brightness — so an existing install never wakes up light after choosing dark.

There is no wallpaper-derived (Material You) colour. The house system reserves colour identity for the app, so that every Nuvetrix app looks like one family.

Typefaces are bundled rather than downloaded, so the app renders correctly with no network: Bricolage Grotesque for display, Figtree for body text, and JetBrains Mono for figures that must line up in a column.

`test/expressive_contract_test.dart` asserts the app against the vendored house document — palette hexes, the type scale, the corner scale and the signature hero outline — so drift from the family standard fails a test rather than a review.

---

## Build

Requires the Flutter SDK (Dart `^3.11.4`) and the Android SDK.

```bash
flutter pub get
flutter run                    # debug on a connected device or emulator
flutter build apk --release    # release APK
```

The release APK lands at `build/app/outputs/flutter-apk/app-release.apk`. Prebuilt APKs are published on the [Releases](../../releases) page.

`flutter_local_notifications` requires core library desugaring, already configured in `android/app/build.gradle.kts`.

---

## Tests

```bash
flutter test
```

887 tests covering unit conversion and BMI, BMR/TDEE and goal clamping, streak edge cases, weekday resolution, catalog integrity and cuisine balance, WCAG contrast across all ten brightness-and-accent combinations, the Material 3 Expressive theme and its widgets, the lobed `CookieBorder` geometry, the two-axis theme migration, and a full backup export/import round-trip against a real SQLite database via `sqflite_common_ffi` — including six classes of malformed input that must be rejected without touching existing data.

---

## Architecture

```
lib/
├── data/           # Static catalogs: exercises, foods, routine templates
├── models/         # Entities and their SQLite row mapping
├── screens/        # One file per tab, plus settings and the video view
├── services/       # Database, scheduling, nutrition/training planners, backup, notifications
├── theme/          # Palette, accents, motion, shape and the Material 3 Expressive theme
└── widgets/        # Shared components
```

Colour, type and shape resolve through `Theme.of(context)`, `ColorScheme` and the `LockoutSemantics` theme extension rather than through compile-time constants, so a scheme change repaints the whole app without touching call sites. Literal colours live only in `lib/theme/palette.dart` and `lib/theme/accents.dart`, and a test fails the build if one appears anywhere else.

The database migrates in place across schema versions; existing installs keep their data.

---

## Permissions

| Permission | Why |
|---|---|
| `INTERNET` | Streaming exercise form videos when you tap Watch. Nothing else. |
| `POST_NOTIFICATIONS` | Local training reminders, scheduled on-device from local data. |
| `RECEIVE_BOOT_COMPLETED` | Re-arming those reminders after a restart. |

No data leaves the device. Backups are shared only when you explicitly export one.

---

## License

GPL-3.0-or-later. Published by Jinatra Ltd.
