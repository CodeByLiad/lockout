import 'dart:ui' show Tristate;

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
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isTrue);
    expect(node.label, 'Start session');
    // The flag and the label are constructor arguments restated; the action
    // is the one property that separates a usable button from a label that
    // announces itself as "Button". `excludeSemantics` over a
    // `GestureDetector` drops it.
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'a button with no tap action cannot be activated by a screen '
          'reader, whatever it announces itself as',
    );
  });

  testWidgets('a screen reader can press it', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      _host(variant: NvButtonVariant.accent, onPressed: () => presses++),
    );
    await tester.pumpAndSettle();

    semanticTap(tester, find.byType(NvButton));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  testWidgets('a disabled button says so to assistive technology',
      (tester) async {
    await tester
        .pumpWidget(_host(variant: NvButtonVariant.accent, enabled: false));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvButton));
    // `isEnabled` is null when the node carries no enabled state at all, so
    // `isFalse` here asserts both that the state exists and that it says
    // disabled — a screen reader must not announce it as actionable.
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
      reason: 'a disabled button must not offer an activation a screen '
          'reader can take',
    );
  });

  testWidgets('the low-emphasis variants carry no fill of their own',
      (tester) async {
    // Device QA B3: the text variant filled with `surface`, which reads as a
    // solid white pill on any tinted surface — three of them sat on the rest
    // bar looking like filled buttons. Section 8: the text variant has no
    // fill, and outlined and danger carry a border, not a fill.
    for (final variant in const [
      NvButtonVariant.text,
      NvButtonVariant.outlined,
      NvButtonVariant.danger,
    ]) {
      await tester.pumpWidget(_host(variant: variant));
      await tester.pumpAndSettle();

      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      final fill = (container.decoration! as BoxDecoration).color;
      expect(fill?.a ?? 0, 0,
          reason: '$variant paints a fill it should not have');
    }
  });

  testWidgets('an accent button is legible on an accent card',
      (tester) async {
    // Device QA B1: NvButton.accent filled with primaryContainer and
    // NvHeroCard fills with primaryContainer, so the hero's primary action
    // painted itself the same colour as the card under it and vanished.
    await tester.pumpWidget(_host(variant: NvButtonVariant.accent));
    await tester.pumpAndSettle();

    final colors = Theme.of(tester.element(find.byType(NvButton))).colorScheme;
    final container =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
    final fill = (container.decoration! as BoxDecoration).color;

    expect(fill, isNot(colors.primaryContainer),
        reason: 'the accent button is the action ON an accent card; sharing '
            'its fill makes it invisible');
  });

  testWidgets('every filled variant paints a colour the theme resolved',
      (tester) async {
    for (final variant in const [
      NvButtonVariant.accent,
      NvButtonVariant.filled,
      NvButtonVariant.tonal,
    ]) {
      await tester.pumpWidget(_host(variant: variant));
      await tester.pumpAndSettle();

      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      expect(
        (container.decoration! as BoxDecoration).color,
        isA<Color>(),
        reason: '$variant resolved no fill',
      );
      expect(
        container.clipBehavior,
        Clip.antiAlias,
        reason: 'a surface that paints has to clip its paint to its corners',
      );
    }
  });

  testWidgets('a fill-less variant costs no clip layer', (tester) async {
    // `MorphingSurface` reads a non-null colour as "this surface paints" and
    // turns on `Clip.antiAlias` for it. `Colors.transparent` therefore bought
    // a clip layer per outlined, text and danger button to clip nothing.
    for (final variant in const [
      NvButtonVariant.outlined,
      NvButtonVariant.text,
      NvButtonVariant.danger,
    ]) {
      await tester.pumpWidget(_host(variant: variant));
      await tester.pumpAndSettle();

      final container =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      expect(
        (container.decoration! as BoxDecoration).color,
        isNull,
        reason: '$variant asks MorphingSurface to paint a fill it does not '
            'have',
      );
      expect(container.clipBehavior, Clip.none, reason: '$variant clips');
    }
  });

  group('NvIconButton', () {
    Widget host({bool enabled = true, VoidCallback? onPressed}) => MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: Center(
              child: NvIconButton(
                icon: Icons.remove,
                tooltip: 'One rep fewer',
                onPressed: enabled ? (onPressed ?? () {}) : null,
              ),
            ),
          ),
        );

    testWidgets('it is a 48dp pill', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(NvIconButton)).height, 48);
      expect(tester.getSize(find.byType(NvIconButton)).width, 48);
      expect(_radiusOf(tester), 999);
    });

    testWidgets('it rounds to 14dp while pressed', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(NvIconButton)));
      await tester.pumpAndSettle();
      expect(_radiusOf(tester), 14);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_radiusOf(tester), 999);
    });

    testWidgets('it carries a content description', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Section 9: an icon-only button always has one, so the tooltip is
      // required rather than optional.
      final node = tester.getSemantics(find.byType(NvIconButton));
      expect(node.label, 'One rep fewer');
      expect(node.flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the description is useless if the node it sits on cannot '
            'be activated',
      );
    });

    testWidgets('a screen reader can press it', (tester) async {
      var presses = 0;
      await tester.pumpWidget(host(onPressed: () => presses++));
      await tester.pumpAndSettle();

      semanticTap(tester, find.byType(NvIconButton));
      await tester.pumpAndSettle();
      expect(presses, 1);
    });

    testWidgets('a disabled icon button offers no action', (tester) async {
      await tester.pumpWidget(host(enabled: false));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(NvIconButton));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });

    testWidgets('it reports the press', (tester) async {
      var presses = 0;
      await tester.pumpWidget(host(onPressed: () => presses++));
      await tester.tap(find.byType(NvIconButton));
      await tester.pumpAndSettle();
      expect(presses, 1);
    });

    testWidgets('a disabled icon button does not morph', (tester) async {
      await tester.pumpWidget(host(enabled: false));
      await tester.pumpAndSettle();

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(NvIconButton)));
      await tester.pumpAndSettle();
      expect(_radiusOf(tester), 999);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
