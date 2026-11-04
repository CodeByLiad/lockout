import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'package:lockout/widgets/house/nv_wavy_progress.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

Future<void> seedActiveWeekdayRoutineForToday({
  double targetWeightKg = 0,
  int restSeconds = 90,
}) async {
  final db = DatabaseService.instance;
  await db.insertRoutine(
    Routine(
      id: 'r1',
      name: 'Split',
      schedulingMode: SchedulingMode.weekday,
      createdAt: '2026-01-01',
    ).toMap(),
  );
  await db.insertDay(
    TrainingDay(
      id: 'd1',
      routineId: 'r1',
      name: 'Legs',
      tag: ScheduleService.weekdayCode(DateTime.now()),
      orderIndex: 0,
    ).toMap(),
  );
  await db.insertExercise(
    ExerciseDef(
      id: 'e1',
      dayId: 'd1',
      name: 'Back Squat',
      targetSets: 2,
      targetRepsMin: 8,
      targetRepsMax: 8,
      targetWeightKg: targetWeightKg,
      restDefaultS: restSeconds,
    ).toMap(),
  );
  await db.setActiveRoutine('r1');
}

Widget hostedTodayTab({DateTime Function()? clock}) => MaterialApp(
  theme: lockoutTestTheme(),
  home: TodayTab(clock: clock ?? DateTime.now),
);
void main() {
  useTestDatabase();
  Future<void> start(WidgetTester t, {DateTime Function()? clock}) async {
    await t.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(hostedTodayTab(clock: clock));
    await settle(t);
    await press(t, 'Start workout');
  }

  test('the finish write remains transactional', () {
    final s = File('lib/screens/today_tab.dart').readAsStringSync();
    expect(s, contains('insertSessionWithSets('));
    expect(s, isNot(contains('insertSetLogs(')));
    expect(s, isNot(contains('insertSessionLog(')));
  });
  testWidgets(
    'empty scheduled day offers setup instead of starting a dead end',
    (t) async {
      final db = DatabaseService.instance;
      await db.insertRoutine(
        Routine(
          id: 'r',
          name: 'Empty',
          schedulingMode: SchedulingMode.weekday,
          createdAt: '2026-01-01',
        ).toMap(),
      );
      await db.insertDay(
        TrainingDay(
          id: 'd',
          routineId: 'r',
          name: 'Empty day',
          tag: ScheduleService.weekdayCode(DateTime.now()),
          orderIndex: 0,
        ).toMap(),
      );
      await db.setActiveRoutine('r');
      await pumpPage(t, TodayTab());
      expect(find.text('Start workout'), findsNothing);
      expect(find.text('Add exercises'), findsOneWidget);
      expect(find.text('Start a custom workout'), findsOneWidget);
    },
  );
  testWidgets('hidden nutrition removes its daily action', (t) async {
    await pumpPage(t, TodayTab(foodTabEnabled: false));
    expect(find.text('Log food'), findsNothing);
    expect(find.text('Weigh in'), findsOneWidget);
  });
  testWidgets('completed sets and real volume drive progress', (t) async {
    await seedActiveWeekdayRoutineForToday(targetWeightKg: 60);
    await start(t);
    expect(find.text('0 of 2 sets · 0 kg'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
    await settle(t, maxPumps: 4);
    expect(find.text('1 of 2 sets · 480 kg'), findsOneWidget);
    expect(
      t.widget<NvWavyProgress>(find.byType(NvWavyProgress).first).value,
      0.5,
    );
  });
  testWidgets('rest uses a wall clock even when ticks were suspended', (
    t,
  ) async {
    await seedActiveWeekdayRoutineForToday();
    var now = DateTime.now();
    await start(t, clock: () => now);
    await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
    await t.pump();
    expect(find.text('Rest · 01:30'), findsOneWidget);
    now = now.add(const Duration(seconds: 37));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Rest · 00:53'), findsOneWidget);
    now = now.add(const Duration(minutes: 2));
    await t.pump(const Duration(seconds: 1));
    expect(find.textContaining('Rest ·'), findsNothing);
  });
  testWidgets('elapsed time uses the clock after a long suspension', (t) async {
    await seedActiveWeekdayRoutineForToday();
    var now = DateTime.now();
    await start(t, clock: () => now);
    now = now.add(const Duration(minutes: 9, seconds: 12));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Workout in progress · 09:12'), findsOneWidget);
  });
  testWidgets('rest adjustments move the deadline and skip clears it', (
    t,
  ) async {
    await seedActiveWeekdayRoutineForToday();
    await start(t);
    await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
    await t.pump();
    await t.tap(find.text('Rest · 01:30'));
    await settle(t, maxPumps: 4);
    await t.tap(find.text('+15 sec'));
    await t.pump();
    await t.pump();
    expect(find.text('01:45'), findsOneWidget);
    await t.tap(find.text('−15 sec'));
    await t.pump();
    await t.pump();
    expect(find.text('01:30'), findsOneWidget);
    await t.tap(find.text('Skip rest'));
    await settle(t, maxPumps: 4);
    expect(find.textContaining('Rest ·'), findsNothing);
  });
  testWidgets('empty custom session can be left without writing history', (
    t,
  ) async {
    await pumpPage(t, TodayTab());
    await press(t, 'Start a custom workout');
    await t.tap(find.byTooltip('Leave session'));
    await settle(t);
    expect(await DatabaseService.instance.getSessionLogs(), isEmpty);
    expect(find.text('Train on your terms'), findsOneWidget);
  });
  testWidgets('discard asks before losing completed work', (t) async {
    await seedActiveWeekdayRoutineForToday();
    await start(t);
    await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
    await t.pump();
    await t.tap(find.byTooltip('Leave session'));
    await settle(t, maxPumps: 5);
    expect(find.text('Discard session?'), findsOneWidget);
    await press(t, 'Keep going');
    expect(find.text('Finish'), findsOneWidget);
    await t.tap(find.byTooltip('Leave session'));
    await settle(t, maxPumps: 5);
    await press(t, 'Discard');
    expect(await DatabaseService.instance.getSessionLogs(), isEmpty);
  });
  testWidgets('failed save keeps completed sets and permits a successful retry', (
    t,
  ) async {
    final db = await DatabaseService.instance.database;
    await db.execute(
      "CREATE TRIGGER test_fail_set_logs BEFORE INSERT ON set_logs BEGIN SELECT RAISE(ABORT, 'test rejection'); END;",
    );
    addTearDown(() => db.execute('DROP TRIGGER IF EXISTS test_fail_set_logs'));
    await seedActiveWeekdayRoutineForToday(targetWeightKg: 60);
    await start(t);
    await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
    await t.pump();
    await press(t, 'Finish');
    await press(t, 'Save workout');
    expect(find.textContaining('Session not saved'), findsOneWidget);
    expect(await DatabaseService.instance.getSessionLogs(), isEmpty);
    expect(find.byKey(const ValueKey('set-complete-0-0')), findsOneWidget);
    await db.execute('DROP TRIGGER test_fail_set_logs');
    await press(t, 'Finish');
    await press(t, 'Save workout');
    final logs = await DatabaseService.instance.getSessionLogs();
    expect(logs, hasLength(1));
    expect(logs.single['total_sets'], 1);
    expect(logs.single['total_volume_kg'], 480);
    expect(
      await DatabaseService.instance.getSetLogsForSession(
        logs.single['id'] as String,
      ),
      hasLength(1),
    );
    await t.pump(const Duration(seconds: 6));
  });
}
