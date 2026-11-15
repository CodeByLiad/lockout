import '../models/models.dart';
import 'database_service.dart';
import 'energy_estimator.dart';
import 'numeric_guard.dart';
import 'schedule_service.dart';

/// Estimated workout burn, summed over the reporting windows Settings shows.
class BurnTotals {
  final double todayKcal;
  final double weekKcal;
  final double allTimeKcal;

  /// Completed workouts counted, whether or not each one had an estimate.
  final int sessions;

  const BurnTotals({
    required this.todayKcal,
    required this.weekKcal,
    required this.allTimeKcal,
    required this.sessions,
  });

  static const empty =
      BurnTotals(todayKcal: 0, weekKcal: 0, allTimeKcal: 0, sessions: 0);
}

/// How a finished workout's estimated burn feeds the food budget and the
/// totals in Settings.
class BurnService {
  BurnService._();

  /// '1' (or absent) counts workout burn in the daily food budget, '0' does not.
  static const settingKey = 'count_burn_in_budget';

  static Future<bool> countsInBudget() async =>
      await DatabaseService.instance.getSetting(settingKey, defaultValue: '1') !=
      '0';

  static Future<void> setCountsInBudget(bool value) =>
      DatabaseService.instance.saveSetting(settingKey, value ? '1' : '0');

  /// Calories left today. Null when there is no target to measure against.
  static int? remainingKcal({
    required int? target,
    required int eaten,
    required double burned,
    required bool countBurn,
  }) {
    if (target == null) return null;
    final allowance = countBurn && burned > 0 ? burned.round() : 0;
    return target + allowance - eaten;
  }

  /// The Saturday that starts the reporting week containing [now], matching
  /// the Progress screen's Saturday-to-Friday week.
  static DateTime weekStart(DateTime now) => DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - DateTime.saturday + 7) % 7,
      );

  static BurnTotals totals(
    Iterable<Map<String, dynamic>> sessionRows, {
    required DateTime now,
  }) {
    final today = ScheduleService.dateKey(now);
    final start = ScheduleService.dateKey(weekStart(now));
    var todayKcal = 0.0;
    var weekKcal = 0.0;
    var allTime = 0.0;
    var sessions = 0;
    for (final row in sessionRows) {
      if (row['status'] != 'completed') continue;
      sessions++;
      final kcal = NumericGuard.read(row['kcal_burned']) ?? 0.0;
      if (kcal <= 0) continue;
      final date = '${row['date_str'] ?? ''}';
      allTime += kcal;
      // ISO date keys sort the same way as the dates they name.
      if (date.compareTo(start) >= 0 && date.compareTo(today) <= 0) {
        weekKcal += kcal;
      }
      if (date == today) todayKcal += kcal;
    }
    return BurnTotals(
      todayKcal: todayKcal,
      weekKcal: weekKcal,
      allTimeKcal: allTime,
      sessions: sessions,
    );
  }

  static Future<BurnTotals> load({DateTime? now}) async => totals(
        await DatabaseService.instance.getSessionLogs(),
        now: now ?? DateTime.now(),
      );
}

/// Planning-time estimates for the routine builder, before any set is logged.
class RoutineEstimate {
  RoutineEstimate._();

  /// Time under load per working set, before the rest that follows it.
  static const workSecondsPerSet = 40;

  static int seconds(List<ExerciseDef> exercises) => exercises.fold(
        0,
        (sum, e) =>
            sum + e.targetSets * (workSecondsPerSet + e.restDefaultS.clamp(0, 600)),
      );

  /// Null without a bodyweight or without any planned sets: no honest
  /// estimate exists, same rule as [EnergyEstimator.estimate].
  static double? kcal(List<ExerciseDef> exercises, double? bodyweightKg) {
    if (bodyweightKg == null || bodyweightKg <= 0) return null;
    final duration = seconds(exercises);
    if (duration <= 0) return null;
    final counts = <String, int>{};
    for (final e in exercises) {
      counts[e.muscleGroup] = (counts[e.muscleGroup] ?? 0) + e.targetSets;
    }
    final group =
        counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    return EnergyEstimator.kcal(
      met: EnergyEstimator.metForGroup(group),
      bodyweightKg: bodyweightKg,
      durationSeconds: duration,
    );
  }
}
