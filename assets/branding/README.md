# Lockout — The last rep

User-approved on 2026-11-04: "I like the last rep one. so use that".
The mark is an upward-angled dumbbell with broad rounded plates, in Rep lime and
dark ink. The production geometry is a clean vector reconstruction of the center
concept in `docs/design/icon-preview/concept-03.png`, rather than a crop of the board.

Five SVG variants: square, rounded-square, round, transparent foreground and
monochrome. PNG exports for each variant: 16, 24, 32, 48, 64, 72, 96, 108, 128,
144, 162, 192, 216, 256, 324, 384, 432, 512 and 1024 pixels. All PNGs carry source
and prompt metadata; `provenance.json` records approval and export details.

The Android launcher uses the same geometry, with 48/72/96/144/192px legacy
resources, vector adaptive layers and an Android 13 themed monochrome layer.
Foreground geometry fits the always-visible circular safe zone.

Regenerate using `python tools/generate_brand_assets.py` with local Pillow.
App package dependencies remain unchanged.
