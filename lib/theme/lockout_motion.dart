import 'package:flutter/material.dart';

/// One named motion tier: a curve and the duration it runs for.
///
/// A value rather than two loose constants, so a call site cannot pair the
/// fast curve with the slow duration.
@immutable
class LockoutMotionTier {
  final Curve curve;
  final Duration duration;

  const LockoutMotionTier({required this.curve, required this.duration});

  /// [duration], or `Duration.zero` when the user has asked the OS to remove
  /// animations.
  ///
  /// Every animated surface in the app reads its duration through this
  /// rather than from [duration] directly. A spring that still overshoots
  /// under "remove animations" is an accessibility regression, not a flourish.
  Duration durationFor(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : duration;
  }
}

/// The app's motion vocabulary — exactly three tiers, no more.
///
/// These map onto the three kinds in
/// `docs/design/nuvetrix-app-design-system.md` section 6. That document
/// specifies Compose springs, which Flutter has no equivalent token for;
/// these match them by settle time instead, and that substitution is entry
/// D3 in the deviation register.
///
/// Framework `Durations` / `Easing` tokens are not used anywhere in the app.
/// Three named tiers that every surface shares is the point: a one-off
/// duration at a call site is how a motion system stops being a system.
class LockoutMotion {
  LockoutMotion._();

  /// Passes its target and settles back. Flutter does not clamp a `Cubic`
  /// above 1.0, so the overshoot is real rather than an eased approximation.
  static const Cubic spring = Cubic(0.2, 1.35, 0.3, 1);

  /// Press morphs, chip selection, the switch thumb.
  static const LockoutMotionTier springFast = LockoutMotionTier(
    curve: spring,
    duration: Duration(milliseconds: 250),
  );

  /// Sheets, screen transitions, card expands.
  static const LockoutMotionTier springDefault = LockoutMotionTier(
    curve: spring,
    duration: Duration(milliseconds: 450),
  );

  /// Colour and opacity. No overshoot: a colour that passes its target
  /// lands on a hue nobody authored.
  static const LockoutMotionTier effects = LockoutMotionTier(
    curve: Curves.easeOut,
    duration: Duration(milliseconds: 200),
  );
}
