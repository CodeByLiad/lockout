import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/bottom_nav.dart';
import 'package:lockout/widgets/house/nv_navigation_bar.dart';

import 'test_helpers.dart';

ThemeData _theme() => LockoutTheme.build(
  colors: darkAppearance.colors,
  semantics: darkAppearance.semantics,
);

Widget _host({
  bool foodTabEnabled = true,
  int index = 0,
  ValueChanged<int>? onTap,
}) {
  return MaterialApp(
    theme: _theme(),
    home: Scaffold(
      bottomNavigationBar: BottomNav(
        currentIndex: index,
        foodTabEnabled: foodTabEnabled,
        onTap: onTap ?? (_) {},
      ),
    ),
  );
}

void main() {
  test('four task destinations in the approved order', () {
    final tabs = BottomNav.visibleTabs();

    expect(tabs.map((t) => t.id).toList(), [
      'home',
      'workout',
      'progress',
      'food',
    ]);
    expect(tabs.map((t) => t.tab).toList(), [
      NavTab.home,
      NavTab.workout,
      NavTab.progress,
      NavTab.food,
    ]);
  });

  test('hiding food leaves three tabs and keeps the order', () {
    final tabs = BottomNav.visibleTabs(foodTabEnabled: false);

    expect(tabs.map((t) => t.id).toList(), ['home', 'workout', 'progress']);
  });

  test('every tab has a distinct selected and unselected icon', () {
    for (final tab in BottomNav.visibleTabs()) {
      expect(
        tab.icon,
        isNot(tab.selectedIcon),
        reason:
            '${tab.id}: selection must read without relying on colour '
            'alone',
      );
    }
  });

  test('labels are sentence case, not the old shouting', () {
    for (final tab in BottomNav.visibleTabs()) {
      expect(tab.label, isNot(tab.label.toUpperCase()), reason: tab.id);
    }
  });

  testWidgets('renders the Expressive NvNavigationBar', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(find.byType(NvNavigationBar), findsOneWidget);
    for (final label in const ['Today', 'Training', 'Progress', 'Food']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('food off renders three destinations', (tester) async {
    await tester.pumpWidget(_host(foodTabEnabled: false));
    await tester.pump();

    expect(find.byType(NvNavigationBar), findsOneWidget);
    for (final label in const ['Today', 'Training', 'Progress']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Food'), findsNothing);
  });

  testWidgets('the bar is at least 64dp and reports its measured height', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump();
    await tester.pump();

    final size = tester.getSize(find.byType(NvNavigationBar));
    expect(size.height, greaterThanOrEqualTo(NvNavigationBar.height));
    expect(
      BottomNav.lastRenderedHeight.value,
      greaterThanOrEqualTo(NvNavigationBar.height),
      reason: 'showUndoBanner positions itself against this',
    );
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    var tapped = -1;
    await tester.pumpWidget(_host(onTap: (i) => tapped = i));
    await tester.pump();

    await tester.tap(find.text('Progress'));
    await tester.pump();

    expect(tapped, 2);
  });

  testWidgets('with food off, the index still matches the visible order', (
    tester,
  ) async {
    var tapped = -1;
    await tester.pumpWidget(
      _host(foodTabEnabled: false, onTap: (i) => tapped = i),
    );
    await tester.pump();

    await tester.tap(find.text('Progress'));
    await tester.pump();

    expect(
      tapped,
      2,
      reason: 'Profile is the fourth visible tab once Food is hidden',
    );
  });

  testWidgets('an out-of-range index clamps rather than throwing', (
    tester,
  ) async {
    await tester.pumpWidget(_host(foodTabEnabled: false, index: 4));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
