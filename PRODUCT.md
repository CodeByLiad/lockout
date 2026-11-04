# Lockout

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

People who track strength training, meals and body measurements on their phone.
The primary usage scene is logging sets during training, often one-handed.

## Product purpose

Plan training, record completed sets and review progress without an account or
server. Daily food and body tracking support the training plan.

## Capabilities and constraints

Flutter and SQLite, bundled fonts and exercise/food catalogs. No new package
dependencies. Preserve existing routines, logs, settings, backups and migrations.
All features work locally. Only an explicit Watch action opens a YouTube video.
User-selected accent generates the whole light/dark color scheme; scheme styles
remain tonal, vibrant and expressive. Respect reduced motion and large text.

## Brand commitments

Full Material 3 Expressive throughout, sentence case, bundled Bricolage Grotesque
and Figtree, distinct shaped icon containers with press morphs. The user approved
the 40 screen/state concepts in docs/design/overhaul-preview/ on 2026-11-03 and
said "Proceed then". Navigation changes are approved. The four task destinations
are Today, Training, Progress and optional Food; settings is a focused route.

## Evidence on hand

Existing local services/models and tests; Mobbin reference links in the overhaul
proposal; 40 generated concepts with exact prompts and original images. Preview
numbers and calendar labels are illustrative, not user data or factual claims.

## Product principles

- A workout can be minimized and resumed without discarding logged work.
- Each screen gives one clear next action and an understandable way back.
- Missing data offers a useful action instead of fabricated values.
- Imported data is validated and replaced atomically; export stays explicit.
- Controls remain accessible at 360dp with 1.5x text and reduced motion.
