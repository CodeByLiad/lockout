import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/log_tab.dart';
import 'package:lockout/screens/progress_tab.dart';
import 'package:lockout/screens/body_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/house/nv_activity_chart.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

void main() {
  useTestDatabase();
  testWidgets('weekly range stays readable at narrow width and enlarged text', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: ProgressTab(clock: () => DateTime(2026, 11, 9)),
      ),
    );
    await settle(t);
    final label = find.text('This week · 7–13 Nov 2026');
    expect(label, findsOneWidget);
    expect(t.getSize(label).width, lessThanOrEqualTo(360));
    expect(t.takeException(), isNull);
  });
  for (final now in [
    DateTime(2026, 11, 7),
    DateTime(2026, 11, 9),
    DateTime(2026, 11, 13, 23, 59),
  ]) {
    testWidgets('Saturday week includes weekend and ends Friday on $now', (
      t,
    ) async {
      for (final entry in {
        'previous': '2026-11-06',
        'saturday': '2026-11-07',
        'sunday': '2026-11-08',
        'friday': '2026-11-13',
        'next': '2026-11-14',
      }.entries) {
        await DatabaseService.instance.insertSessionLog(
          SessionLog(
            id: entry.key,
            dayName: entry.key,
            dateStr: entry.value,
            status: 'completed',
            durationSeconds: 60,
            totalVolumeKg: 100,
            totalSets: 1,
          ).toMap(),
        );
      }
      await pumpPage(t, ProgressTab(clock: () => now));
      expect(find.text('3 workouts'), findsOneWidget);
      final chart = t.widget<NvActivityChart>(find.byType(NvActivityChart));
      expect(chart.buckets.keys, [
        'Sat',
        'Sun',
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
      ]);
      expect(chart.buckets.values, [1, 1, 0, 0, 0, 0, 1]);
      expect(find.text('This week · 7–13 Nov 2026'), findsOneWidget);
      await press(t, 'Month');
      expect(find.text('5 workouts'), findsOneWidget);
    });
  }
  testWidgets('Saturday reset handles a week crossing the year', (t) async {
    await DatabaseService.instance.insertSessionLog(
      SessionLog(
        id: 'last-year',
        dayName: 'Sunday',
        dateStr: '2026-12-27',
        status: 'completed',
        durationSeconds: 60,
        totalVolumeKg: 100,
        totalSets: 1,
      ).toMap(),
    );
    var now = DateTime(2027, 1, 1, 23, 59);
    final key = GlobalKey<ProgressTabState>();
    await pumpPage(t, ProgressTab(key: key, clock: () => now));
    expect(find.text('1 workout'), findsOneWidget);
    expect(find.text('This week · 26 Dec 2026–1 Jan 2027'), findsOneWidget);
    now = DateTime(2027, 1, 2);
    await key.currentState!.reload();
    await settle(t);
    expect(find.text('0 workouts'), findsOneWidget);
    expect(find.text('This week · 2–8 Jan 2027'), findsOneWidget);
  });
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
