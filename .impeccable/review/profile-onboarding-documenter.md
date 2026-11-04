# Profile onboarding — native design extraction

Date: 2026-11-04. Candidate: local `1.4.0+7`. Role: Impeccable documenter, not the final finish reviewer.

## Result and write boundary

Extended `DESIGN.md` and `.impeccable/design.json` with the implemented profile setup, unified editor, Units preferences, filled-label treatment and video recovery. Existing authored colors, type scale, spacing and shape tokens remain unchanged. No new visual direction, seed palette or web component system was introduced. The sidecar retains native role/state mappings rather than fabricated HTML/CSS specimens.

This report and the two design records are the only files written by this task. No app code, tests, configuration, approval records or release artifacts were changed. No tests or builds were run. Existing v1.3.1 artifact details and its bounded review verdict remain historical. The separate follow-up verdict is **Ship** in `.impeccable/review/profile-setup-finish-review.md`, within its stated onboarding/field scope.

Read final receipts: `.spine/profile-setup-final-tests.log` ends with 973 tests passed; `.spine/profile-setup-final-analysis.log` has zero errors/warnings and two baseline information notices. That latest analyzer record supersedes the review's earlier three-notice snapshot. The local candidate is `.spine/release/LOCKOUT-v1.4.0-preview.apk`; `.spine/profile-setup-signature.log` matches permanent certificate SHA-256 `5580479C76233D86FD10A50B557F3585127A16C0AF807CF7E2622420F3858C24`. No publication is asserted.

## Source and authority inspected

- `AGENTS.md`, `CODEX_HANDOVER.md`, local Spine configuration/progress, `PRODUCT.md`, and Impeccable `reference/document.md`.
- Approved `docs/design/onboarding-preview/screens.json` and `docs/spine/specs/2026-11-04-profile-onboarding.md`.
- `lib/screens/profile_setup_screen.dart`, `lib/services/profile_setup_service.dart`, `lib/widgets/house/nv_setup_header.dart`, and `lib/widgets/house/nv_expressive.dart`.
- Relevant Profile/Units routes in `lib/screens/settings_screen.dart`, and `lib/screens/exercise_video_screen.dart`.
- Existing `DESIGN.md` and `.impeccable/design.json`, including prior release and branding metadata.

## Actual native patterns recorded

- `NvSetupHeader`: 32dp primary-tinted approved monochrome logo, headline-small brand, label-large count, five equal 6dp-high progress segments with 6dp gaps/8dp corners. Primary fills current/prior steps; surface-container-highest fills later steps. Effects timing respects reduced motion; the progress announces one “Step n of 5.”
- Setup shell: SafeArea/Column, fixed header, Expanded independently scrolling body, intrinsic footer outside the scroll view. Horizontal margins remain 20dp. Footer Back/primary flex is 2:3 with a 12dp gap; keyboard insets leave actions above the IME and wrapped labels can grow controls.
- Five steps: About you, Measurements, Goal, Activity and Review. Shaped intro badges remain 72dp with display-small headings/body-large supporting copy. New-user fields are empty; no sex is silently selected. Restore backup is explicit and confirmation-gated; required setup has no Skip.
- Local raw-input drafts preserve progress separately from active profile calculations. Back/relaunch and review edits retain entered values. The completion service validates and checks its baseline before atomically writing active profile/settings/units/completion and any needed first/changed measurement, then clears drafts. It preserves history and converts completed values to kg/cm.
- The later Profile editor uses the same screen and starts at Review. Units contains preferences and an Edit profile entry instead of splitting actual height/weight input across settings.
- `NvField`: always-floating label inside the fill, using `UnderlineInputBorder`; rounded fill remains 16→24dp on focus. Rest has no stroke; focused underline is 2dp primary; error roles remain explicit. Floating-label style resolves from body-large, but Flutter's floating layout has nominal 12sp label text before user text scaling; no new global label token was invented.
- Video failure state requires `isForMainFrame == true`. Subresource/unknown-frame errors do not replace a usable WebView. Copy avoids inferring Wi-Fi state; explicit retry and external YouTube/link fallback remain available with caught launch failure. No automatic external launch or new dependency is implied.

## Native screenshot inspection

Independently opened all nine supplied captures under `.impeccable/review/final/`:

- `onboarding-early-about.png`
- `onboarding-early-measurements.png`
- `onboarding-early-goal.png`
- `onboarding-early-activity.png`
- `onboarding-early-review.png`
- `onboarding-stress-review.png`
- `onboarding-stress-review-bottom.png`
- `profile-editor-dark-stress.png`
- `profile-measurements-dark-stress-keyboard.png`

They show the actual five-segment/brand header, inside-fill labels, connected review rows and reachable persistent actions across ordinary light views, enlarged review text, dark editing and keyboard-constrained measurements. The two stress review positions show that body content can scroll independently of header/footer. The dark measurement capture shows the active underline and a wrapped Review changes action above the keyboard. Sample entered values in these captures are evidence of presentation only, not defaults for new users.

These are static supplied emulator images. This documenter did not independently drive the device, listen to TalkBack, record motion, complete a persistence/restore transaction, inspect all error states, test actual external video handlers or certify physical hardware/tablet behavior. Source inspection describes intended runtime paths; screenshots alone do not establish their functional success. The follow-up review additionally records completion/restart/settings-return captures and preserves its representative-phone scope. Video recovery is source/test-reviewed there; no final video-error screenshot or successful external playback is independently certified.

## Pre-existing drift left unchanged

1. An initially observed Review wording discrepancy was resolved by the controller's specification clarification before this extraction finished. The current spec says Review shows entered details/direct edits, with calculated nutrition targets and existing planner explanations after completion. This now matches `_review()`; it is not an open defect and no invented pre-save values were added. This documenter did not edit the spec or implementation.
2. Existing `DESIGN.md` includes a `## Android identity` section beyond the document reference's eight canonical sections. Its approved branding/signing content and section placement were preserved; this extraction did not restructure that incumbent section.
3. The historical v1.3.1 verification/artifact record remains in the design files. A separate `1.4.0+7` note records its actual follow-up review and final receipts instead of extending the old verdict. No candidate APK hash or release/publication status was invented.
4. Historical handover/Spine progress still contains earlier branch and pre-approval wording. The latest explicit approval and current source govern this extraction. Those controller-owned records were not edited.

## Validation

The updated JSON sidecar parsed successfully. Frontmatter primitives remain the incumbent native values; new component-specific geometry/state details live in prose and sidecar extensions. Retain this extraction alongside the bounded follow-up review, final functional receipts and local artifact provenance. The Review wording discrepancy is resolved; the other historical document drift above was preserved without expanding this task's scope.
