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

/// The app's motion vocabulary — three interaction tiers and one ambient
/// tier, no more.
///
/// The three interaction tiers map onto the three kinds in
/// `docs/design/nuvetrix-app-design-system.md` section 6. That document
/// specifies Compose springs, which Flutter has no equivalent token for;
/// these match them by settle time instead, and that substitution is entry
/// D3 in the deviation register.
///
/// [ambientDrift] is the fourth, and it is deliberately not a fourth kind of
/// interaction. Section 6 opens with "nothing moves on its own except the
/// wavy progress indicator" and lists the wave separately from the table:
/// it answers no gesture, has no rest and active state, and never settles,
/// so none of the three can describe it. It is named here rather than left
/// as a literal in the widget so that the wave's period is a vocabulary
/// entry someone can find, and so that a second ambient surface has one
/// place to take its timing from instead of inventing another number.
///
/// Framework `Durations` / `Easing` tokens are not used anywhere in the app.
/// A small closed set of named tiers that every surface shares is the point:
/// a one-off duration at a call site is how a motion system stops being a
/// system. Adding a fifth entry here needs the same argument the fourth
/// made — a kind of motion none of the existing tiers can describe.
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

  /// The wavy progress indicator's drift — the only motion in the app that
  /// runs without the user asking for it (house section 6).
  ///
  /// Linear, because the curve is the shape of one loop of a continuous
  /// cycle: an eased loop would make the wave hesitate once per period, and
  /// a spring would make it jerk. 2400ms is "slowly" as section 6 asks —
  /// about one wavelength per two and a half seconds at the painted
  /// wavelength, slow enough to read as drift rather than as travel.
  ///
  /// Consumed through [duration], not [durationFor], and that is the one
  /// exception in this file. A repeating controller cannot take
  /// `Duration.zero` as a period, so reduced motion is honoured the way
  /// section 6 actually specifies it for the wave — "stop the wave" — by
  /// stopping the ticker in `nv_wavy_progress.dart`, which
  /// `nv_wavy_progress_test.dart` holds.
  static const LockoutMotionTier ambientDrift = LockoutMotionTier(
    curve: Curves.linear,
    duration: Duration(milliseconds: 2400),
  );
}
