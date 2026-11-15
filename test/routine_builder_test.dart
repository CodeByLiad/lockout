import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/routines_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

Future<void> _seedPlan() async {
  final db = DatabaseService.instance;
  await db.insertRoutine(
    Routine(
      id: 'r',
      name: 'My plan',
      schedulingMode: SchedulingMode.weekday,
      createdAt: '2026-11-15',
    ).toMap(),
  );
  await db.insertDay(
    TrainingDay(
      id: 'd',
      routineId: 'r',
      name: 'Upper body',
      tag: 'MON',
      orderIndex: 0,
    ).toMap(),
  );
  await db.insertExercise(
    ExerciseDef(
      id: 'e',
      dayId: 'd',
      name: 'Bench press',
      targetSets: 3,
      targetRepsMin: 8,
      targetRepsMax: 12,
      muscleGroup: 'Chest',
    ).toMap(),
  );
  await db.insertBodyLog({
    'id': 'b',
    'date_str': '2026-11-10',
    'weight_kg': 80.0,
  });
}

void main() {
  useTestDatabase();

  testWidgets('a plan opens as one builder with its exercises inline', (
    t,
  ) async {
    await _seedPlan();
    await pumpPage(t, RoutinesTab());
    await t.tap(find.text('My plan').last);
    await settle(t);

    expect(find.text('Your week'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('3 × 8–12 reps · rest 60 s'), findsOneWidget);
    expect(find.text('Est. time / week'), findsOneWidget);
    expect(find.textContaining('~5 min'), findsWidgets);
    expect(find.textContaining('kcal'), findsWidgets);
    expect(find.byKey(const ValueKey('routine-builder-done')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('sets change in place from the builder', (t) async {
    await _seedPlan();
    await pumpPage(t, RoutinesTab());
    await t.tap(find.text('My plan').last);
    await settle(t);

    await t.tap(find.byKey(const ValueKey('sets-plus-e')));
    await settle(t);
    expect(find.text('4 × 8–12 reps · rest 60 s'), findsOneWidget);
    var row = (await DatabaseService.instance.getExercisesForDay('d')).single;
    expect(row['target_sets'], 4);

    await t.tap(find.byKey(const ValueKey('sets-minus-e')));
    await settle(t);
    row = (await DatabaseService.instance.getExercisesForDay('d')).single;
    expect(row['target_sets'], 3);
  });

  testWidgets('creating a routine lands in its builder', (t) async {
    await pumpPage(t, RoutinesTab());
    await press(t, 'Create routine');
    await t.tap(find.byKey(const ValueKey('routine-template-ppl')));
    await settle(t);
    await t.ensureVisible(find.text('Save routine'));
    await settle(t);
    await t.tap(find.text('Save routine'));
    await settle(t, maxPumps: 40);

    expect(find.text('Your week'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-builder-done')), findsOneWidget);
    expect(await DatabaseService.instance.getRoutines(), hasLength(1));
    expect(t.takeException(), isNull);
  });
}
