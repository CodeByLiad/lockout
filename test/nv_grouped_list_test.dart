import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_grouped_list.dart';

import 'test_helpers.dart';

Widget _host(int count, {VoidCallback? onTap, bool tappable = true}) {
  return MaterialApp(
    theme: lockoutTestTheme(),
    home: Scaffold(
      body: NvGroupedList(
        children: [
          for (var i = 0; i < count; i++)
            NvListItem(
              title: 'Row $i',
              supporting: '3 sets',
              onTap: tappable ? (onTap ?? () {}) : null,
            ),
        ],
      ),
    ),
  );
}

double _rowRadius(WidgetTester tester, String title) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.widgetWithText(NvListItem, title),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (((container.decoration! as BoxDecoration).borderRadius!)
          as BorderRadius)
      .topLeft
      .x;
}

BorderRadius _clipRadius(WidgetTester tester, String title) {
  final clip = tester.widget<ClipRRect>(
    find
        .ancestor(
          of: find.widgetWithText(NvListItem, title),
          matching: find.byType(ClipRRect),
        )
        .first,
  );
  return clip.borderRadius as BorderRadius;
}

void main() {
  testWidgets('a row clears the 72dp minimum height', (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(NvListItem).first).height,
      greaterThanOrEqualTo(72),
    );
  });

  testWidgets('the rows sit 3dp apart', (tester) async {
    await tester.pumpWidget(_host(2));
    await tester.pumpAndSettle();

    final firstBottom = tester.getBottomLeft(find.byType(NvListItem).at(0)).dy;
    final secondTop = tester.getTopLeft(find.byType(NvListItem).at(1)).dy;
    expect(secondTop - firstBottom, 3);
  });

  testWidgets('the group is large on its outer corners and small inside',
      (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();

    expect(_clipRadius(tester, 'Row 0').topLeft.x, 26);
    expect(_clipRadius(tester, 'Row 0').bottomLeft.x, 8);
    expect(_clipRadius(tester, 'Row 1').topLeft.x, 8);
    expect(_clipRadius(tester, 'Row 2').bottomLeft.x, 26);
  });

  testWidgets('a single child is large on all four corners', (tester) async {
    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();

    final radius = _clipRadius(tester, 'Row 0');
    expect(radius.topLeft.x, 26);
    expect(radius.bottomLeft.x, 26);
  });

  testWidgets('a row is 8dp at rest and 20dp under the finger',
      (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();
    expect(_rowRadius(tester, 'Row 1'), 8);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await tester.pumpAndSettle();
    expect(_rowRadius(tester, 'Row 1'), 20);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rowRadius(tester, 'Row 1'), 8);
  });

  testWidgets('a row with no tap handler does not morph', (tester) async {
    await tester.pumpWidget(_host(3, tappable: false));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Row 1')));
    await tester.pumpAndSettle();
    expect(
      _rowRadius(tester, 'Row 1'),
      8,
      reason: 'a row that does nothing has no press state to shape-shift into',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('it reports the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(3, onTap: () => taps++));
    await tester.tap(find.text('Row 1'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('a row fills with surfaceContainer', (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();

    final colors = Theme.of(tester.element(find.byType(NvGroupedList)))
        .colorScheme;
    final container = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.widgetWithText(NvListItem, 'Row 1'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((container.decoration! as BoxDecoration).color,
        colors.surfaceContainer);
  });

  testWidgets('a tappable row is a button to assistive technology',
      (tester) async {
    await tester.pumpWidget(_host(3));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvListItem).first);
    expect(node.flagsCollection.isButton, isTrue);
  });

  testWidgets('a screen reader can press a row', (tester) async {
    // `isButton` above is the literal constructor argument read back two
    // lines into `build`, and it is true of a row a screen reader cannot
    // activate at all — the exact assertion shape that hid an earlier
    // Critical on `NvButton`. `NvListItem` is the most-instantiated control
    // in the app, so the gap would have been the widest here.
    var taps = 0;
    await tester.pumpWidget(_host(3, onTap: () => taps++));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvListItem).first);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue,
        reason: 'a row announced as a button must offer an activation');

    // The row's own `Semantics` deliberately carries NO label, so the title
    // and the supporting line merge up from the `Text` widgets and are
    // announced once each. Pinned because the merge is a concatenation, not
    // a rejection: the day someone adds `label: title` to that annotation to
    // "fix" an unlabelled row, every row in the app starts announcing its
    // title twice, which is exactly what `NvSegmentedButton` was doing.
    expect(node.label, 'Row 0\n3 sets',
        reason: 'the row announces its title and its supporting line once '
            'each, in order');

    semanticTap(tester, find.byType(NvListItem).first);
    await tester.pumpAndSettle();
    expect(taps, 1,
        reason: 'and that activation must reach the callback the row was '
            'given, not merely exist on the node');
  });

  testWidgets('an inert row offers no activation', (tester) async {
    // The other half: `onTap: null` makes the row inert by construction, so
    // a screen reader must not be offered a press that does nothing.
    await tester.pumpWidget(_host(3, tappable: false));
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(NvListItem).first);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
  });

  testWidgets('an empty group renders nothing', (tester) async {
    await tester.pumpWidget(_host(0));
    await tester.pumpAndSettle();
    expect(find.byType(NvListItem), findsNothing);
  });

  testWidgets('the supporting text and trailing slot both render',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: const Scaffold(
          body: NvGroupedList(
            children: [
              NvListItem(
                title: 'Bench press',
                supporting: '3 sets',
                trailing: Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 sets'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
