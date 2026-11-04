import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_activity_chart.dart';
import 'test_helpers.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('weekly chart keeps readable columns at text scale $scale', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: NvActivityChart(
                  caption: 'Workouts by day',
                  buckets: {
                    'Mon': 0,
                    'Tue': 1,
                    'Wed': 0,
                    'Thu': 0,
                    'Fri': 0,
                    'Sat': 0,
                    'Sun': 0,
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final scroll = t.state<ScrollableState>(find.byType(Scrollable));
      if (scale == 1) {
        expect(scroll.position.maxScrollExtent, 0);
        expect(
          t.getBottomRight(find.text('Sun')).dx,
          lessThanOrEqualTo(t.getBottomRight(find.byType(NvActivityChart)).dx),
        );
      } else {
        expect(scroll.position.maxScrollExtent, greaterThan(0));
        await t.drag(find.byType(SingleChildScrollView), const Offset(-200, 0));
        await t.pumpAndSettle();
        expect(
          t.getBottomRight(find.text('Sun')).dx,
          lessThanOrEqualTo(t.getBottomRight(find.byType(NvActivityChart)).dx),
        );
      }
      expect(t.takeException(), isNull);
    });
  }
}
