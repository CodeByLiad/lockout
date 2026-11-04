import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lockout/models/models.dart';
import 'package:lockout/screens/log_tab.dart';
import 'package:lockout/services/database_service.dart';

import 'test_helpers.dart';

SessionLog _log({
  String id = 's1',
  String dayName = 'MON - Legs',
  String dateStr = '2026-09-07',
  int durationSeconds = 3060,
  double totalVolumeKg = 2295.0,
  int totalSets = 22,
  double kcal = 0.0,
  String status = 'completed',
}) => SessionLog(
  id: id,
  dayName: dayName,
  dateStr: dateStr,
  durationSeconds: durationSeconds,
  totalVolumeKg: totalVolumeKg,
  status: status,
  totalSets: totalSets,
  kcalBurned: kcal,
);

Future<void> _insertSession(
  DatabaseService db,
  SessionLog log, {
  List<SetLog> sets = const [],
}) async {
  await db.insertSessionLog(log.toMap());
  if (sets.isNotEmpty) {
    await db.insertSetLogs(sets.map((s) => s.toMap()).toList());
  }
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  group('sessionArchiveLine', () {
    test('includes the burn estimate when there is one', () {
      expect(
        sessionArchiveLine(_log(kcal: 388.7)),
        '2026-09-07  -  51 min  -  22 sets  -  ~389 kcal',
      );
    });

    test('omits the burn entirely when there is none', () {
      expect(sessionArchiveLine(_log()), '2026-09-07  -  51 min  -  22 sets');
    });
  });

  Future<void> pumpLog(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: lockoutTestTheme(), home: LogTab()),
    );
    await settle(tester);
  }

  testWidgets('empty history offers useful guidance', (t) async {
    await pumpLog(t);
    expect(find.text('Your next chapter starts here'), findsOneWidget);
    expect(find.text('No active streak'), findsOneWidget);
  });
  testWidgets('completed workouts lead to their real set details', (t) async {
    await _insertSession(
      DatabaseService.instance,
      _log(dayName: 'Legs'),
      sets: [
        SetLog(
          id: 'set-1',
          sessionExerciseId: '',
          sessionId: 's1',
          exerciseName: 'Squat',
          setIndex: 1,
          reps: 8,
          weightKg: 60,
          isCompleted: true,
        ),
      ],
    );
    await pumpLog(t);
    await t.tap(find.text('Legs'));
    await settle(t);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('60.0 kg'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
  testWidgets(
    'deletion undo restores header and all set ids in original order',
    (t) async {
      final db = DatabaseService.instance;
      await _insertSession(
        db,
        _log(dayName: 'Legs'),
        sets: [
          for (var i = 1; i <= 3; i++)
            SetLog(
              id: 'set-$i',
              sessionExerciseId: '',
              sessionId: 's1',
              exerciseName: i < 3 ? 'Squat' : 'Press',
              setIndex: i,
              reps: 8,
              weightKg: 60,
              isCompleted: true,
            ),
        ],
      );
      final header = await db.getSessionLogs();
      final sets = await db.getSetLogsForSession('s1');
      await pumpLog(t);
      await t.tap(find.text('Legs'));
      await settle(t);
      await t.ensureVisible(find.text('Delete workout'));
      await t.tap(find.text('Delete workout'));
      await settle(t);
      expect(await db.getSessionLogs(), isEmpty);
      expect(await db.getSetLogsForSession('s1'), isEmpty);
      await t.tap(find.text('Undo'));
      await settle(t);
      expect(await db.getSessionLogs(), header);
      expect(await db.getSetLogsForSession('s1'), sets);
      await t.pump(const Duration(seconds: 6));
    },
  );
  testWidgets('skipped sessions do not appear or count in history', (t) async {
    await _insertSession(
      DatabaseService.instance,
      _log(dayName: 'Skipped', status: 'skipped'),
    );
    await _insertSession(
      DatabaseService.instance,
      _log(id: 'good', dayName: 'Completed'),
    );
    await pumpLog(t);
    expect(find.text('Skipped'), findsNothing);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('1 workouts'), findsOneWidget);
  });
  for (final value in [double.nan, double.infinity, double.negativeInfinity]) {
    test('nonfinite total remains readable $value', () {
      expect(kgWhole(value), '--');
    });
  }
}
