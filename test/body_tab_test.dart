import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lockout/models/models.dart';
import 'package:lockout/screens/body_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'package:lockout/widgets/sparkline.dart';

import 'test_helpers.dart';

Future<void> _insertLog(
  DatabaseService db, {
  required String id,
  required String dateStr,
  required double weightKg,
  double waistCm = 0.0,
}) async {
  await db.insertBodyLog(
    BodyEntry(
      id: id,
      dateStr: dateStr,
      weightKg: weightKg,
      waistCm: waistCm,
    ).toMap(),
  );
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  group('sparklineNormalise', () {
    test('maps the range onto 0..1', () {
      expect(sparklineNormalise([70.0, 72.0, 74.0]), [0.0, 0.5, 1.0]);
    });

    test('a flat series sits in the middle rather than dividing by zero', () {
      expect(sparklineNormalise([72.0, 72.0, 72.0]), [0.5, 0.5, 0.5]);
    });

    test('a series too short to draw returns nothing', () {
      expect(sparklineNormalise([72.0]), isEmpty);
      expect(sparklineNormalise(const []), isEmpty);
    });

    test('a descending series normalises without reordering', () {
      expect(sparklineNormalise([74.0, 72.0, 70.0]), [1.0, 0.5, 0.0]);
    });

    test(
      'a single outlier still normalises the rest against the full range',
      () {
        // Q3: an outlier must not be silently clipped out of the range — every
        // other point still lands correctly relative to a range the outlier
        // itself defines.
        expect(sparklineNormalise([72.0, 72.5, 73.0, 100.0]), [
          0.0,
          0.017857142857142856,
          0.03571428571428571,
          1.0,
        ]);
      },
    );
  });

  group('Sparkline', () {
    testWidgets('draws when it has data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: Sparkline(
              values: const [70.0, 71.5, 71.0, 72.4],
              lineColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders an empty box rather than failing on one point', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: Sparkline(values: const [70.0], lineColor: Colors.black),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  Future<void> pumpBody(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(theme: lockoutTestTheme(), home: BodyTab()));
    await settle(t);
  }

  testWidgets(
    'empty measurements explain the next action without invented data',
    (t) async {
      await pumpBody(t);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.text('Log measurement'), findsOneWidget);
      expect(
        find.text('Your measurements will appear here after you log one.'),
        findsOneWidget,
      );
    },
  );
  for (final weights in [
    [80.0],
    [80.0, 82.0],
    [82.0, 80.0],
  ]) {
    testWidgets(
      'trend uses chronological measured values ${weights.join(",")}',
      (t) async {
        for (var i = 0; i < weights.length; i++) {
          await _insertLog(
            DatabaseService.instance,
            id: 'entry-$i',
            dateStr: '2026-09-0${i + 1}',
            weightKg: weights[i],
          );
        }
        await pumpBody(t);
        final trend = t.widget<NvTrend>(find.byType(NvTrend));
        expect(trend.values, weights);
        expect(
          find.textContaining('${weights.last.toStringAsFixed(1)} kg'),
          findsWidgets,
        );
      },
    );
  }
  testWidgets('same-date readings preserve database ordering', (t) async {
    await _insertLog(
      DatabaseService.instance,
      id: 'a',
      dateStr: '2026-09-01',
      weightKg: 80,
    );
    await _insertLog(
      DatabaseService.instance,
      id: 'b',
      dateStr: '2026-09-01',
      weightKg: 82,
    );
    await pumpBody(t);
    expect(t.widget<NvTrend>(find.byType(NvTrend)).values, [80, 82]);
  });
  testWidgets('deletion undo restores identity and all measurement fields', (
    t,
  ) async {
    final db = DatabaseService.instance;
    await _insertLog(
      db,
      id: 'a',
      dateStr: '2026-09-01',
      weightKg: 80,
      waistCm: 91,
    );
    final before = await db.getBodyLogs();
    await pumpBody(t);
    await t.tap(find.byTooltip('Delete entry'));
    await settle(t);
    expect(await db.getBodyLogs(), isEmpty);
    await t.tap(find.text('Undo'));
    await settle(t);
    expect(await db.getBodyLogs(), before);
    await t.pump(const Duration(seconds: 6));
  });
  testWidgets('expired undo leaves the entry deleted', (t) async {
    await _insertLog(
      DatabaseService.instance,
      id: 'a',
      dateStr: '2026-09-01',
      weightKg: 80,
    );
    await pumpBody(t);
    await t.tap(find.byTooltip('Delete entry'));
    await settle(t);
    await t.pump(const Duration(seconds: 6));
    expect(find.text('Undo'), findsNothing);
    expect(await DatabaseService.instance.getBodyLogs(), isEmpty);
  });
  testWidgets('BMI explains real profile inputs', (t) async {
    final db = DatabaseService.instance;
    await db.saveSetting('height_cm', '180');
    await _insertLog(db, id: 'a', dateStr: '2026-09-01', weightKg: 81);
    await pumpBody(t);
    await t.tap(find.text('About your BMI'));
    await settle(t);
    expect(find.text('How it is calculated'), findsOneWidget);
    expect(find.text('25.0'), findsOneWidget);
    expect(find.text('An estimate, not a diagnosis.'), findsOneWidget);
  });
  for (final bad in ['NaN', 'Infinity', 'not a number']) {
    testWidgets('poisoned measurement $bad does not strand loading', (t) async {
      final db = await DatabaseService.instance.database;
      await db.insert('body_logs', {
        'id': 'bad',
        'date_str': '2026-09-01',
        'weight_kg': bad,
        'waist_cm': 0,
      });
      await pumpBody(t);
      expect(find.text('Measurements'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
}
