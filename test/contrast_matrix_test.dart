import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('allAppearances is the full 2 x 5 x 3 matrix', () {
    expect(allAppearances.length, 30);
  });

  for (final a in allAppearances) {
    test('${a.key}: every text pair clears 4.5:1', () {
      final c = a.colors, s = a.semantics;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (c.onSurface, c.surface),
        'onSurfaceVariant/surface': (c.onSurfaceVariant, c.surface),
        'onPrimary/primary': (c.onPrimary, c.primary),
        'onPrimaryContainer/primaryContainer':
            (c.onPrimaryContainer, c.primaryContainer),
        'onSecondaryContainer/secondaryContainer':
            (c.onSecondaryContainer, c.secondaryContainer),
        'onSuccess/success': (s.onSuccess, s.success),
        'success/surface': (s.success, c.surface),
        'warning/surface': (s.warning, c.surface),
        'danger/surface': (s.danger, c.surface),
        'restDay/surface': (s.restDay, c.surface),
        'inversePrimary/inverseSurface': (c.inversePrimary, c.inverseSurface),
        'onInverseSurface/inverseSurface':
            (c.onInverseSurface, c.inverseSurface),
        'onSurface/surfaceContainerHigh':
            (c.onSurface, c.surfaceContainerHigh),
        'onSurface/surfaceContainerHighest':
            (c.onSurface, c.surfaceContainerHighest),
        'onSurfaceVariant/surfaceContainerHigh':
            (c.onSurfaceVariant, c.surfaceContainerHigh),
        'onSurfaceVariant/surfaceContainerLow':
            (c.onSurfaceVariant, c.surfaceContainerLow),
        'onHeroFill/heroFill': (s.onHeroFill, s.heroFill),
      };
      for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
        expect(_ratio(fg, bg), greaterThanOrEqualTo(4.5),
            reason: '$key in ${a.key}');
      }
    });
  }

  for (final a in allAppearances) {
    test('${a.key}: category ramp clears 3:1 on surface, danger != success',
        () {
      final c = a.colors, s = a.semantics;
      for (final (i, colour) in s.categoryRamp.indexed) {
        expect(_ratio(colour, c.surface), greaterThanOrEqualTo(3.0),
            reason: 'categoryRamp[$i] in ${a.key}');
      }
      expect(s.danger, isNot(s.success), reason: 'danger == success');
    });
  }
}
