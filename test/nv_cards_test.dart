import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_button.dart';
import 'package:lockout/widgets/house/nv_cards.dart';
import 'package:lockout/widgets/house/nv_empty_state.dart';

import 'test_helpers.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(body: child),
    );

void main() {
  group('info card', () {
    testWidgets('it is surfaceContainer with 28dp corners', (tester) async {
      await tester.pumpWidget(
        _wrap(const NvInfoCard(child: Text('Go easy on the knee'))),
      );
      await tester.pumpAndSettle();

      final colors =
          Theme.of(tester.element(find.byType(NvInfoCard))).colorScheme;
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(NvInfoCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, colors.surfaceContainer);
      expect((decoration.borderRadius! as BorderRadius).topLeft.x, 28);
    });
  });

  group('TBA card', () {
    testWidgets('it paints a dashed border and no fill', (tester) async {
      await tester.pumpWidget(
        _wrap(const NvTbaCard(message: 'No exercises yet')),
      );
      await tester.pumpAndSettle();

      final paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(NvTbaCard),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(paint.painter, isNotNull);
      expect(find.text('No exercises yet'), findsOneWidget);
    });

    testWidgets('the border colour comes from the theme', (tester) async {
      await tester.pumpWidget(
        _wrap(const NvTbaCard(message: 'No exercises yet')),
      );
      await tester.pumpAndSettle();

      final colors =
          Theme.of(tester.element(find.byType(NvTbaCard))).colorScheme;
      final painter = tester
          .widget<CustomPaint>(
            find
                .descendant(
                  of: find.byType(NvTbaCard),
                  matching: find.byType(CustomPaint),
                )
                .first,
          )
          .painter! as DashedBorderPainter;

      expect(painter.color, colors.outlineVariant);
      expect(painter.strokeWidth, 2);
    });
  });

  group('empty state', () {
    testWidgets('it offers a headline, a sentence and one button',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          NvEmptyState(
            headline: 'No session today',
            body: 'Train off-plan or take the day.',
            actionLabel: 'Start a custom session',
            onAction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No session today'), findsOneWidget);
      expect(find.text('Train off-plan or take the day.'), findsOneWidget);
      expect(find.byType(NvButton), findsOneWidget);
    });

    testWidgets('it is a surfaceContainer block with 32dp corners',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          NvEmptyState(
            headline: 'No session today',
            body: 'Train off-plan or take the day.',
            actionLabel: 'Start a custom session',
            onAction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final colors =
          Theme.of(tester.element(find.byType(NvEmptyState))).colorScheme;
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(NvEmptyState),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, colors.surfaceContainer);
      expect((decoration.borderRadius! as BorderRadius).topLeft.x, 32);
    });

    testWidgets('the button does the thing the sentence asked for',
        (tester) async {
      var acted = 0;
      await tester.pumpWidget(
        _wrap(
          NvEmptyState(
            headline: 'No session today',
            body: 'Train off-plan or take the day.',
            actionLabel: 'Start a custom session',
            onAction: () => acted++,
          ),
        ),
      );
      await tester.tap(find.text('Start a custom session'));
      await tester.pumpAndSettle();
      expect(acted, 1);
    });
  });
}
