# First-launch profile setup

Status: required first-time setup and all five previews approved on 2026-11-04;
implemented and verified in local candidate v1.4.0+7.
User direction, 2026-11-04: onboarding pages collect age, gender, weight, height,
target weight and the other details needed by the app. This addresses the
confusing separation between height entry in Units and current weight elsewhere.

## Proposed flow

1. **About you:** age and sex used by the existing calorie equation. Explain the
   calculation purpose plainly; do not silently select a sex for a new user.
2. **Your measurements:** current body weight and height together, with kg/lb and
   cm/feet-and-inches choices. New-user values are empty, not invented defaults.
3. **Your goal:** target weight and timeframe in weeks. Weight changes and
   maintenance derive from the entered current/target values.
4. **Your activity:** activity level and planned training days per week. Explain
   activity choices; actual routine creation remains a next action after setup.
5. **Review:** all entered details and direct edit actions. After completion,
   nutrition targets use the existing planner and its limiting/explanation behavior.
   Finish setup saves once and opens Today with the user's actual profile.

Each page has visible progress, Back and Continue, uses the approved Material 3
Expressive/Nv vocabulary, and supports keyboards, large text and reduced motion.
Restore an existing backup is available before entering a new profile. No
account, internet or early notification-permission request is introduced.

## Persistence and existing users

- Reuse age, sex, height_cm, target_weight_kg, goal_weeks, activity_level,
  training_days_per_week and existing unit preferences. Current weight belongs
  in body_logs so Today, Progress, BMI and nutrition use one consistent source.
- Valid complete profile details gate first launch, including legacy profiles;
  completion and first measurement
  save atomically. Retry/relaunch must not duplicate the initial weigh-in.
- Keep draft inputs when navigating Back. Interrupted setup resumes rather than
  discarding all entries. Drafts do not become active calculation inputs early.
- Prefill existing users from valid stored values and latest real measurement;
  preserve history and avoid duplicate body entries. Missing fields are clearly
  requested. A restored complete profile must not be overwritten by stale drafts.
- Load/save failures remain visible with Retry and entered values retained.
- Keep one later profile/details editor; Units describes unit preferences rather
  than hiding half of the user's body/profile entry there.
- No new dependencies, destructive migrations, schema change or planner formula.

## Confirmed first-launch behavior

The user chose "Require first-time setup (recommended)" on 2026-11-04.
Essential profile setup is required before first use, with Back and Restore
backup available. No Skip action bypasses completion. Existing users have valid
saved values prefilled and complete missing details without losing history.

## Verification plan

Test first and run serially: new-install gating; validated kg/lb and height input;
step Back retention; interrupted draft recovery; transactional completion;
save-failure retry; no duplicate measurement; complete/incomplete existing-user
migration; restore behavior; one consistent goal snapshot; profile editing.
Run the first device pass early, including keyboard layout and 360dp/1.5x text.
Present new onboarding screen previews before implementing the visual design.
The five separate concepts are now in `docs/design/onboarding-preview/`, with
`index.html` as the gallery and `screens.json` recording exact prompts and the
visual-approval record. The user chose "Approve and implement" before onboarding
app code was written.
The user subsequently requested committing, pushing, publishing the v1.4.0 APK
and updating the GitHub README on 2026-11-04. Publication is authorized.

The notification banner diagnosis is separate: existing reminders request
default channel importance. No reminder behavior is silently changed by setup.
