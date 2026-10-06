import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/cookie_border.dart';

/// Samples the outline's radius at [steps] angles around its centre.
List<double> _radiiOf(CookieBorder border, Rect rect, {int steps = 720}) {
  final path = border.getOuterPath(rect);
  final metrics = path.computeMetrics().toList();
  expect(metrics.length, 1, reason: 'the outline must be one closed contour');
  final metric = metrics.single;

  final centre = rect.center;
  final radii = <double>[];
  for (var i = 0; i < steps; i++) {
    final tangent = metric.getTangentForOffset(metric.length * i / steps)!;
    radii.add((tangent.position - centre).distance);
  }
  return radii;
}

/// Counts how many times the sampled radius turns from rising to falling.
int _lobeCount(List<double> radii) {
  var maxima = 0;
  for (var i = 0; i < radii.length; i++) {
    final prev = radii[(i - 1 + radii.length) % radii.length];
    final next = radii[(i + 1) % radii.length];
    if (radii[i] > prev && radii[i] >= next) maxima++;
  }
  return maxima;
}

void main() {
  const rect = Rect.fromLTWH(0, 0, 100, 100);

  group('geometry', () {
    test('the outline is closed', () {
      final path = const CookieBorder(lobes: 6, amplitude: 0.07)
          .getOuterPath(rect);
      final metric = path.computeMetrics().single;
      expect(metric.isClosed, isTrue);
    });

    for (final border in const [
      CookieBorder.rest,
      CookieBorder.training,
      CookieBorder.streak,
      CookieBorder.achievement,
    ]) {
      test('${border.lobes} lobes produce ${border.lobes} maxima', () {
        expect(_lobeCount(_radiiOf(border, rect)), border.lobes);
      });
    }

    test('amplitude bounds the radius around the base circle', () {
      const border = CookieBorder(lobes: 6, amplitude: 0.07);
      final radii = _radiiOf(border, rect);
      // The lobe PEAKS touch the rect's inscribed circle, so the base circle
      // the amplitude swings around sits a factor of (1 + amplitude) inside
      // it. See `an oblong rect still yields a bounded outline`.
      final base = rect.shortestSide / 2 / 1.07;
      expect(radii.reduce(math.max),
          closeTo(base * (1 + 0.07), base * 0.02));
      expect(radii.reduce(math.min),
          closeTo(base * (1 - 0.07), base * 0.02));
    });

    test('an oblong rect still yields a bounded outline', () {
      const border = CookieBorder(lobes: 9, amplitude: 0.06);
      final path = border.getOuterPath(const Rect.fromLTWH(0, 0, 200, 80));
      expect(path.getBounds().width, lessThanOrEqualTo(200));
      expect(path.getBounds().height, lessThanOrEqualTo(80));
    });
  });

  group('lerp', () {
    test('two borders of the same lobe count interpolate their amplitude', () {
      const a = CookieBorder(lobes: 6, amplitude: 0.00);
      const b = CookieBorder(lobes: 6, amplitude: 0.10);
      final mid = ShapeBorder.lerp(a, b, 0.5)! as CookieBorder;
      expect(mid.lobes, 6);
      expect(mid.amplitude, closeTo(0.05, 0.0001));
    });

    test('a lobe-count mismatch throws rather than drawing a wrong path', () {
      const a = CookieBorder(lobes: 6, amplitude: 0.07);
      const b = CookieBorder(lobes: 9, amplitude: 0.06);
      // `throwsArgumentError`, not `throwsAssertionError`: an assert is
      // stripped from a release build, so the silent wrong path this guards
      // against was precisely what would have shipped.
      expect(() => ShapeBorder.lerp(a, b, 0.5), throwsArgumentError);
      expect(() => ShapeBorder.lerp(b, a, 0.5), throwsArgumentError);
    });
  });

  group('equality', () {
    test('two borders with the same parameters are equal', () {
      expect(const CookieBorder(lobes: 4, amplitude: 0.1),
          const CookieBorder(lobes: 4, amplitude: 0.1));
    });

    test('the named registers carry the documented parameters', () {
      expect(CookieBorder.rest.lobes, 4);
      expect(CookieBorder.rest.amplitude, 0.10);
      expect(CookieBorder.training.lobes, 6);
      expect(CookieBorder.training.amplitude, 0.07);
      expect(CookieBorder.streak.lobes, 9);
      expect(CookieBorder.streak.amplitude, 0.06);
      expect(CookieBorder.achievement.lobes, 12);
      expect(CookieBorder.achievement.amplitude, 0.04);
    });
  });
}
