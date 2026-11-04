import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/lockout_motion.dart';
import '../../theme/lockout_shapes.dart';
import '../../theme/lockout_theme.dart';

/// The 48dp icon tile used for Today's action grid.
///
/// Each tile carries its own fixed shape (deviation D13, superseding "one
/// consistent squircle"), and morphs to a circle while pressed.
class NvIconTile extends StatefulWidget {
  final IconData icon;

  /// The tile's resting shape.
  final LockoutShape shape;

  final String label;
  final VoidCallback onTap;

  const NvIconTile({
    super.key,
    required this.icon,
    required this.shape,
    required this.label,
    required this.onTap,
  });

  @override
  State<NvIconTile> createState() => _NvIconTileState();
}

class _NvIconTileState extends State<NvIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Offset? _downAt;

  void _animateTo(double target) {
    if (!mounted) return;
    final tier = LockoutMotion.springFast;
    final duration = tier.durationFor(context);
    if (duration == Duration.zero) {
      _press.value = target;
      return;
    }
    _press.animateTo(target, duration: duration, curve: tier.curve);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // `onTap` here as well as on the detector: `excludeSemantics` drops the
    // detector's semantics node and its tap action with it, leaving a tile a
    // screen reader can read and cannot press.
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      // The press morph rides a `Listener`, not `onTapDown`: a tap recognizer
      // delays `onTapDown` by `kPressTimeout` (100ms), which would eat most of
      // a springFast morph and make the response feel late.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          _downAt = e.position;
          _animateTo(1);
        },
        onPointerMove: (e) {
          // A drag inside a scroll view is won by the scroll recognizer, and
          // the Listener sees no cancel until the finger lifts.
          final down = _downAt;
          if (down != null && (e.position - down).distance > kTouchSlop) {
            _downAt = null;
            _animateTo(0);
          }
        },
        onPointerUp: (_) {
          _downAt = null;
          _animateTo(0);
        },
        onPointerCancel: (_) {
          _downAt = null;
          _animateTo(0);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapCancel: () => _animateTo(0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: LockoutTheme.spaceSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _press,
                  builder: (context, child) => DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colors.secondaryContainer,
                      shape: LockoutShapeBorder(
                        widget.shape,
                        morphTo: LockoutShape.circle,
                        progress: _press.value,
                      ),
                    ),
                    child: child,
                  ),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: LockoutTheme.spaceSm),
                Text(
                  widget.label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
