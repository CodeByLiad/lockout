import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_navigation_bar.dart';

import 'test_helpers.dart';

const _dests = [
  NvNavigationDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  NvNavigationDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Profile',
  ),
];

Widget _host(int index, ValueChanged<int> onTap, {bool reduce = false}) =>
    MaterialApp(
      theme: lockoutTestTheme(lightAppearance),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          bottomNavigationBar: NvNavigationBar(
            selectedIndex: index,
            onDestinationSelected: onTap,
            destinations: _dests,
          ),
        ),
      ),
    );

Finder _indicator() => find.byKey(const ValueKey('nv-nav-indicator'));

void main() {
  testWidgets('64dp on surfaceContainer, every label shown', (tester) async {
    await tester.pumpWidget(_host(0, (_) {}));
    final bar = find.byType(NvNavigationBar);
    expect(tester.getSize(bar).height, NvNavigationBar.height);
    final material = tester.widget<Material>(
      find.descendant(of: bar, matching: find.byType(Material)).first,
    );
    expect(material.color, lightAppearance.colors.surfaceContainer);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('selected icon is the filled variant', (tester) async {
    await tester.pumpWidget(_host(0, (_) {}));
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('the pill indicator is 56x32 and sits under the selection', (
    tester,
  ) async {
    await tester.pumpWidget(_host(1, (_) {}));
    await tester.pumpAndSettle();
    expect(tester.getSize(_indicator()), NvNavigationBar.indicatorSize);
    expect(
      tester.getCenter(_indicator()).dx,
      closeTo(tester.getCenter(find.byIcon(Icons.person)).dx, 0.5),
    );
  });

  testWidgets('the indicator springs between destinations', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (_, set) => _host(index, (i) => set(() => index = i)),
      ),
    );
    final from = tester.getCenter(_indicator()).dx;
    await tester.tap(find.text('Profile'));
    // The first pump builds the frame that starts the tween; time advances
    // from the one after it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getCenter(_indicator()).dx;
    await tester.pumpAndSettle();
    final to = tester.getCenter(_indicator()).dx;
    expect(mid, greaterThan(from));
    expect(mid, lessThan(to));
  });

  testWidgets('reduced motion moves the indicator instantly', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (_, set) =>
            _host(index, (i) => set(() => index = i), reduce: true),
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(
      tester.getCenter(_indicator()).dx,
      closeTo(tester.getCenter(find.byIcon(Icons.person)).dx, 0.5),
    );
  });

  testWidgets('a press squashes the indicator, release recovers', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0, (_) {}));
    final rest = tester.getSize(_indicator());
    final g = await tester.startGesture(tester.getCenter(find.text('Home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getSize(_indicator()).width, lessThan(rest.width));
    await g.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(_indicator()), rest);
  });

  testWidgets('one semantics node per destination, labelled and selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(0, (_) {}));
    expect(
      tester.getSemantics(find.text('Home')),
      matchesSemantics(
        label: 'Home',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Profile')),
      matchesSemantics(
        label: 'Profile',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('tapping reports the index', (tester) async {
    int? tapped;
    await tester.pumpWidget(_host(0, (i) => tapped = i));
    await tester.tap(find.text('Profile'));
    expect(tapped, 1);
  });
}
