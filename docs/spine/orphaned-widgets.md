# Orphaned widgets — `house-rebuild-branch-1`

**Status at branch end. This is a ledger, not a deletion list.** Nothing is removed here.
A widget whose only remaining consumers are the out-of-scope screens is deleted on the branch
that rebuilds those screens, when the last consumer goes.

Rebuilt on this branch: `lib/screens/today_tab.dart`, `lib/screens/settings_screen.dart`,
`lib/screens/about_screen.dart`.
Out of scope (spec §2): Workout (`routines_tab.dart`), Progress (`progress_tab.dart`),
Food (`food_tab.dart`), Log (`log_tab.dart`), Body (`body_tab.dart`) — plus the shell
`main_screen.dart`, `profile_tab.dart` and Workout's sub-screen `exercise_video_screen.dart`,
which are not among the five but were not rebuilt either.

---

## How this list was derived

The plan's sketch matched on the bare file name (`grep -rl "$name" lib`). That is too loose in
both directions: it hits any prose or identifier containing the name, and `hero_card` is a
substring of `nv_hero_card`, so the catalog's own hero card would have read as a consumer of the
pre-rebuild one. It also walked only `lib/widgets/*.dart`, so `lib/widgets/house/` was invisible
to it.

Sharpened to match the **import path**, the way the contract guard at
`test/expressive_contract_test.dart` ("a rebuilt screen composes from the catalog, not the old
widgets") does — anchoring the name on a preceding `'` or `/` is what separates
`'house/nv_hero_card.dart'` from `'../widgets/hero_card.dart'`:

```bash
# run from the repo root
for f in $(find lib/widgets -name '*.dart' | sort); do
  name=$(basename "$f" .dart)
  consumers=$(grep -rlE "import +'[^']*['/]${name}\.dart'" lib --include='*.dart' \
              | grep -v "^${f}$" | sort | tr '\n' ' ')
  printf '%-36s %s\n' "$name" "${consumers:-<NO CONSUMER>}"
done
```

Two cross-checks were run before trusting the output, because an import-path grep is only
complete if every reference *is* an import of that form:

- `grep -rn "package:lockout/widgets" lib` — no hits. Nothing reaches a widget by package URI.
- `grep -rn "^export" lib/widgets` — no hits. No widget is re-exported through another file,
  so no consumer is hidden behind a barrel.

**What the derivation can still miss.** It proves a file is *imported*, not that anything in it
is *built*. A screen that keeps a stale import of a widget it no longer instantiates reads here
as a live consumer, and a widget reached only through a `Widget`-typed parameter passed in from
elsewhere would be undercounted. Dart's own unused-import lint covers the first case (the
analyzer is clean), but it is worth saying out loud rather than implying the table is a
build-graph. It is an import graph.

---

## Orphaned by this branch — zero consumers anywhere in `lib/`

Dead code today. No screen, rebuilt or out of scope, imports these.

| Widget | Consumers | Delete when |
| --- | --- | --- |
| `lib/widgets/action_grid.dart` | none | deletable now on the merits; held back because this task deletes nothing |
| `lib/widgets/home_hub.dart` | none | same |
| `lib/widgets/nutrition_bars.dart` | none | same |

`home_hub.dart` and `action_grid.dart` are both named in `_preRebuildWidgets` in the contract
test, so the guard keeps a rebuilt screen from importing them back. `nutrition_bars.dart` is
not in that list — it lost its last consumer without ever being guarded.

## Orphaned by this branch — only out-of-scope consumers remain

The rebuilt screens no longer reach any of these. Each row's consumers are **all** out of scope,
so each is deleted on the branch that rebuilds its last consumer.

