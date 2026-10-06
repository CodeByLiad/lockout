import 'package:flutter/material.dart';

import 'accents.dart';
import 'lockout_semantics.dart';

/// The house neutral palette, composed with a selectable accent.
///
/// Every colour below is copied from
/// `docs/design/nuvetrix-app-design-system.md` section 3. The four roles the
/// house document does not name — `surfaceContainerLow`,
/// `surfaceContainerLowest`, `secondary` and the inverse trio — are
/// interpolated from the ones it does, and are marked where they appear.
class LockoutPalette {
  LockoutPalette._();

  // House section 3.1 — light.
  static const Color _lightSurface = Color(0xFFFBF9FF);
  static const Color _lightContainer = Color(0xFFF1EEF8);
  static const Color _lightContainerHigh = Color(0xFFE8E4F2);
  static const Color _lightContainerHighest = Color(0xFFDDD8EC);
  static const Color _ink = Color(0xFF16132E);
  static const Color _lightOnSurfaceVariant = Color(0xFF4A4663);
  static const Color _lightOutline = Color(0xFF77728F);
  static const Color _lightOutlineVariant = Color(0xFFCAC5DA);
  static const Color _lightPrimary = Color(0xFF2E2766);
  static const Color _lightSecondaryContainer = Color(0xFFE4DFFF);
  static const Color _lightOnSecondaryContainer = Color(0xFF231A5C);
  static const Color _lightTertiary = Color(0xFF5B3FE0);
  static const Color _lightTertiaryContainer = Color(0xFFE6DEFF);
  static const Color _lightOnTertiaryContainer = Color(0xFF21105E);
  static const Color _lightError = Color(0xFFB3261E);
  static const Color _lightErrorContainer = Color(0xFFF9DEDC);
  static const Color _lightOnErrorContainer = Color(0xFF410E0B);

  // House section 3.2 — dark.
  static const Color _darkSurface = Color(0xFF131124);
  static const Color _darkContainer = Color(0xFF1C1A33);
  static const Color _darkContainerHigh = Color(0xFF25223F);
  static const Color _darkContainerHighest = Color(0xFF302D4C);
  static const Color _darkOnSurface = Color(0xFFEDEAF7);
  static const Color _darkOnSurfaceVariant = Color(0xFFC3BED7);
  static const Color _darkOutline = Color(0xFF938EAB);
  static const Color _darkOutlineVariant = Color(0xFF46425F);
  static const Color _darkSecondaryContainer = Color(0xFF342D6B);
  static const Color _darkOnSecondaryContainer = Color(0xFFE4DFFF);
  static const Color _darkTertiary = Color(0xFFB9A8FF);
  static const Color _darkTertiaryContainer = Color(0xFF3C2C8F);
  static const Color _darkOnTertiaryContainer = Color(0xFFE6DEFF);
  static const Color _darkError = Color(0xFFF2B8B5);
  static const Color _darkErrorContainer = Color(0xFF601410);
  static const Color _darkOnErrorContainer = Color(0xFFF9DEDC);

  // Interpolated: the house document stops at `surfaceContainer`, but
  // Flutter's ColorScheme has two steps below it and the bottom-sheet theme
  // already reads `surfaceContainerLow`.
  static const Color _lightContainerLow = Color(0xFFF6F3FC);
  static const Color _lightContainerLowest = Color(0xFFFFFFFF);
  static const Color _darkContainerLow = Color(0xFF181630);
  static const Color _darkContainerLowest = Color(0xFF0E0C1C);

  // Interpolated: `secondary` has no house entry; it is the solid tone of
  // the secondary container pair the house does define.
  static const Color _lightSecondary = Color(0xFF4C4680);
  static const Color _darkSecondary = Color(0xFFC7C0F5);

  // House section 8 states the snackbar is `onSurface` behind `surface`
  // text, which is exactly what the inverse pair means.
  static const Color _lightInverseSurface = _ink;
  static const Color _lightOnInverseSurface = _lightSurface;
  static const Color _darkInverseSurface = _darkOnSurface;
  static const Color _darkOnInverseSurface = _darkSurface;

