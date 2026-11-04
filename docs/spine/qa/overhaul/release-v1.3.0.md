# v1.3.0 release verification

Superseded draft candidate; never published. The user then approved a new icon
and requested a permanent signing key. See [v1.3.1 verification](release-v1.3.1.md).

Date: 2026-11-04. User explicitly requested a source push to
`https://github.com/CodeByLiad/lockout.git`, a GitHub release with the APK, and a
README with real app screenshots cropped to remove Android's system bars.

## Release candidate

- Version `1.3.0+5`, Android package `com.jinatra.lockout`.
- Asset `LOCKOUT-v1.3.0.apk`, 57,051,572 bytes.
- SHA-256 `419D06B752C5073CDDBB54070430459C2940B9C736B2CB8C4F7AB637A262BBFC`.
- Built using the full-path Flutter SDK and `build apk --release --no-pub`.
- Existing full overhaul suite: 937 passed serially.
- Release follow-up: 35 About/backup tests passed serially after the new version
  and requested repository link; the About version regression failed first.
- Release analysis: 0 errors, 0 warnings, 2 pre-existing test information notices.
- Exact named release asset installed with replacement on the API 36 emulator;
  Android reports versionName `1.3.0`, versionCode `5`. Existing data retained.
- No pictured screen changed after the verified UI captures; release changes
  update version metadata and the explicit About source destination.

Logs are local under `.spine/`: `release-version-red.log`,
`release-version-green.log`, `release-v1.3.0-analysis.log` and
`release-v1.3.0-build.log`. The previous UI candidate's identity and bounded
visual review remain documented in `verification.md`.

## README screenshots

Eight real installed-app captures are in `docs/screenshots/`. Each was cropped
from 1080×2400 to 1080×2211 using box `[0,126,1080,2337]`: Android's status bar
and bottom system gesture bar are removed. The app's own navigation remains.
No content was retouched or generated. `provenance.json` records every source
and exact crop. Two cropped light/dark views were visually rechecked; all eight
were checked for source dimensions and exact crop bounds.

The README now describes four task destinations, generated three-axis themes,
rebuilt workout flows, local storage, serial tests and honest verification scope.
Generated design concepts remain separate review documents.

## Signing compatibility

The repository's existing release configuration signs with the local Android
debug key. The candidate certificate SHA-256 is
`95ae772f7c2a2b788214e4118aa9045e90b4207aab8d07142d114d512cecfecc`.
The published v1.1.0 APK uses
`f6624d0175c0f41d952df015e1d939edd65ff1798937cb93d1d81c75935cc061`.
Android rejects an in-place update across these different signing identities.
The original signing key is not in the checkout. This compatibility finding
must remain explicit in the release documentation unless the original key is
provided and the artifact is rebuilt with it.
