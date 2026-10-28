import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/widgets/house/nv_status_badge.dart';

import 'test_helpers.dart';

Widget _host(NvBadgeKind kind) => MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: Center(child: NvStatusBadge(label: 'Done', kind: kind)),
      ),
    );

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(NvStatusBadge),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('a done badge reads as success', (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.done));
    await tester.pumpAndSettle();

    final semantics = LockoutSemantics.of(
      tester.element(find.byType(NvStatusBadge)),
    );
    expect(_decorationOf(tester).color, semantics.success);
  });

  testWidgets('an accent badge takes the accent, not a neutral',
      (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.accent));
    await tester.pumpAndSettle();

    final colors =
        Theme.of(tester.element(find.byType(NvStatusBadge))).colorScheme;
    expect(_decorationOf(tester).color, colors.primaryContainer);
  });

  testWidgets('an unknown badge is transparent with a dashed-weight border',
      (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.unknown));
    await tester.pumpAndSettle();

    final decoration = _decorationOf(tester);
    expect(decoration.color!.a, 0.0);
    expect(decoration.border, isNotNull,
        reason: 'section 8 gives the unknown badge an outline, not a fill');
  });

  testWidgets('a neutral badge takes surfaceContainerHigh', (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.neutral));
    await tester.pumpAndSettle();

    final colors =
        Theme.of(tester.element(find.byType(NvStatusBadge))).colorScheme;
    expect(_decorationOf(tester).color, colors.surfaceContainerHigh);
  });

  testWidgets('every kind resolves its colour from the theme',
      (tester) async {
    for (final kind in NvBadgeKind.values) {
      await tester.pumpWidget(_host(kind));
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, isA<Color>(),
          reason: '$kind resolved no fill');
    }
  });

  testWidgets('the label follows the active appearance', (tester) async {
    await tester.pumpWidget(_host(NvBadgeKind.neutral));
    await tester.pumpAndSettle();
    final dark = tester.widget<Text>(find.text('Done')).style?.color;

    await tester.pumpWidget(
      MaterialApp(
        theme: lightAppearance.theme,
        home: const Scaffold(
          body: Center(
            child: NvStatusBadge(label: 'Done', kind: NvBadgeKind.neutral),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Done')).style?.color, isNot(dark));
  });
}
