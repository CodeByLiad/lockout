import 'package:flutter/material.dart';
import '../services/display_units.dart';

import '../theme/lockout_shapes.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_feedback.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/schedule_service.dart';
import '../theme/lockout_theme.dart';

/// The archive card's detail line.
///
/// A top-level function rather than a private method so it can be tested
/// without pumping the screen, and so the burn's presence rule lives in one
/// place: no estimate means the segment is absent, never "0 kcal".
String sessionArchiveLine(SessionLog log) => [
  log.dateStr,
  log.durationLabel,
  '${log.totalSets} sets',
  if (log.kcalLabel.isNotEmpty) log.kcalLabel,
].join('  -  ');

/// A whole-kilogram label, or `--` when the figure is not a real number.
///
/// Belt to the braces `NumericGuard` puts on every write site: `toInt()`
/// throws `Unsupported operation: Infinity or NaN` rather than returning
/// anything, and it is called from `build()`, so one poisoned
/// `total_volume_kg` written by a build shipped before those guards turns
/// LOG into a red error screen on every launch — including the archive row
/// whose DELETE ENTRY is the only way to get rid of the bad session. No
/// migration can find such a row after the fact, so the render side has to
/// survive it.
String kgWhole(double kg) => kg.isFinite ? '${kg.toInt()}' : '--';

class LogTab extends StatefulWidget {
  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  LogTab({super.key});

  @override
  State<LogTab> createState() => LogTabState();
}

class LogTabState extends State<LogTab> {
  List<SessionLog> _logs = [];
  int _streakDays = 0;
  bool _isLoading = true;

  /// Sets for sessions the user has expanded, loaded lazily.
  final Map<String, List<SetLog>> _expandedSets = {};
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  /// Called by MainScreen so a session finished on the Today tab shows here
  /// immediately, without an app restart.
  Future<void> reload() => _loadLogs();

  Future<void> _loadLogs() async {
    final db = DatabaseService.instance;
    final rows = await db.getSessionLogs();
    final dates = await db.getWorkoutDates();

    if (!mounted) return;
    setState(() {
      _logs = rows.map(SessionLog.fromMap).toList();
      _streakDays = ScheduleService.currentStreakDays(dates);
      _isLoading = false;
      _expanded.clear();
      _expandedSets.clear();
    });
  }

  /// Deletes [log] and its set detail immediately (`deleteSessionLog`
  /// removes both, atomically), then offers a few seconds to reverse it
  /// through the same `showUndoBanner` mechanism BODY and FOOD already use
  /// (Ruling F) — not the pre-v2 confirm-dialog, which guarded the tap with
  /// a modal but left no way back once DELETE was actually pressed. The
  /// sets are fetched *before* the delete — a closed card never populates
  /// `_expandedSets`, so that cache cannot be relied on to still hold them
  /// for restore.
  Future<void> _deleteLog(SessionLog log) async {
    final db = DatabaseService.instance;
    final setRows = (await db.getSetLogsForSession(
      log.id,
    )).map(SetLog.fromMap).toList();

    await db.deleteSessionLog(log.id);
    if (!mounted) return;
    await _loadLogs();
    if (!mounted) return;

    showNvUndo(
      context,
      message: '${log.dayName} workout deleted',
      onUndo: () => _restoreLog(log, setRows),
    );
  }

  /// Re-inserts [log] with its original id and every field intact, then its
  /// [sets] the same way, atomically (`DatabaseService.restoreSessionLog`)
  /// so an interruption mid-restore cannot leave a header with no sets.
  /// `ConflictAlgorithm.replace` on both tables makes this a true restore,
  /// not a near-copy with freshly minted ids. Reinserting the sets in their
  /// original order preserves `getSetLogsForSession`'s `rowid ASC` reading
  /// of them even though the delete cleared their prior rowids.
  Future<void> _restoreLog(SessionLog log, List<SetLog> sets) async {
    final db = DatabaseService.instance;
    await db.restoreSessionLog(
      log.toMap(),
      sets.map((s) => s.toMap()).toList(),
    );
    if (!mounted) return;
    await _loadLogs();
  }

  double get _totalVolumeAllTime =>
      _logs.fold(0.0, (sum, l) => sum + l.totalVolumeKg);

  String get _streakLabel {
    if (_streakDays == 0) return 'No active streak';
    return _streakDays == 1 ? '1 day streak' : '$_streakDays day streak';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final completed = _logs.where((l) => l.status == 'completed').toList();
    return NvPage(
      title: 'Workout history',
      back: Navigator.of(context).canPop(),
      children: [
        NvSurface(
          tone: NvTone.primary,
          child: Row(
            children: [
              const NvIconBadge(
                icon: Icons.local_fire_department_outlined,
                shape: LockoutShape.sunny,
                size: 64,
                tone: NvTone.surface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _streakLabel,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${completed.length} workouts · ${kgWhole(_totalVolumeAllTime)} kg total',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const NvHeading('Your workouts'),
        if (_logs.isEmpty)
          const NvEmpty(
            title: 'Your next chapter starts here',
            message:
                'Finish a workout and your completed sets will appear here automatically.',
            icon: Icons.history_rounded,
          ),
        NvGroupedList(
          children: [
            for (var i = 0; i < _logs.length; i++)
              NvListItem(
                leading: NvIconBadge(
                  icon: Icons.fitness_center_rounded,
                  shape: LockoutShape.values[[11, 8, 14, 6, 9][i % 5]],
                  tone: NvTone.values[i % 3],
                ),
                title: _logs[i].dayName,
                supporting: sessionArchiveLine(_logs[i]),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openDetail(_logs[i]),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openDetail(SessionLog log) async {
    final rows = await DatabaseService.instance.getSetLogsForSession(log.id);
    if (!mounted) return;
    final sets = rows.map(SetLog.fromMap).toList();
    final grouped = _groupByExercise(sets);
    await showNvEditor<void>(
      context: context,
      title: log.dayName,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.dateStr, style: Theme.of(ctx).textTheme.bodyLarge),
          const SizedBox(height: 20),
          NvSurface(
            tone: NvTone.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.durationLabel,
                  style: Theme.of(ctx).textTheme.displayMedium,
                ),
                Text(
                  '${log.totalSets} sets · ${DisplayUnits.format(ctx, log.totalVolumeKg, decimals: 0)}',
                ),
                if (log.kcalLabel.isNotEmpty)
                  Text('${log.kcalLabel} estimated energy'),
              ],
            ),
          ),
          const NvHeading('Exercises'),
          if (sets.isEmpty)
            const Text('No set detail was stored for this workout.'),
          for (final entry in grouped.entries) ...[
            NvSurface(
              tone: NvTone.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Text('Set')),
                      Expanded(child: Text('Weight')),
                      Expanded(child: Text('Reps')),
                    ],
                  ),
                  for (final set in entry.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${set.setIndex}',
                              style: LockoutTheme.numeric(ctx, size: 15),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              DisplayUnits.format(ctx, set.weightKg),
                              style: LockoutTheme.numeric(ctx, size: 15),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${set.reps}',
                              style: LockoutTheme.numeric(ctx, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          NvButton(
            variant: NvButtonVariant.danger,
            label: 'Delete workout',
            onPressed: () async {
              await _deleteLog(log);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Map<String, List<SetLog>> _groupByExercise(List<SetLog> sets) {
    final grouped = <String, List<SetLog>>{};
    for (final set in sets) {
      grouped.putIfAbsent(set.exerciseName, () => []).add(set);
    }
    return grouped;
  }
}
