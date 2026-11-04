import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/routines_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });
  setUp(() => wipeDatabaseAndReseed(DatabaseService.instance));
  testWidgets('an empty plan opens its own route and can save its first day', (
    tester,
  ) async {
    await DatabaseService.instance.insertRoutine(
      Routine(
        id: 'r',
        name: 'My plan',
        schedulingMode: SchedulingMode.weekday,
        createdAt: '2026-11-03',
      ).toMap(),
    );
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: RoutinesTab()),
    );
    await settle(tester);
    expect(find.text('Your routines'), findsOneWidget);
    await tester.tap(find.text('My plan').last);
    await settle(tester);
    expect(find.text('Your week'), findsOneWidget);
    await tester.tap(find.text('Add day'));
    await settle(tester);
    final name = find.descendant(
      of: find.byWidgetPredicate((w) => w is NvField && w.label == 'Day name'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(name, 'Upper body');
    await tester.ensureVisible(find.text('Create day'));
    await tester.tap(find.text('Create day'));
    await settle(tester);
    expect(
      (await DatabaseService.instance.getDaysForRoutine('r')).single['name'],
      'Upper body',
    );
    expect(find.text('Upper body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('blank custom routine explains the missing name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: RoutinesTab()),
    );
    await settle(tester);
    await tester.tap(find.text('Create routine').last);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('routine-template-blank')));
    await tester.ensureVisible(find.text('Save routine'));
    await settle(tester);
    await tester.tap(find.text('Save routine'));
    await settle(tester);
    expect(find.text('Enter a routine name'), findsOneWidget);
    expect(await DatabaseService.instance.getRoutines(), isEmpty);
  });
  testWidgets('several exercises can be added to a day in one selection', (
    tester,
  ) async {
    await DatabaseService.instance.insertRoutine(
      Routine(
        id: 'r',
        name: 'My plan',
        schedulingMode: SchedulingMode.weekday,
        createdAt: '2026-11-03',
      ).toMap(),
    );
    await DatabaseService.instance.insertDay(
      TrainingDay(
        id: 'd',
        routineId: 'r',
        name: 'Upper body',
        tag: 'MON',
        orderIndex: 0,
      ).toMap(),
    );
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: RoutinesTab()),
    );
    await settle(tester);
    await tester.tap(find.text('My plan').last);
    await settle(tester);
    await tester.tap(find.text('Upper body'));
    await settle(tester);
    await tester.ensureVisible(find.text('Add exercise'));
    await settle(tester);
    await tester.tap(find.text('Add exercise'));
    await settle(tester);
    await tester.tap(find.text('Barbell Bench Press'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Incline Dumbbell Press'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    await tester.tap(find.text('Incline Dumbbell Press'));
    await settle(tester);
    await tester.tap(find.text('Add 2 exercises'));
    await settle(tester);
    final exercises = await DatabaseService.instance.getExercisesForDay('d');
    expect(exercises, hasLength(2));
    expect(
      exercises.map((e) => e['name']),
      containsAll(['Barbell Bench Press', 'Incline Dumbbell Press']),
    );
  });
}
