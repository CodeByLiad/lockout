import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/theme/palette.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('the neutrals come from the house document', () {
    test('light surfaces and ink are exact', () {
      final s = LockoutPalette.schemeFor(
          Brightness.light, LockoutAccent.lime);
      expect(s.surface, const Color(0xFFFBF9FF));
      expect(s.surfaceContainer, const Color(0xFFF1EEF8));
      expect(s.surfaceContainerHigh, const Color(0xFFE8E4F2));
      expect(s.surfaceContainerHighest, const Color(0xFFDDD8EC));
      expect(s.onSurface, const Color(0xFF16132E));
      expect(s.onSurfaceVariant, const Color(0xFF4A4663));
      expect(s.outline, const Color(0xFF77728F));
      expect(s.outlineVariant, const Color(0xFFCAC5DA));
      expect(s.secondaryContainer, const Color(0xFFE4DFFF));
      expect(s.tertiary, const Color(0xFF5B3FE0));
      expect(s.error, const Color(0xFFB3261E));
    });

    test('dark surfaces and ink are exact', () {
      final s = LockoutPalette.schemeFor(
          Brightness.dark, LockoutAccent.lime);
      expect(s.surface, const Color(0xFF131124));
      expect(s.surfaceContainer, const Color(0xFF1C1A33));
      expect(s.surfaceContainerHigh, const Color(0xFF25223F));
      expect(s.surfaceContainerHighest, const Color(0xFF302D4C));
      expect(s.onSurface, const Color(0xFFEDEAF7));
      expect(s.onSurfaceVariant, const Color(0xFFC3BED7));
      expect(s.outline, const Color(0xFF938EAB));
      expect(s.outlineVariant, const Color(0xFF46425F));
      expect(s.secondaryContainer, const Color(0xFF342D6B));
      expect(s.tertiary, const Color(0xFFB9A8FF));
      expect(s.error, const Color(0xFFF2B8B5));
    });
  });

  group('the accent occupies the roles the house document gives it', () {
    test('in light, the accent is the container and primary is fixed', () {
      for (final accent in LockoutAccent.all) {
        final s = LockoutPalette.schemeFor(Brightness.light, accent);
        expect(s.primaryContainer, accent.accent);
        expect(s.onPrimaryContainer, accent.ink);
        expect(s.primary, const Color(0xFF2E2766),
            reason: 'light primary is the same for every accent');
        expect(s.onPrimary, const Color(0xFFFFFFFF));
      }
    });

    test('in dark, the accent is both primary and the container', () {
      for (final accent in LockoutAccent.all) {
        final s = LockoutPalette.schemeFor(Brightness.dark, accent);
        expect(s.primary, accent.accent);
        expect(s.onPrimary, accent.ink);
        expect(s.primaryContainer, accent.accent);
        expect(s.onPrimaryContainer, accent.ink);
      }
    });

    test('brightness is carried through', () {
      expect(LockoutPalette.schemeFor(Brightness.dark, LockoutAccent.teal)
          .brightness, Brightness.dark);
      expect(LockoutPalette.schemeFor(Brightness.light, LockoutAccent.teal)
          .brightness, Brightness.light);
    });
  });

  group('semantics', () {
    test('success is the house success pair in both brightnesses', () {
      final light = LockoutPalette.semanticsFor(
          Brightness.light, LockoutAccent.lime);
      final dark = LockoutPalette.semanticsFor(
          Brightness.dark, LockoutAccent.lime);
      expect(light.success, const Color(0xFF1E6E47));
      expect(dark.success, const Color(0xFF7ED3A4));
    });

    test('the chart line follows the accent', () {
      for (final accent in LockoutAccent.all) {
        final semantics =
            LockoutPalette.semanticsFor(Brightness.dark, accent);
        expect(semantics.chartLine, accent.accent);
      }
    });

    test('there are two ramps, one per brightness, not one per accent', () {
      final a = LockoutPalette.semanticsFor(
          Brightness.dark, LockoutAccent.lime).categoryRamp;
      final b = LockoutPalette.semanticsFor(
          Brightness.dark, LockoutAccent.coral).categoryRamp;
      expect(a, b);
    });

    test('every ramp entry clears 3.0 against its own surface', () {
      for (final brightness in Brightness.values) {
        final scheme =
            LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        final semantics =
            LockoutPalette.semanticsFor(brightness, LockoutAccent.lime);
        for (final colour in semantics.categoryRamp) {
          expect(_contrast(colour, scheme.surface),
              greaterThanOrEqualTo(3.0),
              reason: '$colour is unreadable on $brightness surface');
        }
      }
    });

    test('the ramp has eight entries, as categoryAt assumes', () {
      expect(
        LockoutPalette.semanticsFor(Brightness.dark, LockoutAccent.lime)
            .categoryRamp.length,
        8,
      );
    });

    test('danger and error stay distinguishable from success', () {
      for (final brightness in Brightness.values) {
        final scheme =
            LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        final semantics =
            LockoutPalette.semanticsFor(brightness, LockoutAccent.lime);
        expect(semantics.danger, isNot(semantics.success));
        expect(scheme.error, isNot(semantics.success));
      }
    });

    test('semantics is a LockoutSemantics, not a bare record', () {
      expect(
        LockoutPalette.semanticsFor(Brightness.light, LockoutAccent.lime),
        isA<LockoutSemantics>(),
      );
    });
  });

  // These two groups carry over the guarantees `schemes_test.dart` held
  // across six schemes. That file is deleted in Task 6, so they live here
  // now, widened from six schemes to the ten brightness-and-accent
  // combinations that replace them.
  group('contrast across all ten combinations', () {
    test('primary and its foreground clear 4.5:1 everywhere', () {
      for (final brightness in Brightness.values) {
        for (final accent in LockoutAccent.all) {
          final s = LockoutPalette.schemeFor(brightness, accent);
          expect(_contrast(s.primary, s.onPrimary),
              greaterThanOrEqualTo(4.5),
              reason: '$brightness + ${accent.key} primary pairing');
          expect(_contrast(s.primaryContainer, s.onPrimaryContainer),
              greaterThanOrEqualTo(4.5),
              reason: '$brightness + ${accent.key} container pairing');
        }
      }
    });

    test('body text clears 4.5:1 on every surface step', () {
      for (final brightness in Brightness.values) {
        final s = LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        for (final surface in [
          s.surface,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ]) {
          expect(_contrast(s.onSurface, surface),
              greaterThanOrEqualTo(4.5));
          expect(_contrast(s.onSurfaceVariant, surface),
              greaterThanOrEqualTo(4.5));
        }
      }
    });
  });

  group('the snackbar pairing', () {
    // The house document's section 8 specifies an `onSurface` background
    // with `surface` text, which is exactly what the inverse pair means.
    // The old assertion targeted `inversePrimary`; this is the retarget.
    test('inverseSurface is onSurface and onInverseSurface is surface', () {
      for (final brightness in Brightness.values) {
        final s = LockoutPalette.schemeFor(brightness, LockoutAccent.lime);
        expect(s.inverseSurface, s.onSurface);
        expect(s.onInverseSurface, s.surface);
      }
    });

    test('the snackbar pairing clears 4.5:1 for every accent', () {
      for (final brightness in Brightness.values) {
        for (final accent in LockoutAccent.all) {
          final s = LockoutPalette.schemeFor(brightness, accent);
          expect(_contrast(s.inverseSurface, s.onInverseSurface),
              greaterThanOrEqualTo(4.5));
          expect(_contrast(s.inverseSurface, s.inversePrimary),
              greaterThanOrEqualTo(4.5),
              reason: 'a SnackBarAction label must be readable');
        }
      }
    });
  });
}
