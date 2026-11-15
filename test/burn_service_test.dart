import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/services/burn_service.dart';

Map<String, dynamic> _session(String date, double kcal,
        {String status = 'completed'}) =>
    {
      'id': '$date-$kcal',
      'date_str': date,
      'status': status,
      'kcal_burned': kcal,
    };

ExerciseDef _ex(String name, {int sets = 3, String group = 'Chest'}) =>
    ExerciseDef(
      id: name,
      dayId: 'd',
      name: name,
      targetSets: sets,
      targetRepsMin: 8,
      targetRepsMax: 12,
      muscleGroup: group,
    );

void main() {
  group('BurnService.totals', () {
    // Sunday 15 November 2026. The reporting week started Saturday 14th.
    final now = DateTime(2026, 11, 15, 18);

    test('splits completed sessions into today, Saturday week and all time',
        () {
      final totals = BurnService.totals([
        _session('2026-11-15', 300),
        _session('2026-11-14', 200),
        _session('2026-11-13', 150), // Friday: previous week
        _session('2026-10-01', 100),
      ], now: now);

      expect(totals.todayKcal, closeTo(300, 0.001));
      expect(totals.weekKcal, closeTo(500, 0.001));
      expect(totals.allTimeKcal, closeTo(750, 0.001));
      expect(totals.sessions, 4);
    });

    test('ignores sessions that are not completed and bad numbers', () {
      final totals = BurnService.totals([
        _session('2026-11-15', 300, status: 'abandoned'),
        {'date_str': '2026-11-15', 'status': 'completed', 'kcal_burned': 'x'},
      ], now: now);

      expect(totals.todayKcal, 0);
      expect(totals.sessions, 1);
    });
  });

  group('BurnService.remainingKcal', () {
    test('adds the burn to the budget when counting is on', () {
      expect(
        BurnService.remainingKcal(
          target: 2000,
          eaten: 1500,
          burned: 320.4,
          countBurn: true,
        ),
        820,
      );
    });

    test('leaves the budget alone when counting is off', () {
      expect(
        BurnService.remainingKcal(
          target: 2000,
          eaten: 1500,
          burned: 320,
          countBurn: false,
        ),
        500,
      );
    });

    test('no target means no remaining figure', () {
      expect(
        BurnService.remainingKcal(
          target: null,
          eaten: 0,
          burned: 300,
          countBurn: true,
        ),
        isNull,
      );
    });
  });

  group('RoutineEstimate', () {
    test('estimates a day from its sets and rest', () {
      final seconds = RoutineEstimate.seconds([
        _ex('Bench Press', sets: 3),
        _ex('Fly', sets: 2),
      ]);
      // 5 sets x (40 s work + 60 s rest).
      expect(seconds, 500);
    });

    test('kcal needs a bodyweight', () {
      expect(RoutineEstimate.kcal([_ex('Bench Press')], null), isNull);
      expect(
        RoutineEstimate.kcal([_ex('Bench Press')], 80),
        greaterThan(0),
      );
    });

    test('an empty day estimates nothing', () {
      expect(RoutineEstimate.seconds(const []), 0);
      expect(RoutineEstimate.kcal(const [], 80), isNull);
    });
  });
}
