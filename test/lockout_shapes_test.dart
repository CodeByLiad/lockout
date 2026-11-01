import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_shapes.dart';

void main() {
  const rect = Rect.fromLTWH(10, 20, 40, 40);

  for (final shape in LockoutShape.values) {
    test('$shape stays inside the rect it is given', () {
      final bounds = LockoutShapeBorder(shape).getOuterPath(rect).getBounds();
      expect(bounds.left, greaterThanOrEqualTo(rect.left - 0.01));
      expect(bounds.top, greaterThanOrEqualTo(rect.top - 0.01));
      expect(bounds.right, lessThanOrEqualTo(rect.right + 0.01));
      expect(bounds.bottom, lessThanOrEqualTo(rect.bottom + 0.01));
      expect(bounds.width, greaterThan(rect.width * 0.5),
          reason: 'the shape should fill most of its box');
    });
  }

  test('the four registers are the four cookies', () {
    expect(LockoutShape.rest, LockoutShape.cookie4);
    expect(LockoutShape.training, LockoutShape.cookie6);
    expect(LockoutShape.streak, LockoutShape.cookie9);
    expect(LockoutShape.achievement, LockoutShape.cookie12);
    expect(LockoutShape.values.where((s) => s.isCookie).length, 4);
  });

  test('a morph at 0 and 1 matches its two ends', () {
    Rect b(ShapeBorder s) => s.getOuterPath(rect).getBounds();
    const m0 = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 0);
    const m1 = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1);
    expect(b(m0), _near(b(const LockoutShapeBorder(LockoutShape.gem))));
    expect(b(m1), _near(b(const LockoutShapeBorder(LockoutShape.circle))));
  });

  test('progress outside [0, 1] is clamped, so a spring overshoot is safe',
      () {
    const over = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1.3);
    const end = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1);
    expect(over.getOuterPath(rect).getBounds(),
        _near(end.getOuterPath(rect).getBounds()));
  });

  test('lerp between two borders of one morph interpolates progress', () {
    const a = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 0);
    const b = LockoutShapeBorder(LockoutShape.gem,
        morphTo: LockoutShape.circle, progress: 1);
    final mid = a.lerpTo(b, 0.5)! as LockoutShapeBorder;
    expect(mid.progress, closeTo(0.5, 1e-9));
  });

  test('equality is value equality', () {
    expect(const LockoutShapeBorder(LockoutShape.gem),
        const LockoutShapeBorder(LockoutShape.gem));
    expect(const LockoutShapeBorder(LockoutShape.gem),
        isNot(const LockoutShapeBorder(LockoutShape.arch)));
  });
}

Matcher _near(Rect r) => predicate<Rect>(
    (x) =>
        (x.left - r.left).abs() < 0.5 &&
        (x.top - r.top).abs() < 0.5 &&
        (x.right - r.right).abs() < 0.5 &&
        (x.bottom - r.bottom).abs() < 0.5,
    'within 0.5 of $r');
