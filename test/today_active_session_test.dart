import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'package:lockout/widgets/house/nv_button.dart';
import 'package:lockout/widgets/house/nv_cards.dart';
import 'package:lockout/widgets/house/nv_wavy_progress.dart';
import 'package:lockout/widgets/lockout_card.dart';

import 'test_helpers.dart';

// The live-session surface, rebuilt from the house catalog.
//
// `today_tab_test.dart` owns the session state machine — what starts, what
// saves, what the summary says. This suite owns how that surface is put
// together: which components it builds, and which pre-rebuild widgets it no
// longer reaches for.

Widget _hostedTodayTab() =>
    MaterialApp(theme: lockoutTestTheme(), home: TodayTab());

Future<void> _seedRoutineForToday() async {
  final db = DatabaseService.instance;
  await db.insertRoutine(Routine(
    id: 'r1',
    name: 'Split',
    schedulingMode: SchedulingMode.weekday,
    createdAt: '2026-01-01T00:00:00.000',
  ).toMap());
  await db.insertDay(TrainingDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Legs',
    tag: ScheduleService.weekdayCode(DateTime.now()),
    orderIndex: 0,
  ).toMap());
  await db.insertExercise(ExerciseDef(
    id: 'e1',
    dayId: 'd1',
    name: 'Back Squat',
    targetSets: 2,
    targetRepsMin: 8,
    targetRepsMax: 8,
    restDefaultS: 60,
  ).toMap());
  await db.setActiveRoutine('r1');
}

Future<void> _startSession(WidgetTester tester) async {
  await _seedRoutineForToday();
  await tester.pumpWidget(_hostedTodayTab());
  await settle(tester);
  await tester.tap(find.text('Start session'));
  await settle(tester);
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  group('the session header', () {
    testWidgets('it draws the wavy progress, not a plain bar',
        (tester) async {
      await _startSession(tester);

      expect(find.byType(NvWavyProgress), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsNothing,
          reason: 'section 8 gives long-running work the wavy indicator');
    });

    testWidgets('Finish is a house button', (tester) async {
      await _startSession(tester);

      expect(find.widgetWithText(NvButton, 'Finish'), findsOneWidget);
    });

    testWidgets('the header itself is a house card', (tester) async {
      await _startSession(tester);

      // Scoped to the header. The exercise cards below it are still
      // pre-rebuild widgets until the task that rebuilds them; the
      // whole-screen version of this assertion lands with the contract
      // guard, once every part of the screen can actually satisfy it.
      expect(
        find.ancestor(
          of: find.widgetWithText(NvButton, 'Finish'),
          matching: find.byType(NvInfoCard),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.widgetWithText(NvButton, 'Finish'),
          matching: find.byType(LockoutCard),
        ),
        findsNothing,
      );
    });
  });

  group('the rest bar', () {
    testWidgets('it draws the wavy progress', (tester) async {
      await _startSession(tester);
      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await settle(tester, maxPumps: 4);

      expect(find.byType(NvWavyProgress), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('its three actions are house text buttons', (tester) async {
      await _startSession(tester);
      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await settle(tester, maxPumps: 4);

      for (final label in const ['-15s', '+15s', 'Skip']) {
        expect(find.widgetWithText(NvButton, label), findsOneWidget,
            reason: '$label is a low-emphasis action, which is the NvButton '
                'text variant');
        expect(find.widgetWithText(TextButton, label), findsNothing);
      }
    });
  });
}
