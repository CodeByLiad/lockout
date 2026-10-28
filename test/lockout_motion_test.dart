import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_motion.dart';

void main() {
  group('the three tiers match the house document', () {
    test('springFast settles in 250ms and overshoots', () {
      expect(LockoutMotion.springFast.duration,
          const Duration(milliseconds: 250));
      expect(LockoutMotion.springFast.curve, LockoutMotion.spring);
    });

    test('springDefault settles in 450ms and overshoots', () {
      expect(LockoutMotion.springDefault.duration,
          const Duration(milliseconds: 450));
      expect(LockoutMotion.springDefault.curve, LockoutMotion.spring);
    });

    test('effects runs 200ms and never overshoots', () {
      expect(LockoutMotion.effects.duration,
          const Duration(milliseconds: 200));

      // The house document states that colour and opacity must not bounce.
      for (var t = 0.0; t <= 1.0; t += 0.01) {
        final v = LockoutMotion.effects.curve.transform(t);
        expect(v, lessThanOrEqualTo(1.0),
            reason: 'effects overshot at t=$t with $v');
        expect(v, greaterThanOrEqualTo(0.0));
      }
    });

    test('the spring curve passes its target and settles back', () {
      var peak = 0.0;
      for (var t = 0.0; t <= 1.0; t += 0.005) {
        final v = LockoutMotion.spring.transform(t);
        if (v > peak) peak = v;
      }
      expect(peak, greaterThan(1.0),
          reason: 'the spring must overshoot, not ease');
      expect(LockoutMotion.spring.transform(1.0), closeTo(1.0, 0.0001));
    });
  });

  group('reduced motion collapses every tier', () {
    testWidgets('each tier reports zero when animations are disabled',
        (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      );

      expect(LockoutMotion.springFast.durationFor(captured), Duration.zero);
      expect(LockoutMotion.springDefault.durationFor(captured), Duration.zero);
      expect(LockoutMotion.effects.durationFor(captured), Duration.zero);
    });

    testWidgets('each tier reports its real duration otherwise',
        (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      );

      expect(LockoutMotion.springFast.durationFor(captured),
          const Duration(milliseconds: 250));
      expect(LockoutMotion.springDefault.durationFor(captured),
          const Duration(milliseconds: 450));
      expect(LockoutMotion.effects.durationFor(captured),
          const Duration(milliseconds: 200));
    });
  });
}
