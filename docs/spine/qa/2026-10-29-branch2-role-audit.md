# Branch 2 role audit: rebuilt screens and house catalog

Date 2026-11-01. Scope: today_tab, profile_tab, settings_screen, about_screen, every file in lib/widgets/house/.

Guard: `generated-scheme readiness` in test/expressive_contract_test.dart. It failed once on first run, but only because of an escaping typo in the test regex. With the regex fixed it passed against unmodified sources, so it is a characterisation guard: no colour literal and no `Colors.*` other than `Colors.transparent` in any rebuilt screen or catalog widget.

## Roles read, by file

| File:line | Role | Paints | Under a generated scheme |
| --- | --- | --- | --- |
| nv_button:78-79 | primary / onPrimary | filled button | Correct. Filled NvButton is on primary. |
| nv_button:83-84 | secondaryContainer / onSecondaryContainer | tonal button | M3 standard. |
| nv_button:93-104 | onSurface, outline, primary, danger, outlineVariant | outlined/text/danger variants | Standard roles. |
| nv_button:73-74 | heroFill / onHeroFill | button on a hero card | Correct, semantic. |
| nv_button:137,114 | surfaceContainerHighest, onSurfaceVariant | disabled | Standard. |
| nv_button:225-235 | surfaceContainerHigh, onSurface, success/onSuccess | secondary state | Standard. |
| nv_hero_card:52,70,85,94 | heroFill / onHeroFill | hero | Correct. |
| nv_icon_tile:86,99 | secondaryContainer / onSecondaryContainer | tile | Moved in Task 6. |
| nv_navigation_bar:68,96,154-164 | surfaceContainer, secondaryContainer (indicator), onSecondaryContainer, onSurface, onSurfaceVariant | nav bar | M3 standard. |
| nv_segmented_button:77-86 | secondaryContainer selected, surfaceContainer rest | segments | M3 standard, kept. |
| nv_status_badge:36-52 | primaryContainer, success, outline, surfaceContainerHigh | badges | Standard. |
| nv_text_field:38-90 | error, outline, primary | field border | Standard. |
| nv_wavy_progress:69-70 | surfaceContainerHighest track, primary | progress | Standard. |
| nv_grouped_list:70,91 | surfaceContainer, onSurfaceVariant | groups | Standard. |
| nv_cards:17-50 | surfaceContainer, outlineVariant, onSurfaceVariant | cards | Standard. |
| nv_dialog:30 | surfaceContainerHigh | dialog | Standard. |
| nv_empty_state:33,45 | surfaceContainer, onSurfaceVariant | empty state | Standard. |
| nv_sheet:19 | surfaceContainer | sheet | Standard. |
| **nv_sheet:65,68** | **surface text on onSurface fill** | **snackbar** | **Fixed-palette choice (inverse by hand). Re-pointed to inverseSurface / onInverseSurface.** |
| today_tab:632, profile_tab:33, settings:726 | surface | scaffold | Standard. |
| today_tab:722,1125 | onSurfaceVariant | captions | Standard. |
| today_tab:1140,1150 | primaryContainer / onPrimaryContainer | session marker | Standard pair. |
| today_tab:1260 | onSurface | text | Standard. |
| today_tab:1305,1462,1549 | surfaceContainer, surfaceContainerHigh | rows | Standard. |
| today_tab:752 | onHeroFill | hero marker | Correct (c1b8a48). |
| today_tab:885 | semantics.chartLine | chart | Semantic. |
| today_tab:1465 | semantics.success | status | Semantic. |
| settings:454-462 | errorContainer / inverseSurface and on-pairs | toast | Already inverse; correct. |
| settings:883-889 | secondaryContainer / onSecondaryContainer | selected item | M3 standard. |
| settings:1206-1243 | primaryContainer / onPrimaryContainer | header medallion area | Standard pair. |
| settings:1261-1267 | tertiaryContainer / onTertiaryContainer | tertiary callout | Standard pair; tertiary is generated, so hue follows the seed. |
| settings:1460 | onSurface / Colors.transparent | swatch ring | Standard. |

about_screen reads no colour roles directly.

## Changed

- `showNvSnackbar` now paints `inverseSurface` with `onInverseSurface` text (test: nv_overlays_test, "it paints inverseSurface with onInverseSurface text"). onSurface/surface only inverted correctly under the old fixed neutrals.

## Confirmed

Filled NvButton on primary; selected segment on secondaryContainer; hero on heroFill.
