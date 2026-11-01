import 'package:flutter/material.dart';

import 'accents.dart';
import 'lockout_semantics.dart';
import 'scheme_style.dart';

/// The app's colour: a scheme generated from the accent, plus the handful
/// of roles Material 3 has none for.
///
/// The scheme is generated, not authored (deviation D11). The house neutrals
/// this class used to copy from `docs/design/nuvetrix-app-design-system.md`
/// section 3 stayed the same whatever accent was chosen, so in light the
/// accent changed almost nothing on screen. Seeding `ColorScheme.fromSeed`
/// with the accent lets surfaces, containers and controls all follow it.
/// What is still authored below is success, its container and the category
/// ramp: roles the generator has no notion of.
class LockoutPalette {
  LockoutPalette._();

  // House section 3.1 custom roles. Still authored: the generator has no
  // success role.
  static const Color _lightSuccess = Color(0xFF1E6E47);
  static const Color _lightSuccessContainer = Color(0xFFCDEFD9);
  static const Color _darkSuccess = Color(0xFF7ED3A4);
  static const Color _darkSuccessContainer = Color(0xFF0F3D27);

  /// Eight colours for telling many categories apart at a glance.
  ///
  /// Authored per brightness rather than derived from the accent. Rotating
  /// one hue through HSL collided two same-category days onto a single
  /// colour and produced muddy mid-tones; that finding predates this
  /// redesign and still holds. Two ramps now, not six.
  static const List<Color> _lightRamp = [
    Color(0xFF365E27),
    Color(0xFF1D5C78),
    Color(0xFF6B3F8C),
    Color(0xFF8C4A1F),
    Color(0xFF0C5B4E),
    Color(0xFF7A2F55),
    Color(0xFF3E4A6B),
    Color(0xFF6B5C0F),
  ];

  static const List<Color> _darkRamp = [
    Color(0xFFB5DE94),
    Color(0xFF8FD0EC),
    Color(0xFFD3B2F0),
    Color(0xFFF0B48C),
    Color(0xFF7FD9C8),
    Color(0xFFF0A3C4),
    Color(0xFFAEB8DE),
    Color(0xFFDECE8F),
  ];

  /// The `ColorScheme` for a brightness, accent and style.
  ///
  /// Generated, not authored (deviation D11): the accent seeds Material's own
  /// tonal algorithm, so surfaces, containers and controls all follow it.
  /// `surfaceTint` is cleared because elevation reads through the container
  /// roles, not through a tint overlay.
  ///
  /// The expressive style pins its primary roles (`primary`, `onPrimary`,
  /// `primaryContainer`, `onPrimaryContainer`, `inversePrimary`) to the
  /// tonal-spot scheme for the same seed. `DynamicSchemeVariant.expressive`
  /// rotates the primary hue away from the seed (teal became brown, coral
  /// blue), so the filled primary action no longer matched the chosen accent
  /// (pass-1 finding 5). Every other expressive role is left as generated.
  static ColorScheme schemeFor(
    Brightness brightness,
    LockoutAccent accent,
    LockoutSchemeStyle style,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent.accent,
      brightness: brightness,
      dynamicSchemeVariant: style.variant,
    ).copyWith(surfaceTint: Colors.transparent);
    if (style != LockoutSchemeStyle.expressive) return scheme;
    final tonal = ColorScheme.fromSeed(
      seedColor: accent.accent,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    return scheme.copyWith(
      primary: tonal.primary,
      onPrimary: tonal.onPrimary,
      primaryContainer: tonal.primaryContainer,
      onPrimaryContainer: tonal.onPrimaryContainer,
      inversePrimary: tonal.inversePrimary,
    );
  }

  /// The roles Material 3 has none for.
  ///
  /// [scheme] is the generated scheme these roles will sit on. `restDay` and
  /// `danger` follow it; `success`, `warning`, the chart fill and the
  /// category ramp keep their authored values, re-verified against every
  /// generated surface by `contrast_matrix_test.dart`. The hero keeps the
  /// exact accent: a generated tonal lime is muted, and the hero is where
  /// Rep lime has to read as itself.
  static LockoutSemantics semanticsFor(
    Brightness brightness,
    LockoutAccent accent,
    ColorScheme scheme,
  ) {
    final light = brightness == Brightness.light;
    return LockoutSemantics(
      success: light ? _lightSuccess : _darkSuccess,
      onSuccess: light ? const Color(0xFFFFFFFF) : const Color(0xFF0F3D27),
      warning: light ? const Color(0xFF8A5A00) : const Color(0xFFE8C06A),
      danger: scheme.error,
      restDay: scheme.onSurfaceVariant,
      chartLine: accent.accent,
      chartFill: light ? _lightSuccessContainer : _darkSuccessContainer,
      categoryRamp: light ? _lightRamp : _darkRamp,
      heroFill: accent.accent,
      onHeroFill: accent.ink,
    );
  }
}
