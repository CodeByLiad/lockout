import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'overhaul_test_support.dart';

void main() {
  useTestDatabase();
  Future<void> plan() => DatabaseService.instance
      .insertRoutine(
        Routine(
          id: 'r',
          name: 'My plan',
          schedulingMode: SchedulingMode.weekday,
          createdAt: '2026-01-01',
        ).toMap(),
      )
      .then((_) => DatabaseService.instance.setActiveRoutine('r'));
  testWidgets(
    'an active empty plan offers its setup instead of another routine',
    (t) async {
      await plan();
      await pumpPage(t, TodayTab());
      expect(find.text('Build your training week'), findsOneWidget);
      expect(find.text('Open plan'), findsOneWidget);
      expect(find.text('Create routine'), findsNothing);
    },
  );
  testWidgets('an unscheduled day in an existing plan reads as recovery', (
    t,
  ) async {
    await plan();
    final today = ScheduleService.weekdayCode(DateTime.now());
    final tag = ScheduleService.weekdayPickerOrder.firstWhere(
      (d) => d != today,
    );
    await DatabaseService.instance.insertDay(
      TrainingDay(
        id: 'd',
        routineId: 'r',
        name: 'Training',
        tag: tag,
        orderIndex: 0,
      ).toMap(),
    );
    await pumpPage(t, TodayTab());
    expect(find.text('Recovery day'), findsOneWidget);
    expect(find.text('View training plan'), findsOneWidget);
    expect(find.text('Start a custom workout'), findsOneWidget);
  });
  testWidgets('explicit rest day cannot start stale exercise rows', (t) async {
    await plan();
    await DatabaseService.instance.insertDay(
      TrainingDay(
        id: 'd',
        routineId: 'r',
        name: 'Rest',
        tag: ScheduleService.weekdayCode(DateTime.now()),
        orderIndex: 0,
        isRestDay: true,
      ).toMap(),
    );
    await DatabaseService.instance.insertExercise(
      ExerciseDef(
        id: 'e',
        dayId: 'd',
        name: 'Stale exercise',
        targetSets: 1,
        targetRepsMin: 8,
        targetRepsMax: 8,
      ).toMap(),
    );
    await pumpPage(t, TodayTab());
    expect(find.text('Recovery day'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(find.text('Add exercises'), findsNothing);
  });
}