  // House section 3.1 custom roles.
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
    Color(0xFF3F6B2E),
    Color(0xFF1D5C78),
    Color(0xFF6B3F8C),
    Color(0xFF8C4A1F),
    Color(0xFF0F6B5C),
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

  /// The `ColorScheme` for a brightness and accent.
  ///
  /// In light the accent fills the container pair and `primary` is the fixed
  /// house indigo for every accent — the accent is for emphasis on two or
  /// three elements per screen, not for every filled button. In dark the
  /// accent fills `primary` as well, because a dark surface needs the
  /// brighter tone to carry.
  static ColorScheme schemeFor(Brightness brightness, LockoutAccent accent) {
    if (brightness == Brightness.light) {
      return ColorScheme(
        brightness: Brightness.light,
        primary: _lightPrimary,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: accent.accent,
        onPrimaryContainer: accent.ink,
        secondary: _lightSecondary,
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: _lightSecondaryContainer,
        onSecondaryContainer: _lightOnSecondaryContainer,
        tertiary: _lightTertiary,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: _lightTertiaryContainer,
        onTertiaryContainer: _lightOnTertiaryContainer,
        error: _lightError,
        onError: const Color(0xFFFFFFFF),
        errorContainer: _lightErrorContainer,
        onErrorContainer: _lightOnErrorContainer,
        surface: _lightSurface,
        onSurface: _ink,
        onSurfaceVariant: _lightOnSurfaceVariant,
        surfaceContainerLowest: _lightContainerLowest,
        surfaceContainerLow: _lightContainerLow,
        surfaceContainer: _lightContainer,
        surfaceContainerHigh: _lightContainerHigh,
        surfaceContainerHighest: _lightContainerHighest,
        outline: _lightOutline,
        outlineVariant: _lightOutlineVariant,
        inverseSurface: _lightInverseSurface,
        onInverseSurface: _lightOnInverseSurface,
        inversePrimary: accent.accent,
        scrim: _ink,
        shadow: _ink,
        surfaceTint: Colors.transparent,
      );
    }

    return ColorScheme(
      brightness: Brightness.dark,
      primary: accent.accent,
      onPrimary: accent.ink,
      primaryContainer: accent.accent,
      onPrimaryContainer: accent.ink,
      secondary: _darkSecondary,
      onSecondary: _darkSecondaryContainer,
      secondaryContainer: _darkSecondaryContainer,
      onSecondaryContainer: _darkOnSecondaryContainer,
      tertiary: _darkTertiary,
      onTertiary: _lightOnTertiaryContainer,
      tertiaryContainer: _darkTertiaryContainer,
      onTertiaryContainer: _darkOnTertiaryContainer,
      error: _darkError,
      onError: _darkErrorContainer,
      errorContainer: _darkErrorContainer,
      onErrorContainer: _darkOnErrorContainer,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      surfaceContainerLowest: _darkContainerLowest,
      surfaceContainerLow: _darkContainerLow,
      surfaceContainer: _darkContainer,
      surfaceContainerHigh: _darkContainerHigh,
      surfaceContainerHighest: _darkContainerHighest,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      inverseSurface: _darkInverseSurface,
      onInverseSurface: _darkOnInverseSurface,
      inversePrimary: _lightPrimary,
      scrim: const Color(0xFF000000),
      shadow: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
    );
  }

  /// The roles Material 3 has none for.
  ///
  /// `chartLine` follows the accent so the one chart on screen reads as the
  /// user's colour; everything else is fixed per brightness.
  static LockoutSemantics semanticsFor(
    Brightness brightness,
    LockoutAccent accent,
  ) {
    final light = brightness == Brightness.light;
    final success = light ? _lightSuccess : _darkSuccess;
    return LockoutSemantics(
      success: success,
      onSuccess: light ? const Color(0xFFFFFFFF) : const Color(0xFF0F3D27),
      warning: light ? const Color(0xFF8A5A00) : const Color(0xFFE8C06A),
      danger: light ? _lightError : _darkError,
      restDay: light ? _lightOnSurfaceVariant : _darkOnSurfaceVariant,
      chartLine: accent.accent,
      chartFill: light
          ? _lightSuccessContainer
          : _darkSuccessContainer,
      categoryRamp: light ? _lightRamp : _darkRamp,
    );
  }
}
