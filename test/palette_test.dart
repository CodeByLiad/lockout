import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/theme/palette.dart';
import 'package:lockout/theme/scheme_style.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

// The scheme is generated from the accent seed now (deviation D11), so the
// groups that pinned authored house neutrals are gone. What is left to pin
// is that the generator is wired the way the spec says, and the handful of
// roles that are still authored. Text-pair contrast across every generated
// appearance lives in `contrast_matrix_test.dart`.
void main() {
  group('the framework generator is what we think it is', () {
    test('fromSeed honours dynamicSchemeVariant on the pinned SDK', () {
      final tonal = ColorScheme.fromSeed(
          seedColor: LockoutAccent.lime.accent,
          dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot);
      final vivid = ColorScheme.fromSeed(
          seedColor: LockoutAccent.lime.accent,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant);
      expect(tonal.primary, isNot(vivid.primary));
    });
  });

  group('schemeFor', () {
    for (final style in LockoutSchemeStyle.values) {
      for (final accent in LockoutAccent.all) {
        for (final b in Brightness.values) {
          test('${b.name}|${accent.key}|${style.key} is fromSeed itself', () {
            final expected = ColorScheme.fromSeed(
              seedColor: accent.accent,
              brightness: b,
              dynamicSchemeVariant: style.variant,
            );
            final actual = LockoutPalette.schemeFor(b, accent, style);
            expect(actual.brightness, b);
            expect(actual.primary, expected.primary);
            expect(actual.surface, expected.surface);
            expect(actual.surfaceContainer, expected.surfaceContainer);
            expect(actual.secondaryContainer, expected.secondaryContainer);
            expect(actual.surfaceTint, Colors.transparent);
          });
        }
      }
    }

    test('in light, the accent now changes primary (complaint 1)', () {
      final lime = LockoutPalette.schemeFor(
          Brightness.light, LockoutAccent.lime, LockoutSchemeStyle.tonal);
      final violet = LockoutPalette.schemeFor(
          Brightness.light, LockoutAccent.violet, LockoutSchemeStyle.tonal);
      expect(lime.primary, isNot(violet.primary));
      expect(lime.surface, isNot(violet.surface),
          reason: 'the accent must tint the surfaces too (complaint 2)');
    });

    test('style maps to the variant the spec names', () {
      expect(LockoutSchemeStyle.tonal.variant, DynamicSchemeVariant.tonalSpot);
      expect(LockoutSchemeStyle.vibrant.variant, DynamicSchemeVariant.vibrant);
      expect(LockoutSchemeStyle.expressive.variant,
          DynamicSchemeVariant.expressive);
    });

    test('byKey: known keys round-trip, junk falls back to tonal', () {
      for (final s in LockoutSchemeStyle.values) {
        expect(LockoutSchemeStyle.byKey(s.key), s);
      }
      expect(LockoutSchemeStyle.byKey('neon'), LockoutSchemeStyle.tonal);
      expect(LockoutSchemeStyle.byKey(''), LockoutSchemeStyle.tonal);
    });
  });

  group('semanticsFor', () {
    test('the hero keeps the exact identity accent in every style', () {
      for (final style in LockoutSchemeStyle.values) {
        for (final b in Brightness.values) {
          final scheme =
              LockoutPalette.schemeFor(b, LockoutAccent.lime, style);
          final s =
              LockoutPalette.semanticsFor(b, LockoutAccent.lime, scheme);
          expect(s.heroFill, LockoutAccent.lime.accent);
          expect(s.onHeroFill, LockoutAccent.lime.ink);
        }
      }
    });

    test('success and the ramp keep their branch-1 values', () {
      final light = LockoutPalette.semanticsFor(Brightness.light,
          LockoutAccent.lime,
          LockoutPalette.schemeFor(Brightness.light, LockoutAccent.lime,
              LockoutSchemeStyle.vibrant));
      expect(light.success, const Color(0xFF1E6E47));
      expect(light.categoryRamp.first, const Color(0xFF365E27));
    });

    test('there are two ramps, one per brightness, not one per accent', () {
      LockoutSemantics dark(LockoutAccent accent) => LockoutPalette.semanticsFor(
          Brightness.dark,
          accent,
          LockoutPalette.schemeFor(
              Brightness.dark, accent, LockoutSchemeStyle.tonal));
      expect(dark(LockoutAccent.lime).categoryRamp,
          dark(LockoutAccent.coral).categoryRamp);
    });

    test('every ramp entry clears 4.5 on its own tinted chip, on every '
        'generated surface', () {
      // `week_day_row.dart` paints a ramp colour as 12px text over a 16%
      // alpha wash of itself. The ramp is still authored but the surface
      // under it is generated now and moves with accent and style, so this
      // sweeps all of them rather than the one lime surface it used to.
      for (final style in LockoutSchemeStyle.values) {
        for (final accent in LockoutAccent.all) {
          for (final brightness in Brightness.values) {
            final scheme = LockoutPalette.schemeFor(brightness, accent, style);
            final semantics =
                LockoutPalette.semanticsFor(brightness, accent, scheme);
            for (final colour in semantics.categoryRamp) {
              final chip = Color.alphaBlend(
                  colour.withValues(alpha: 0.16), scheme.surfaceContainer);
              expect(_contrast(colour, chip), greaterThanOrEqualTo(4.5),
                  reason: '$colour on its own chip in '
                      '${brightness.name}|${accent.key}|${style.key}');
            }
          }
        }
      }
    });

    test('the ramp has eight entries, as categoryAt assumes', () {
      expect(
        LockoutPalette.semanticsFor(
                Brightness.dark,
                LockoutAccent.lime,
                LockoutPalette.schemeFor(Brightness.dark, LockoutAccent.lime,
                    LockoutSchemeStyle.tonal))
            .categoryRamp.length,
        8,
      );
    });
  });

  group('LockoutSemantics.onCategoryColor', () {
    // Ported from `schemes_test.dart`, which took it from
    // `theme_tokens_test.dart` when `JinatraTokens.onAccentColor` became
    // this. It ran over six schemes' ramps; it now runs over the two this
    // palette authors — the ramp is per brightness and identical across
    // accents, which the group above pins — so the coverage is the same
    // set of colours.
    //
    // A luminance-direction check against two literal backgrounds, which is
    // all `day_colours_test.dart` carries, would not catch a mid-tone accent
    // resolving the wrong way. That is what these four hold.
    List<Color> rampFor(Brightness brightness) =>
        LockoutPalette.semanticsFor(
                brightness,
                LockoutAccent.lime,
                LockoutPalette.schemeFor(
                    brightness, LockoutAccent.lime, LockoutSchemeStyle.tonal))
            .categoryRamp;

    test('every ramp accent of every scheme can carry a readable label', () {
      for (final brightness in Brightness.values) {
        for (final accent in rampFor(brightness)) {
          expect(
            _contrast(accent, LockoutSemantics.onCategoryColor(accent)),
            greaterThanOrEqualTo(3.0),
            reason: '$brightness ${accent.toARGB32().toRadixString(16)}',
          );
        }
      }
    });

    test('the label is the real-contrast argmax over every ramp accent', () {
      for (final brightness in Brightness.values) {
        for (final accent in rampFor(brightness)) {
          final onDark = _contrast(accent, const Color(0xFF111111));
          final onLight = _contrast(accent, const Color(0xFFFFFFFF));
          final expected = onDark >= onLight
              ? const Color(0xFF111111)
              : const Color(0xFFFFFFFF);
          expect(
            LockoutSemantics.onCategoryColor(accent),
            expected,
            reason: '$brightness ${accent.toARGB32().toRadixString(16)} '
                'onDark=$onDark onLight=$onLight',
          );
        }
      }
    });

    test('picks the higher-contrast of near-black and white, not a threshold',
        () {
      expect(LockoutSemantics.onCategoryColor(const Color(0xFFFFE24A)),
          const Color(0xFF111111));
      expect(LockoutSemantics.onCategoryColor(const Color(0xFF1E44D6)),
          const Color(0xFFFFFFFF));
    });

    /// Ported from `theme_tokens_test.dart` via `schemes_test.dart`. No
    /// scheme authors #E23A2E, so this is not a palette case — it is kept as
    /// a pure-function pin, because it is the mid-tone a luminance-threshold
    /// implementation resolves to white and the argmax resolves to
    /// near-black, and that is the mistake being guarded.
    test('regression: #E23A2E resolves to near-black, not white', () {
      expect(LockoutSemantics.onCategoryColor(const Color(0xFFE23A2E)),
          const Color(0xFF111111));
    });
  });
}
