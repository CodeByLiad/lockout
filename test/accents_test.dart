import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('there are five accents and lime is the default', () {
    expect(LockoutAccent.all.length, 5);
    expect(LockoutAccent.fallback, LockoutAccent.lime);
    expect(LockoutAccent.fallback.key, 'lime');
  });

  test('gold is gone — it belongs to another app in the family', () {
    expect(LockoutAccent.all.map((a) => a.key), isNot(contains('gold')));
    for (final accent in LockoutAccent.all) {
      expect(accent.accent, isNot(const Color(0xFFFFB938)));
    }
  });

  test('every accent carries its ink at 4.5:1 or better', () {
    for (final accent in LockoutAccent.all) {
      expect(_contrast(accent.accent, accent.ink), greaterThanOrEqualTo(4.5),
          reason: '${accent.key} fails the house contrast rule');
    }
  });

  test('the identity accent is Rep lime', () {
    expect(LockoutAccent.lime.accent, const Color(0xFFC2EE7B));
    expect(LockoutAccent.lime.ink, const Color(0xFF1F2E00));
    expect(LockoutAccent.lime.name, 'Rep lime');
  });

  test('byKey maps every legacy scheme key onto an accent', () {
    expect(LockoutAccent.byKey('graphite'), LockoutAccent.steel);
    expect(LockoutAccent.byKey('paper'), LockoutAccent.steel);
    expect(LockoutAccent.byKey('ember'), LockoutAccent.coral);
    expect(LockoutAccent.byKey('linen'), LockoutAccent.coral);
    expect(LockoutAccent.byKey('indigo'), LockoutAccent.violet);
    expect(LockoutAccent.byKey('frost'), LockoutAccent.teal);
    expect(LockoutAccent.byKey('dynamic'), LockoutAccent.lime);
  });

  test('byKey falls back on junk and on an empty string', () {
    expect(LockoutAccent.byKey('not-an-accent'), LockoutAccent.lime);
    expect(LockoutAccent.byKey(''), LockoutAccent.lime);
  });

  test('every accent name is sentence case', () {
    for (final accent in LockoutAccent.all) {
      expect(accent.name, isNot(accent.name.toUpperCase()),
          reason: 'the house document forbids all-caps (section 4.2)');
    }
  });
}
