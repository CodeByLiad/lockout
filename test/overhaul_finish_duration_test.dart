import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'overhaul_test_support.dart';
import 'today_tab_test.dart' show seedActiveWeekdayRoutineForToday;

void main() {
  useTestDatabase();
  testWidgets(
    'waiting on finish review preserves its duration and completion date',
    (t) async {
      await seedActiveWeekdayRoutineForToday(targetWeightKg: 60);
      var now = DateTime(2026, 11, 3, 23, 58);
      await pumpPage(t, TodayTab(clock: () => now));
      await press(t, 'Start workout');
      await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await t.pump();
      now = now.add(const Duration(seconds: 60));
      await t.pump(const Duration(seconds: 1));
      await press(t, 'Finish');
      expect(find.text('01:00'), findsOneWidget);
      now = now.add(const Duration(minutes: 2));
      await t.pump(const Duration(seconds: 1));
      await press(t, 'Save workout');
      final row = (await DatabaseService.instance.getSessionLogs()).single;
      expect(row['duration_seconds'], 60);
      expect(row['date_str'], '2026-11-03');
      expect(row['total_sets'], 1);
      expect(row['total_volume_kg'], 480);
      await flushUndo(t);
    },
  );
}
