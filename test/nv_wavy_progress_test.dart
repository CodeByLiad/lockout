import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_wavy_progress.dart';

import 'test_helpers.dart';

Widget _host({required double value, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(body: NvWavyProgress(value: value)),
    ),
  );
}

WavePainter _painterOf(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(NvWavyProgress),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return paint.painter! as WavePainter;
}

void main() {
  testWidgets('it reports its value to assistive technology', (tester) async {
    await tester.pumpWidget(_host(value: 0.5));
    await tester.pump();
    expect(tester.getSemantics(find.byType(NvWavyProgress)).value, '50%');
  });

  testWidgets('a value past the top clamps rather than throwing',
      (tester) async {
    await tester.pumpWidget(_host(value: 1.4));
    await tester.pump();
    expect(tester.getSemantics(find.byType(NvWavyProgress)).value, '100%');
    expect(_painterOf(tester).progress, 1.0);
  });

  testWidgets('the wave drifts on its own', (tester) async {
    await tester.pumpWidget(_host(value: 0.5));
    await tester.pump();
    final first = _painterOf(tester);

    await tester.pump(const Duration(milliseconds: 400));
    expect(
      _painterOf(tester).phase,
      isNot(first.phase),
      reason: 'section 6: the wave is the one thing in the app that moves on '
          'its own',
    );
  });

  testWidgets('reduced motion stops the wave', (tester) async {
    await tester.pumpWidget(_host(value: 0.5, reduceMotion: true));
    await tester.pump();
    final first = _painterOf(tester);

    await tester.pump(const Duration(milliseconds: 400));
    expect(
      _painterOf(tester).phase,
      first.phase,
      reason: 'section 6 stops the wave when the user asked the OS to remove '
          'animations',
    );
  });

  testWidgets('the wave colour comes from the theme', (tester) async {
    await tester.pumpWidget(_host(value: 0.5));
    await tester.pump();

    final colors =
        Theme.of(tester.element(find.byType(NvWavyProgress))).colorScheme;
    expect(_painterOf(tester).wave, colors.primary);
    expect(_painterOf(tester).track, colors.surfaceContainerHighest);
  });
}
