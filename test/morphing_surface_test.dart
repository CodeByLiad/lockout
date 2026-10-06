import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_motion.dart';
import 'package:lockout/widgets/morphing_surface.dart';

double _radiusOf(WidgetTester tester) {
  final container = tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
  final decoration = container.decoration! as BoxDecoration;
  return (decoration.borderRadius! as BorderRadius).topLeft.x;
}

Widget _host({required bool active, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      home: Scaffold(
        body: MorphingSurface(
          restRadius: 24,
          activeRadius: 12,
          active: active,
          child: const SizedBox(width: 120, height: 48),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('it paints the rest radius when inactive', (tester) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 24);
  });

  testWidgets('it morphs to the active radius', (tester) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(active: true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_radiusOf(tester), lessThan(24),
        reason: 'the radius must be in motion, not snapped');

    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 12);
  });

  testWidgets('it uses the fast tier, not a one-off duration', (tester) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();
    final container = tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
    expect(container.duration, LockoutMotion.springFast.duration);
    expect(container.curve, LockoutMotion.springFast.curve);
  });

  testWidgets('reduced motion snaps instead of springing', (tester) async {
    await tester.pumpWidget(_host(active: false, reduceMotion: true));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(active: true, reduceMotion: true));
    await tester.pump();
    expect(_radiusOf(tester), 12,
        reason: 'the morph must be instant under "remove animations"');
  });

  testWidgets('an active scale shrinks the surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MorphingSurface(
            restRadius: 999,
            activeRadius: 12,
            active: true,
            activeScale: 0.97,
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.97);
  });
}
