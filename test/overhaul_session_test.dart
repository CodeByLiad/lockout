import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });
  setUp(() => wipeDatabaseAndReseed(DatabaseService.instance));
  testWidgets(
    'selected-day workout saves only completed sets with its own provenance',
    (tester) async {
      final db = DatabaseService.instance;
      final routine = Routine(
        id: 'selected-routine',
        name: 'My plan',
        schedulingMode: SchedulingMode.weekday,
        createdAt: '2026-11-03',
      );
      final day = TrainingDay(
        id: 'selected-day',
        routineId: routine.id,
        name: 'Selected day',
        tag: 'MON',
        orderIndex: 0,
      );
      final ex = ExerciseDef(
        id: 'selected-exercise',
        dayId: day.id,
        name: 'Bench press',
        targetSets: 2,
        targetRepsMin: 6,
        targetRepsMax: 8,
        targetWeightKg: 60,
      );
      await db.insertRoutine(routine.toMap());
      await db.insertDay(day.toMap());
      await db.insertExercise(ex.toMap());
      final key = GlobalKey<TodayTabState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: TodayTab(key: key, presentSessionAsRoute: true),
        ),
      );
      await settle(tester);
      await key.currentState!.startDay(
        ScheduledDay(routine: routine, day: day, exercises: [ex]),
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await settle(tester);
      await tester.tap(find.text('Skip rest'));
      await settle(tester);
      await tester.tap(find.text('Finish workout'));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('save-workout')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('save-workout')));
      await settle(tester);
      final session = (await db.getSessionLogs()).single;
      expect(session['routine_id'], routine.id);
      expect(session['day_id'], day.id);
      expect(session['total_sets'], 1);
      expect(session['total_volume_kg'], 480);
      final sets = await db.getSetLogsForSession(session['id'] as String);
      expect(sets, hasLength(1));
      expect(sets.single['reps'], 8);
      expect(find.text('Workout saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
