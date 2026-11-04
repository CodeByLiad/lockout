import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/routines_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

void main() {
  useTestDatabase();
  Future<void> seed({bool rest = false, bool exercise = false}) async {
    final db = DatabaseService.instance;
    await db.insertRoutine(
      Routine(
        id: 'r',
        name: 'My plan',
        schedulingMode: SchedulingMode.weekday,
        createdAt: '2026-01-01',
      ).toMap(),
    );
    await db.insertDay(
      TrainingDay(
        id: 'd',
        routineId: 'r',
        name: 'Upper body',
        tag: 'MON',
        orderIndex: 0,
        isRestDay: rest,
      ).toMap(),
    );
    if (exercise) {
      await db.insertExercise(
        ExerciseDef(
          id: 'e',
          dayId: 'd',
          name: 'Bench press',
          targetSets: 3,
          targetRepsMin: 8,
          targetRepsMax: 12,
        ).toMap(),
      );
    }
  }

  Future<void> openDay(WidgetTester t) async {
    await pumpPage(t, RoutinesTab());
    await press(t, 'My plan');
    await press(t, 'Upper body');
  }

  testWidgets('creation requires an explicit starter choice', (t) async {
    await pumpPage(t, RoutinesTab());
    await press(t, 'Create routine');
    await press(t, 'Save routine');
    expect(await DatabaseService.instance.getRoutines(), isEmpty);
    expect(find.textContaining('Choose'), findsWidgets);
  });
  testWidgets('custom name and rotating schedule persist', (t) async {
    await pumpPage(t, RoutinesTab());
    await press(t, 'Create routine');
    await t.tap(find.byKey(const ValueKey('routine-template-blank')));
    await settle(t);
    await t.enterText(field('Routine name'), 'Weekend plan');
    await press(t, 'Rotating');
    await press(t, 'Save routine');
    final routine = (await DatabaseService.instance.getRoutines()).single;
    expect(routine['name'], 'Weekend plan');
    expect(routine['scheduling_mode'], 'ROTATING');
    expect(
      await DatabaseService.instance.getDaysForRoutine(routine['id'] as String),
      isEmpty,
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('day edit persists and returns to refreshed week', (t) async {
    await seed();
    await openDay(t);
    await press(t, 'Edit day');
    await t.enterText(field('Day name'), 'Push');
    await press(t, 'Save day');
    expect(
      (await DatabaseService.instance.getDaysForRoutine('r')).single['name'],
      'Push',
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('warm-up and finisher add actions survive their first item', (
    t,
  ) async {
    await seed();
    await openDay(t);
    for (final section in ['warm-up', 'finisher']) {
      await press(t, 'Add $section');
      await t.enterText(field('Movement'), 'Test $section');
      await t.enterText(field('Amount'), '3 minutes');
      await press(t, 'Add');
      expect(find.text('Test $section'), findsOneWidget);
      expect(find.text('Add $section'), findsOneWidget);
    }
    expect(await DatabaseService.instance.getWarmupsForDay('d'), hasLength(1));
    expect(
      await DatabaseService.instance.getFinishersForDay('d'),
      hasLength(1),
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('rest days offer recovery and editing without exercise actions', (
    t,
  ) async {
    await seed(rest: true);
    await openDay(t);
    expect(find.text('Recovery is part of the plan'), findsOneWidget);
    expect(find.text('Add exercise'), findsNothing);
    expect(find.text('Add warm-up'), findsNothing);
    expect(find.text('Start workout'), findsNothing);
    expect(find.text('Edit day'), findsOneWidget);
  });
  testWidgets('exercise edits retain typed input on route rebuild and save', (
    t,
  ) async {
    await seed(exercise: true);
    await openDay(t);
    await press(t, 'Bench press');
    await t.enterText(field('Note'), 'Pause each rep');
    await t.enterText(field('Weight (kg)'), '72.5');
    await t.binding.setSurfaceSize(const Size(600, 2200));
    await t.pump();
    expect(find.text('Pause each rep'), findsOneWidget);
    await press(t, 'Save changes');
    final ex = (await DatabaseService.instance.getExercisesForDay('d')).single;
    expect(ex['note'], 'Pause each rep');
    expect(ex['target_weight_kg'], 72.5);
    expect(t.takeException(), isNull);
  });
  testWidgets('invalid repetition range keeps the editor and original record', (
    t,
  ) async {
    await seed(exercise: true);
    await openDay(t);
    await press(t, 'Bench press');
    await t.enterText(field('Min reps'), '20');
    await t.enterText(field('Max reps'), '5');
    await press(t, 'Save changes');
    expect(find.text('Edit exercise'), findsOneWidget);
    expect(
      (await DatabaseService.instance.getExercisesForDay(
        'd',
      )).single['target_reps_min'],
      8,
    );
  });
  testWidgets('removing an exercise refreshes the open day', (t) async {
    await seed(exercise: true);
    await openDay(t);
    await press(t, 'Bench press');
    await press(t, 'Remove exercise');
    expect(find.text('Bench press'), findsNothing);
    expect(find.text('Add exercise'), findsOneWidget);
    expect(await DatabaseService.instance.getExercisesForDay('d'), isEmpty);
  });
  testWidgets(
    'routine deletion requires confirmation and retains completed history',
    (t) async {
      await seed();
      await DatabaseService.instance.insertSessionLog(
        SessionLog(
          status: 'completed',
          id: 's',
          dayName: 'Past workout',
          dateStr: '2026-01-01',
          durationSeconds: 60,
          totalSets: 1,
          totalVolumeKg: 10,
        ).toMap(),
      );
      await pumpPage(t, RoutinesTab());
      await press(t, 'My plan');
      await press(t, 'Delete routine');
      await press(t, 'Keep routine');
      expect(await DatabaseService.instance.getRoutines(), hasLength(1));
      await press(t, 'Delete routine');
      await press(t, 'Delete');
      expect(await DatabaseService.instance.getRoutines(), isEmpty);
      expect(await DatabaseService.instance.getSessionLogs(), hasLength(1));
      expect(t.takeException(), isNull);
    },
  );
}
