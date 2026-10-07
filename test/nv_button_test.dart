import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_button.dart';

import 'test_helpers.dart';

Widget _host({
  required NvButtonVariant variant,
  bool large = false,
  bool enabled = true,
  bool reduceMotion = false,
  VoidCallback? onPressed,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: Center(
          child: NvButton(
            variant: variant,
            label: 'Start session',
            onPressed: enabled ? (onPressed ?? () {}) : null,
            large: large,
          ),
        ),
      ),
    ),
  );
}

double _radiusOf(WidgetTester tester) {
  final container =
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
  final decoration = container.decoration! as BoxDecoration;
  return (decoration.borderRadius! as BorderRadius).topLeft.x;
}

void main() {
  testWidgets('it is a pill at rest', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 999);
  });

  testWidgets('it morphs to 12dp under the finger and back', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 12);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 999);
  });

  testWidgets('a large button morphs to 16dp instead', (tester) async {
    await tester
        .pumpWidget(_host(variant: NvButtonVariant.accent, large: true));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester), 16);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('it is at least 48dp tall', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.tonal));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(NvButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('a large button is 60dp tall', (tester) async {
    await tester
        .pumpWidget(_host(variant: NvButtonVariant.accent, large: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(NvButton)).height, 60);
  });

  testWidgets('reduced motion lands the morph instantly', (tester) async {
    await tester.pumpWidget(
      _host(variant: NvButtonVariant.accent, reduceMotion: true),
    );
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pump();
    expect(
      _radiusOf(tester),
      12,
      reason: 'with animations off the radius must land immediately, not '
          'spring — this is the whole reason the control is bespoke (D10)',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('it reports the press', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      _host(variant: NvButtonVariant.accent, onPressed: () => presses++),
    );
    await tester.tap(find.text('Start session'));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  testWidgets('a disabled button does not morph under the finger',
      (tester) async {
    await tester
        .pumpWidget(_host(variant: NvButtonVariant.accent, enabled: false));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Start session')));
    await tester.pumpAndSettle();
    expect(
      _radiusOf(tester),
      999,
      reason: 'a disabled button has no press state to shape-shift into',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('it is a button to assistive technology', (tester) async {
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvButton));
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(node.hasFlag(SemanticsFlag.isEnabled), isTrue);
    expect(node.label, 'Start session');
  });

  testWidgets('a disabled button says so to assistive technology',
      (tester) async {
    await tester
        .pumpWidget(_host(variant: NvButtonVariant.accent, enabled: false));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvButton));
    expect(node.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(node.hasFlag(SemanticsFlag.isEnabled), isFalse);
  });

  testWidgets('every variant paints a colour the theme resolved',
      (tester) async {
    for (final variant in NvButtonVariant.values) {
      await tester.pumpWidget(_host(variant: variant));
      await tester.pumpAndSettle();

      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      expect(
        (container.decoration! as BoxDecoration).color,
        isA<Color>(),
        reason: '$variant resolved no fill',
      );
    }
  });
}
