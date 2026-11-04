disposition: ship

## persistence

Pass within this follow-up's scope. PRODUCT.md and DESIGN.md describe the existing native Material 3 Expressive world. Five approved onboarding concepts and their approval/interpretation record exist in `docs/design/onboarding-preview/screens.json` (“Approve and implement,” 2026-11-04). This review extends the existing world; no new visual identity is being substituted. Native Flutter screenshots are the evidence; web comp-diff/state and HTML/CSS detector results are not claimed.

Source reviewed: `profile_setup_screen.dart`, `profile_setup_service.dart`, `nv_setup_header.dart`, relevant main/settings routing and Units, `exercise_video_screen.dart`, and NvField labels in `nv_expressive.dart`; focused profile and exercise-video tests were sampled. Drafts remain separate from the active profile; completion activates settings and initial measurement in one transaction. Unit conversion preserves kilogram/centimetre storage. Review edits retain context and completion does not require invented sample values. Existing valid profiles bypass setup. Source includes stale-baseline rejection and saved-height migration handling.

Read `.spine/profile-setup-final-tests.log` through **973: All tests passed!** The final `.spine/profile-setup-final-analysis.log` has two pre-existing test information notices and no errors/warnings. The setup brace-style notice was corrected before the final 973-test run. No tests or builds were executed by this reviewer. Build signing and APK identity are outside this review.

## fidelity

| Element | Status | Evidence |
|---|---|---|
| TYPE | Match | Bundled expressive display headings and readable Figtree body preserve the approved hierarchy and lettering character. |
| MATERIAL | Match | Flat native filled fields, shaped badges, connected rows and tonal actions; preview-image shading is not reproduced as decorative fake material. The preview notes explicitly require real generated roles without gradients. |
| GROUND | Match | Theme-generated pale green light surfaces and corresponding dark scheme preserve the existing world; colors remain driven by the selected accent. |
| Brand/progress | Match | Angled dumbbell, Lockout heading, explicit step count and five-segment progress retain the approved identity and actual step state. |
| Five-step task order | Match | About, measurements, goal, activity, review appear in the approved order, with the relevant inputs, review edits, completion and restore action. |
| Field labels | Match | Visible inside the filled top region, with values beneath; repaired exercise capture and dark focused measurement show labels no longer straddling an outline. |
| Back/continue/finish | Adaptation | A single persistent bottom action group replaces duplicated upper Back examples; it preserves the approved Back/Continue capability and avoids duplicate navigation. Footer grows at enlarged text and remains above the real IME. |
| Intro placement/density | Adaptation | Badge and heading stack in the shared native composition instead of alternating side-by-side generated arrangements. Existing catalog/type scale, predictable single-column reading and enlarged-text accessibility justify the reflow. |
| Review groups | Match | About, goal and activity have truthful values and Edit actions. The scrollable native review exposes its lower groups rather than reducing text to fit the entire generated board in one viewport. |
| Sample values | Adaptation | New fields begin empty or prefill actual existing data; approved preview notes explicitly mark pictured values illustrative. Direction follows current/target weights as approved. |

Independently viewed five approved concept PNGs and these actual device captures in `.impeccable/review/final/`: `onboarding-early-about`, `onboarding-early-measurements`, `onboarding-early-goal`, `onboarding-early-activity`, `onboarding-early-review`, `reported-fields-fixed`, `onboarding-stress-review`, `onboarding-stress-review-bottom`, `onboarding-completed-today`, `onboarding-restart-completed`, `profile-editor-dark-stress`, `profile-measurements-dark-stress-keyboard`, `profile-save-returned-settings` (all PNG). All are valid nonblank captures of their named surfaces. Root confirms stress settings: density 480 yielding 360dp and font scale 1.5. Dark measurement capture contains a real numeric IME, legible focused label/value, and complete Review changes button above it. Review bottom capture demonstrates accessible lower groups. Restart capture is settled Today, not a splash.

Exercise-video error handling is source/test-reviewed: main-frame failures offer retry, external opening and Back; subresource failures do not replace usable content. No final native video-error screenshot was supplied, so the verdict does not claim independent visual certification of that error surface or successful external playback.

## ceiling

Reached for the bounded onboarding/field follow-up with supplied native phone evidence. No material actionable defect found. This is an independent delegated review, not an inline substitution. Physical hardware, tablet behavior, TalkBack listening, measured contrast and animation smoothness were not independently tested. All five step layouts have narrow/keyboard regression coverage; device stress captures sample Review and measurements, not every step/theme combination. This report does not reopen or certify the entire forty-screen overhaul.

## material_fixes

None. No source correction or further visual-polish loop is requested by this bounded pass.

## keep

Preserve the user-seeded expressive world, inside-field labels, complete growing actions, draft-preserving Back, actual data prefill and atomic activation of the completed profile and first measurement.
