import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/widgets/house/nv_icon_tile.dart';

import 'test_helpers.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _host({VoidCallback? onTap, Color color = const Color(0xFF884422)}) {
  return MaterialApp(
    theme: lockoutTestTheme(),
    home: Scaffold(
      body: NvIconTile(
        icon: Icons.restaurant,
        color: color,
        label: 'Log food',
        onTap: onTap ?? () {},
      ),
    ),
  );
}

Container _tileContainer(WidgetTester tester) {
  return tester.widget<Container>(
    find
        .descendant(
          of: find.byType(NvIconTile),
          matching: find.byType(Container),
        )
        .first,
  );
}

void main() {
  testWidgets('the tile is 40dp square', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final size = tester.getSize(
      find
          .descendant(
            of: find.byType(NvIconTile),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(size.width, 40);
    expect(size.height, 40);
  });

  testWidgets('the tile is one consistent squircle, 14dp', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final decoration = _tileContainer(tester).decoration! as BoxDecoration;
    expect((decoration.borderRadius! as BorderRadius).topLeft.x, 14);
  });

  testWidgets('the whole tile clears the 48dp touch target', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(NvIconTile)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the fill is the category colour it was handed',
      (tester) async {
    await tester.pumpWidget(_host(color: const Color(0xFF123456)));
    await tester.pumpAndSettle();

    final decoration = _tileContainer(tester).decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF123456));
  });

  testWidgets('the glyph follows the fill it was handed, on both sides',
      (tester) async {
    // The defect this guards: the glyph was pinned to `colorScheme.surface`,
    // which is only legible on a fill the scheme happens to pair with it.
    // Hand the tile a light fill and a dark one in the SAME theme — a glyph
    // read off the theme cannot tell them apart, so it comes back identical
    // and this fails.
    await tester.pumpWidget(_host(color: const Color(0xFFF2F2F2)));
    await tester.pumpAndSettle();
    final onLightFill = tester.widget<Icon>(find.byType(Icon)).color;

    await tester.pumpWidget(_host(color: const Color(0xFF101010)));
    await tester.pumpAndSettle();
    final onDarkFill = tester.widget<Icon>(find.byType(Icon)).color;

    expect(onLightFill, isNot(onDarkFill),
        reason: 'one theme, two fills: a glyph that does not read the fill '
            'paints the same colour on both and is invisible on one');
    expect(onLightFill, LockoutSemantics.onCategoryColor(
        const Color(0xFFF2F2F2)));
    expect(onDarkFill, LockoutSemantics.onCategoryColor(
        const Color(0xFF101010)));
  });

  testWidgets('the glyph clears 3:1 on a fill the scheme does not pair with',
      (tester) async {
    // Deliberately the mismatched pairs, not the ramp: every ramp colour
    // already clears 3:1 against `colorScheme.surface`, so a ramp loop
    // passes against the pinned glyph too and guards nothing. A fill on the
    // same side as the theme's own `surface` — a dark fill under the dark
    // theme, a light one under the light theme — is where reading the glyph
    // off the theme collapses to about 1:1.
    Future<double> contrastOn(TestAppearance appearance, Color fill) async {
      await tester.pumpWidget(MaterialApp(
        theme: lockoutTestTheme(appearance),
        home: Scaffold(
          body: NvIconTile(
            icon: Icons.restaurant,
            color: fill,
            label: 'Log food',
            onTap: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return _contrast(fill, tester.widget<Icon>(find.byType(Icon)).color!);
    }

    expect(await contrastOn(darkAppearance, const Color(0xFF101010)),
        greaterThanOrEqualTo(3.0));
    expect(await contrastOn(lightAppearance, const Color(0xFFF2F2F2)),
        greaterThanOrEqualTo(3.0));
  });

  testWidgets('the label sits under the tile in sentence case',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Log food'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Log food')).dy,
      greaterThan(tester.getTopLeft(find.byType(Icon)).dy),
    );
  });

  testWidgets('it reports the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(onTap: () => taps++));
    await tester.tap(find.text('Log food'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('it is a button to assistive technology', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvIconTile));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.label, 'Log food');
    // The flag and the label are the constructor arguments read back; the
    // action is the part a screen reader actually needs.
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'excludeSemantics over the InkWell drops its tap action, so '
          'the tile announces as a button nothing can press',
    );
  });

  testWidgets('a screen reader can press it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(onTap: () => taps++));
    await tester.pumpAndSettle();

    // Not `tester.tap`: a synthetic pointer event reaches the InkWell
    // whether or not semantics expose the action.
    final node = tester.getSemantics(find.byType(NvIconTile));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
