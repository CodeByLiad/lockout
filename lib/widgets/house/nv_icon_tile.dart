import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// The 40dp icon tile from section 8's list spec, used for Today's action
/// grid.
///
/// One consistent squircle across every tile, 14dp. Lobe count deliberately
/// does not rotate here: colour already carries category, and two signals on
/// one axis read as noise.
class NvIconTile extends StatelessWidget {
  final IconData icon;

  /// The category colour, from `LockoutSemantics.categoryRamp`.
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

    return Semantics(
      button: true,
      label: label,
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
                child: Icon(icon, size: 20, color: theme.colorScheme.surface),
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
