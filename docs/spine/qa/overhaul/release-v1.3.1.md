# v1.3.1 release verification

Date: 2026-11-04. The user authorized publication and a new permanent signing
key, then approved The last rep from icon exploration 03.

## Final artifact

- `LOCKOUT-v1.3.1.apk`, package `com.jinatra.lockout`, version `1.3.1+6`.
- 57,066,084 bytes.
- APK SHA-256: `9C84D39AB6CDD87D7583703D843EAA5BCFD6B69D64A94776600708E4CE77A4BF`.
- Public signing certificate SHA-256:
  `5580479C76233D86FD10A50B557F3585127A16C0AF807CF7E2622420F3858C24`.
- `apksigner verify --verbose --print-certs`: valid v2 signature, one signer,
  RSA 4096, subject Lockout Android release / Jinatra Ltd.

The keystore and self-contained `SIGNING_KEY.md` recovery backup are in the
owner-requested OneDrive folder, outside Git. Recovery Base64 was decoded and
compared byte-for-byte with the actual encrypted keystore. Ignored local
properties supply the credentials; no passwords or private material are in
the source, logo ZIP or release downloads. `docs/releasing.md` records setup.

## Tests and build

- Full serial suite: **940 passed**, `.spine/release-v1.3.1-tests.log`.
- Analysis: **0 errors, 0 warnings, 2 pre-existing test information notices**,
  `.spine/release-v1.3.1-analysis.log`.
- Release build: successful, `.spine/release-v1.3.1-build.log`.
- Launcher tests first failed for missing assets, then passed: all legacy pixel
  sizes, adaptive/round/themed resources, and the actual foreground's opaque
  pixels inside Android's always-visible circular safe zone.
- Signing validation failed before implementation, passes with the permanent
  key, and rejects deliberately missing configuration without debug fallback.
- About's version regression failed before updating the final displayed version.

The existing CI workflow is retained because the current GitHub OAuth grant
cannot edit workflows. With explicit `GITHUB_ACTIONS=true` and no permanent
credentials, it builds debug-signed test APKs and logs a warning. Local official
release builds still reject missing credentials. CI artifacts are not public
release APKs. This branch was tested to fail first, then pass; the official APK's
permanent certificate was separately verified. No new app dependencies.

## Native and visual scope

The final APK installed and launched as versionName `1.3.1`, versionCode `6` on
an API 36 read-only emulator replica (`emulator-5556`). Only that ephemeral copy's
older signed installation was removed; the original QA disk and data were kept.
Android's settled App info screen shows the approved dumbbell icon with its
round adaptive mask (`.impeccable/review/final/v1.3.1-app-icon.png`).

The emulator's System UI briefly reported an ANR during cold boot under host
load; it recovered. This was a system-process dialog, not a Flutter exception.
The final Flutter runtime log is `.spine/release-v1.3.1-runtime.log`.
The prior bounded light/dark/large-text UI evidence remains in `verification.md`;
this final pass checks the icon, signing and release package rather than claiming
a new independent forty-state visual certification.

## Public assets and migration

`Lockout-logo-pack.zip` contains five SVG masters and 95 PNGs in square,
rounded-square, round, foreground and monochrome formats. The README retains
eight real app screenshots with only Android's system bars cropped away.

This permanent key differs from all earlier debug-signed candidates and v1.1.0.
Release notes and the README require exporting a backup outside the app before
removing an older installation, then importing after installing v1.3.1. Future
official releases must use this permanent key for in-place updates.

The superseded v1.3.0 draft is removed when v1.3.1 is published; its Git tag is
retained as historical source rather than rewritten. v1.3.1's tag identifies the
actual approved-icon/signing source.
