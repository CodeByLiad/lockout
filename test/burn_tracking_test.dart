import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/food_tab.dart';
import 'package:lockout/screens/settings_screen.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/burn_service.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

Future<void> _seedFinishedWorkoutToday({double kcal = 300}) async {
  final db = DatabaseService.instance;
  await db.saveSetting('calorie_target', '2000');
  await db.insertSessionWithSets(
    SessionLog(
      id: 's1',
      dayName: 'Legs',
      dateStr: ScheduleService.dateKey(DateTime.now()),
      durationSeconds: 3600,
      totalVolumeKg: 1000,
      status: 'completed',
      totalSets: 10,
      kcalBurned: kcal,
    ).toMap(),
    const [],
  );
}

void main() {
  useTestDatabase();

  testWidgets('a finished workout raises Today kcal left by its burn', (
    t,
  ) async {
    await _seedFinishedWorkoutToday();
    await pumpPage(t, TodayTab());
    expect(find.textContaining('2300 kcal left'), findsOneWidget);
    expect(find.textContaining('~300 kcal burned'), findsWidgets);
  });

  testWidgets('switching burn counting off restores the plain budget', (
    t,
  ) async {
    await _seedFinishedWorkoutToday();
    await BurnService.setCountsInBudget(false);
    await pumpPage(t, TodayTab());
    expect(find.textContaining('2000 kcal left'), findsOneWidget);
  });

  testWidgets('Food adds the workout burn to the day budget', (t) async {
    await _seedFinishedWorkoutToday();
    await pumpPage(t, FoodTab());
    expect(find.textContaining('2300 kcal left'), findsOneWidget);
    expect(find.textContaining('~300 kcal burned'), findsWidgets);
  });

  testWidgets('Settings nutrition tracks burn totals and the switch', (
    t,
  ) async {
    await _seedFinishedWorkoutToday(kcal: 250);
    await pumpPage(t, SettingsBody(onSettingsUpdated: () {}, section: 'nutrition'));
    expect(find.text('Workout burn'), findsOneWidget);
    expect(find.text('~250 kcal'), findsWidgets);
    expect(find.text('Count workout burn in daily budget'), findsOneWidget);
    await press(t, 'Count workout burn in daily budget');
    expect(await BurnService.countsInBudget(), isFalse);
  });

  test('a saved session burn can be corrected', () async {
    await _seedFinishedWorkoutToday();
    await DatabaseService.instance.updateSessionBurn('s1', 410);
    final rows = await DatabaseService.instance.getSessionLogs();
    expect(rows.single['kcal_burned'], 410);
  });

  testWidgets('the saved workout page lets the user correct the burn', (
    t,
  ) async {
    final db = DatabaseService.instance;
    final routine = Routine(
      id: 'r',
      name: 'Plan',
      schedulingMode: SchedulingMode.weekday,
      createdAt: '2026-11-15',
    );
    final day = TrainingDay(
      id: 'd',
      routineId: 'r',
      name: 'Push',
      tag: 'MON',
      orderIndex: 0,
    );
    final ex = ExerciseDef(
      id: 'e',
      dayId: 'd',
      name: 'Bench press',
      targetSets: 1,
      targetRepsMin: 8,
      targetRepsMax: 8,
      targetWeightKg: 60,
    );
    await db.insertRoutine(routine.toMap());
    await db.insertDay(day.toMap());
    await db.insertExercise(ex.toMap());
    final key = GlobalKey<TodayTabState>();
    await t.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: TodayTab(key: key, presentSessionAsRoute: true),
      ),
    );
    await settle(t);
    await key.currentState!.startDay(
      ScheduledDay(routine: routine, day: day, exercises: [ex]),
    );
    await settle(t);
    await t.tap(find.byKey(const ValueKey('set-complete-0-0')));
    await settle(t);
    if (find.text('Skip rest').evaluate().isNotEmpty) {
      await t.tap(find.text('Skip rest'));
      await settle(t);
    }
    await t.tap(find.text('Finish workout'));
    await settle(t);
    await t.ensureVisible(find.byKey(const ValueKey('save-workout')));
    await settle(t);
    await t.tap(find.byKey(const ValueKey('save-workout')));
    await settle(t);

    expect(find.text('Your workout burned'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('edit-burn')));
    await settle(t);
    await t.enterText(find.byType(TextField).last, '450');
    await t.tap(find.byKey(const ValueKey('save-burn')));
    await settle(t);

    expect(find.text('~450 kcal'), findsOneWidget);
    final row = (await db.getSessionLogs()).single;
    expect(row['kcal_burned'], 450);
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });
}
