# Workout burn tracking and routine builder

Date: 2026-11-15. Approved by the user through framing answers in session.

## Problem

1. A finished workout stores an estimated burn (`session_logs.kcal_burned`), but
   the rebuilt Today screen never shows it and "kcal left" ignores it. The Food
   screen ignores it too. From the user's side the burn is not counted.
2. Settings has no record of calorie burn.
3. Building a routine is spread across separate pages: create form, plan page,
   day page, day form, exercise form. Nothing shows the whole week at once.

## Mobbin references

- MyFitnessPal "Building a routine" and Hevy "Creating a routine": one builder page
  with the name on top, live estimated duration and calories, every exercise
  inline with its sets, and an add exercise action.
- Cal AI "Burned calories": "Your workout burned 211 Cals" with an edit pencil
  before logging.
- BitePal: calories left grows by workout burn.

## Decisions (user answers)

- Burn is added to kcal left on Today and Food. A Settings switch turns this off.
  Setting key `count_burn_in_budget`, default on, stored in `user_settings`.
- Settings > Nutrition shows burn totals: today, this week (Saturday to Friday,
  same as Progress), all time, workouts counted.
- The workout saved page shows "Your workout burned ~N kcal" with an edit action.
  Editing updates `kcal_burned` on that session only.
- Routine making uses the Hevy/MFP builder: after choosing a starting point, the
  user lands on one full-screen builder for the routine. It shows the name,
  scheduling, live estimates and every day as a card with its exercises inline.
  Sets change in place with steppers. Each day has add exercise and day settings.
  Opening a plan from Training opens the same builder.

## Constraints

No schema change, no new dependency, no network. Existing data preserved.
Estimates keep the `~` prefix. House catalog widgets only.

## Out of scope

Drag reordering, superset grouping, manual burn for days without a workout,
notification behaviour.
