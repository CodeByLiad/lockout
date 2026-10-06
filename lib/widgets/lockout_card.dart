import 'package:flutter/material.dart';

import '../theme/lockout_theme.dart';

/// The app's one card shape.
///
/// It deliberately sets neither colour nor shape: both come from
/// `CardThemeData`, so a theme switch repaints every card without touching a
/// call site. A card that passes its own `color:` is a bug rather than a
/// variant — the one legitimate use is [color], for a card that has to sit on
/// top of another surface and needs the next tone up.
class LockoutCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Only for a card stacked on another surface — a card inside a sheet, say.
  /// Everything else takes the theme's surface tone.
  final Color? color;

  final VoidCallback? onTap;

  /// Lifts to elevation 3 for the one card per screen that leads.
  final bool elevated;

  /// Overrides the theme's card shape. Only the hero card passes one — it
  /// wears the family's signature asymmetric outline, and every other card
  /// takes the uniform shape from `cardTheme`.
  final ShapeBorder? shape;

  const LockoutCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.elevated = false,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding ?? const EdgeInsets.all(LockoutTheme.cardPadding),
      child: child,
    );

    return Card(
      color: color,
      elevation: elevated ? 3 : null,
      shape: shape,
      child: onTap == null
          ? body
          // The ripple has to follow the card's own outline: a pill-radius
          // splash on the asymmetric hero shape bleeds past the tight corner.
          : InkWell(
              onTap: onTap,
              customBorder: shape ??
                  RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(LockoutTheme.radiusCard),
                  ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: LockoutTheme.minTouchTarget,
                ),
                child: body,
              ),
            ),
    );
  }
}
