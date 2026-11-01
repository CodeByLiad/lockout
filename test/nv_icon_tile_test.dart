import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_shapes.dart';
import 'package:lockout/widgets/house/nv_icon_tile.dart';

import 'test_helpers.dart';

ShapeDecoration _decoration(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.descendant(
        of: find.byType(NvIconTile), matching: find.byType(DecoratedBox)))
    .map((d) => d.decoration)
    .whereType<ShapeDecoration>()
    .single;

Widget _host({bool reduce = false, VoidCallback? onTap}) => MaterialApp(
      theme: lockoutTestTheme(lightAppearance),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: Center(
            child: NvIconTile(
              icon: Icons.add,
              shape: LockoutShape.gem,
              label: 'Custom',
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('at rest the tile wears its own shape on secondaryContainer',
      (tester) async {
    await tester.pumpWidget(_host());
    final d = _decoration(tester);
    final border = d.shape as LockoutShapeBorder;
    expect(border.shape, LockoutShape.gem);
    expect(border.morphTo, LockoutShape.circle);
    expect(border.progress, 0);
    expect(d.color, lightAppearance.colors.secondaryContainer);
    expect(tester.widget<Icon>(find.byIcon(Icons.add)).color,
        lightAppearance.colors.onSecondaryContainer);
  });

  testWidgets('pressed, it morphs to a circle on springFast', (tester) async {
    await tester.pumpWidget(_host());
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(NvIconTile)));
    await tester.pump(); // the ticker's first frame is elapsed zero
    await tester.pump(const Duration(milliseconds: 125));
    final mid = (_decoration(tester).shape as LockoutShapeBorder).progress;
    expect(mid, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 200));
    expect((_decoration(tester).shape as LockoutShapeBorder).progress,
        closeTo(1, 0.05));
    await gesture.up();
    await tester.pumpAndSettle();
    expect((_decoration(tester).shape as LockoutShapeBorder).progress, 0);
  });

  testWidgets('under reduced motion the morph is instant', (tester) async {
    await tester.pumpWidget(_host(reduce: true));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(NvIconTile)));
    await tester.pump();
    expect((_decoration(tester).shape as LockoutShapeBorder).progress, 1);
    await gesture.up();
  });

  testWidgets('the whole tile clears the 48dp touch target', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(NvIconTile)).height,
        greaterThanOrEqualTo(48));
  });

  testWidgets('it reports the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(onTap: () => taps++));
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('it is a button to assistive technology', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byType(NvIconTile));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.label, 'Custom');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('a screen reader can press it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(onTap: () => taps++));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byType(NvIconTile));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
