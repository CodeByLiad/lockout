# Colour debt on old screens

Grep: `Color(0x` and `Colors.(white|black|grey)` across lib/screens and lib/widgets, excluding rebuilt screens and lib/widgets/house/. Run 2026-11-01 over the tree at HEAD c1b8a48.

Result: no hits. Not fixed here; nothing to fix.

| Hit | Owner |
| --- | --- |
| none | n/a |

Caveat: the grep covers only those literals. Old screens (workout/routines, progress, body, log, food) may still use other `Colors.*` constants (for example `Colors.red`), fixed role choices such as `inverseSurface` fills, or colours in lib/theme. Branch 3 (Workout) and branch 4 (Progress, Body, Log, Food) should repeat a role audit like branch2-role-audit.md when each is rebuilt.
