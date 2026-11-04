import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/log_tab.dart';
import 'package:lockout/screens/progress_tab.dart';
import 'package:lockout/screens/body_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

void main() {
  useTestDatabase();
  testWidgets('progress opens an overview with three time ranges', (t) async {
    await pumpPage(t, const ProgressTab());
    for (final s in [
      'Week',
      'Month',
      'All time',
      'Your training',
      'Measurements',
      'Workout history',
    ]) {
      expect(find.text(s), findsWidgets);
    }
    expect(find.text('0 workouts'), findsOneWidget);
  });
  testWidgets('history and measurements open focused routes and return', (
    t,
  ) async {
    await pumpPage(t, const ProgressTab());
    await press(t, 'Workout history');
    expect(find.byType(LogTab), findsOneWidget);
    await t.pageBack();
    await settle(t);
    await press(t, 'Measurements');
    expect(find.byType(BodyTab), findsOneWidget);
    await t.pageBack();
    await settle(t);
    expect(find.text('Your training'), findsOneWidget);
  });
  testWidgets('all time includes older workouts while week excludes them', (
    t,
  ) async {
    await DatabaseService.instance.insertSessionLog(
      SessionLog(
        status: 'completed',
        id: 's',
        dayName: 'Old session',
        dateStr: '2020-01-01',
        durationSeconds: 120,
        totalSets: 2,
        totalVolumeKg: 100,
      ).toMap(),
    );
    await pumpPage(t, const ProgressTab());
    expect(find.text('0 workouts'), findsOneWidget);
    await press(t, 'All time');
    expect(find.text('1 workout'), findsOneWidget);
  });
  testWidgets('external history action opens the history route', (t) async {
    final key = GlobalKey<ProgressTabState>();
    await pumpPage(t, ProgressTab(key: key));
    key.currentState!.showSegment(ProgressSegment.history);
    await settle(t);
    expect(find.byType(LogTab), findsOneWidget);
  });
}