| Widget | Remaining consumers | All out of scope? |
| --- | --- | --- |
| `calm_row.dart` | `body_tab.dart` | yes |
| `day_block.dart` | `routines_tab.dart` | yes |
| `food_picker.dart` | `food_tab.dart` | yes |
| `hero_card.dart` | `log_tab.dart` | yes |
| `lockout_card.dart` | `body_tab.dart`, `exercise_video_screen.dart`, `log_tab.dart`, `routines_tab.dart` | yes |
| `lockout_field.dart` | `body_tab.dart`, `food_tab.dart`, `routines_tab.dart` | yes |
| `meal_section.dart` | `food_tab.dart` | yes |
| `progress_hero.dart` | `food_tab.dart` | yes |
| `sheet_scaffold.dart` | `body_tab.dart`, `food_tab.dart`, `routines_tab.dart` | yes |
| `stat_tile.dart` | `body_tab.dart`, `food_tab.dart`, `log_tab.dart` | yes |
| `today_day_card.dart` | `routines_tab.dart` | yes |
| `undo_banner.dart` | `body_tab.dart`, `food_tab.dart`, `log_tab.dart` | yes |
| `week_day_row.dart` | `routines_tab.dart` | yes |
| `weight_card.dart` | `body_tab.dart` | yes |

## Not orphaned — still reached by a rebuilt screen

These stay. Two of them are worth flagging rather than filing quietly.

| Widget | Consumers | Note |
| --- | --- | --- |
| `bottom_nav.dart` | `main_screen.dart` | the app shell, not a screen body; untouched by the rebuild |
| `exercise_picker.dart` | `routines_tab.dart`, **`today_tab.dart`** | BREACH — see below |
| `sparkline.dart` | **`today_tab.dart`**, `weight_card.dart` | exempt — see below |

**Both are pre-rebuild widgets that a rebuilt screen still imports.** The pinned contract says a
rebuilt screen "composes from `lib/widgets/house/` and the theme only, never from a pre-rebuild
widget in `lib/widgets/`". The forbidden-import guard caught neither, because
`_preRebuildWidgets` names eight files and neither of these is among them.

**Human ruling, 2026-10-11: the two are not the same kind of debt, and are not treated the
same.**

`sparkline.dart` is **exempt, permanently.** It is a `CustomPainter` that draws a line from a
list of numbers. It owns no layout, no spacing and no surface, and takes its colour from the
caller. There is no previous design preserved inside it, so there is nothing for the rebuild to
end — a chart primitive is not a composition. The reason is written into
`_preRebuildWidgets`' own doc comment in `test/expressive_contract_test.dart`, so the next
reader finds it where they would go looking.

`exercise_picker.dart` is a **real breach, recorded and owned.** It is an old-composition sheet
reached by a rebuilt screen. It is **owed to the branch that rebuilds `routines_tab.dart`** —
its other consumer — and should be rebuilt as a house sheet there, at which point
`'exercise_picker.dart'` joins `_preRebuildWidgets` and `today_tab.dart`'s import goes with it.
Rebuilding it on this branch would pull an out-of-scope screen along with it, which is why it is
not fixed here.

It is recorded rather than fixed, not recorded instead of fixed: adding the name to
`_preRebuildWidgets` today turns the suite red on shipping code, and a guard that is green
because its list is short is not the same as code that is clean.

## Catalog-internal — reached only from `lib/widgets/house/`

Not orphans. The two shape-as-state primitives are now consumed by the catalog rather than
directly by a screen, which is the intended shape of the dependency.

| Widget | Consumers |
| --- | --- |
| `connected_group.dart` | `house/nv_grouped_list.dart` |
| `morphing_surface.dart` | `house/nv_button.dart`, `house/nv_grouped_list.dart` |

Spec §5.2 currently lists `morphing_surface` and `connected_group` among the widgets "that the
rebuilt screens no longer reach", alongside genuinely orphaned ones. They are reached — one
level down, through the catalog — and they must not be swept up by a later deletion pass that
reads that sentence literally.

## The catalog itself

Every file under `lib/widgets/house/` has at least one consumer outside the catalog
(`nv_button`, `nv_cards`, `nv_dialog`, `nv_empty_state`, `nv_grouped_list`, `nv_hero_card`,
`nv_icon_tile`, `nv_segmented_button`, `nv_sheet`, `nv_status_badge`, `nv_switch`,
`nv_text_field`, `nv_wavy_progress`). Nothing in the catalog is orphaned. The variants inside
those files are a separate question, answered in spec §5.2.
