import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/connected_group.dart';

List<BorderRadius> _radiiOf(WidgetTester tester) {
  return tester
      .widgetList<ClipRRect>(find.descendant(
        of: find.byType(ConnectedGroup),
        matching: find.byType(ClipRRect),
      ))
      .map((c) => c.borderRadius as BorderRadius)
      .toList();
}

void main() {
  Widget host(int count) => MaterialApp(
        home: Scaffold(
          body: ConnectedGroup(
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(key: ValueKey(i), height: 72, child: Text('row $i')),
            ],
          ),
        ),
      );

  testWidgets('the first and last child carry the large outer corners',
      (tester) async {
    await tester.pumpWidget(host(4));
    await tester.pumpAndSettle();

    final radii = _radiiOf(tester);
    expect(radii.length, 4);

    expect(radii.first.topLeft.x, LockoutTheme.radiusGroupEnd);
    expect(radii.first.topRight.x, LockoutTheme.radiusGroupEnd);
    expect(radii.first.bottomLeft.x, LockoutTheme.radiusRowRest);

    expect(radii.last.bottomLeft.x, LockoutTheme.radiusGroupEnd);
    expect(radii.last.bottomRight.x, LockoutTheme.radiusGroupEnd);
    expect(radii.last.topLeft.x, LockoutTheme.radiusRowRest);
  });

  testWidgets('inner children are small on every corner', (tester) async {
    await tester.pumpWidget(host(4));
    await tester.pumpAndSettle();

    final middle = _radiiOf(tester)[1];
    expect(middle.topLeft.x, LockoutTheme.radiusRowRest);
    expect(middle.bottomRight.x, LockoutTheme.radiusRowRest);
  });

  testWidgets('a single child is large on all four corners', (tester) async {
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle();

    final only = _radiiOf(tester).single;
    expect(only.topLeft.x, LockoutTheme.radiusGroupEnd);
    expect(only.bottomRight.x, LockoutTheme.radiusGroupEnd);
  });

  testWidgets('children sit 3dp apart', (tester) async {
    await tester.pumpWidget(host(3));
    await tester.pumpAndSettle();

    final gaps = tester
        .widgetList<SizedBox>(find.descendant(
          of: find.byType(ConnectedGroup),
          matching: find.byType(SizedBox),
        ))
        .where((b) => b.height == LockoutTheme.groupGap);
    expect(gaps.length, 2, reason: 'n children need n-1 gaps');
  });

  testWidgets('an empty group renders nothing rather than throwing',
      (tester) async {
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    expect(_radiiOf(tester), isEmpty);
  });
}
