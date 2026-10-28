import 'package:flutter/material.dart';

import '../../theme/lockout_semantics.dart';
import '../../theme/lockout_theme.dart';

/// The 40dp icon tile from section 8's list spec, used for Today's action
/// grid.
///
/// One consistent squircle across every tile, 14dp. Lobe count deliberately
/// does not rotate here: a tile is given one fill, and two signals on one
/// axis read as noise.
class NvIconTile extends StatelessWidget {
  final IconData icon;

  /// The tile's fill. Any colour: the glyph is derived from it, so the tile
  /// stays legible on whatever it is handed.
  ///
  /// It was documented as a `LockoutSemantics.categoryRamp` entry, and the
  /// glyph was pinned to `colorScheme.surface` on the strength of that —
  /// legible only on a fill the scheme happens to pair with `surface`. The
  /// one caller abandoned the ramp (Today's quick actions take a single
  /// neutral), so the contract is now the weaker and true one: the fill is
  /// the caller's, the foreground is this widget's problem.
  final Color color;

  final String label;
  final VoidCallback onTap;

  const NvIconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `onTap` here as well as on the `InkWell`: `excludeSemantics` drops the
    // InkWell's semantics node and its tap action with it, leaving a tile a
    // screen reader can read and cannot press.
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LockoutTheme.spaceSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                // Derived from the fill, not read off the theme:
                // `onCategoryColor` picks whichever of near-black and white
                // has the higher contrast against it, which is >= 3:1 for
                // any fill a caller can reasonably pass.
                child: Icon(icon,
                    size: 20, color: LockoutSemantics.onCategoryColor(color)),
              ),
              const SizedBox(height: LockoutTheme.spaceSm),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
