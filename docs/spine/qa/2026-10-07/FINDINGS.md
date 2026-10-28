# Device QA — Today, 2026-10-07

Emulator `lockout_qa`, Android 16 / API 36, 1080×2400, density 420.
Release APK built from `8533267`. Appearance under test: light + teal (the
migrated theme on this device), which is itself useful — it is not the
identity accent, so nothing here is flattered by Rep lime.

**Verdict: FAIL on the first pass, PASS on the recheck.** Every finding below
was fixed and re-verified on the device, not just in tests — see "Recheck" at
the end.

**First pass:** Three blocking findings, two material ones. All five were
invisible to 796 passing tests.

## Blocking

### B1 — The hero's primary action is invisible

`NvButton`'s accent variant fills with `primaryContainer`. `NvHeroCard` fills
with `primaryContainer`. So "Start session" paints the same colour as the card
it sits on and reads as bare text, while the secondary "Custom session" is a
solid lavender pill. The primary action looks less actionable than the
secondary one.

Screenshot: `06-today-training-day.png`.

This is the branch's own failure mode in miniature: both colours are
house-correct tokens, correctly resolved, and the composition is still wrong.
No unit test can catch it, because every assertion about either widget passes.

### B2 — Set rows have no surface

Inside `NvGroupedList`, a set row paints only its completion tint. An
incomplete row is therefore transparent, so the stepper and tick controls
float on the page background with no row behind them, and the group reads as
one card followed by loose buttons rather than as a group.

Screenshots: `07-live-session.png` (rows 1-3 all transparent),
`08-rest-timer.png` (row 1 tinted after completion, row 2 still floating —
the contrast between them makes it plain).

### B3 — The text variant paints a fill

`NvButtonVariant.text` sets `background: colors.surface` rather than no fill,
so on any tinted surface it renders as a solid white pill. Visible on the rest
bar, where -15s / +15s / Skip look like three filled buttons on a lavender
bar. Section 8 says the text variant has no fill. The same bug makes
`outlined` and `danger` paint a surface fill they should not have.

Screenshot: `08-rest-timer.png`.

## Material

### M1 — The rest day says the same thing twice

The hero card says "Nothing scheduled / 0 sets / Custom session" and the empty
state directly below says "No session today / Nothing is scheduled. Train
off-plan or take the day. / Start a custom session". Two blocks, two buttons,
one meaning. The hero's big number is also `0`, which spends the screen's one
display-scale number on nothing.

Screenshot: `01-today-rest-day.png`.

### M2 — The day name is printed twice

On a training day the screen title is "Push" and the hero card's title is
"Push", one above the other.

Screenshot: `06-today-training-day.png`.

## Confirmed working

- The hero card's signature asymmetric outline: 36dp on three corners, 12dp
  bottom-left, verified by pixel crop (`01a-hero-bottom-left-corner.png`).
- The accent fill on the hero card — the defect the last device pass caught is
  gone.
- Sentence case throughout Today, including the "Quick actions" heading that
  replaced `'QUICK ACTIONS'`.
- Lobed markers read as register: 4 lobes on a rest day, 6 on a training day
  and on the live-session marker.
- Icon tiles are one consistent squircle; lobe count does not rotate.
- The status badge moves neutral → accent → (at completion) success, and the
  completed set row tints.
- The rest bar's wavy progress renders as a wave and animates.
- Grouped-list corner arithmetic: 26dp outer, small inner, 3dp gaps.

## Not a defect: the ANR

The app showed "lockout isn't responding" three times. Investigated rather
than dismissed:

- The single ANR trace (`/data/anr/anr_2026-10-07-18-47-51-096`) shows the
  main thread in `MessageQueue.nativePollOnce` — idle, waiting for messages.
  A hung app shows a deep Dart/Flutter stack; this has none.
- `system_server` logged "Long monitor contention" and "Slow dispatch took
  782ms" in the same window, and a bluetooth process native-crashed.
- Only one ANR trace was ever written. The later two dialogs were the same
  unresolved one being re-presented; no new trace, and `top` showed 392% idle.
- After `am force-stop` and a relaunch, every interaction responded normally.

Conclusion: a wedged input channel on a starved emulator, not an app hang.
Recorded here so the next person does not re-investigate it.

## Recheck — same emulator, APK rebuilt after the fixes

Screenshots `09-recheck-training-day.png` and `10-recheck-live-session.png`.

- **B1 fixed.** "Start session" is a dark filled pill against the mint card and
  now plainly reads as the primary action; "Custom session" stays tonal
  beside it. The accent variant inverts the pair — `onPrimaryContainer` fill,
  `primaryContainer` text — so it can never again match the card it sits on.
- **B2 fixed.** Set row 2 sits on `surfaceContainer` with its controls inside
  the group; row 1 shows the completion tint composited over that surface
  rather than instead of it.
- **B3 fixed.** -15s / +15s / Skip carry no fill on the rest bar.
- **M1 fixed.** A rest day shows the hero with no count and a single empty
  state carrying the one action.
- **M2 fixed.** The hero reads "Today's session" under a "Push" screen title.

**Verdict: PASS.** The gate reopens.

Left as cosmetic, not fixed here: the live-session header prints "SAT - Push"
with a hyphen where the rest of the app uses "·".
