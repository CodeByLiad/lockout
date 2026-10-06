import 'package:flutter/material.dart';

import '../theme/lockout_motion.dart';

/// A surface whose corner radius is a function of its interaction state.
///
/// The one place the shape-as-state rule is implemented, so a screen never
/// writes its own `AnimatedContainer` with a hand-picked duration. Pass the
/// rest and active radii from `LockoutTheme`'s pairs; pass `activeScale` on
/// anything the house document says shrinks while pressed.
///
/// `MediaQuery.maybeDisableAnimationsOf` is honoured through
/// `LockoutMotionTier.durationFor`, so a user who asked the OS to remove
/// animations gets an instant state change rather than a spring.
class MorphingSurface extends StatelessWidget {
  final double restRadius;
  final double activeRadius;
  final bool active;

  /// 1.0 for anything that does not shrink. The house press morph is 0.97.
  final double activeScale;

  /// Painted behind [child]. Null leaves the surface transparent, for a
  /// caller that paints its own background inside.
  final Color? color;

  final Widget child;

  const MorphingSurface({
    super.key,
    required this.restRadius,
    required this.activeRadius,
    required this.active,
    this.activeScale = 1.0,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tier = LockoutMotion.springFast;
    final duration = tier.durationFor(context);

    return AnimatedScale(
      scale: active ? activeScale : 1.0,
      duration: duration,
      curve: tier.curve,
      child: AnimatedContainer(
        duration: duration,
        curve: tier.curve,
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              BorderRadius.circular(active ? activeRadius : restRadius),
        ),
        clipBehavior: color == null ? Clip.none : Clip.antiAlias,
        child: child,
      ),
    );
  }
}
