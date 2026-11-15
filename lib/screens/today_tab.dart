import 'dart:async';
import 'package:flutter/material.dart';
import '../services/display_units.dart';

import 'progress_tab.dart' show ProgressSegment;
import '../theme/lockout_shapes.dart';
import '../theme/lockout_semantics.dart';
import '../theme/lockout_theme.dart';
import '../models/models.dart';
import '../services/burn_service.dart';
import '../services/database_service.dart';
import '../services/energy_estimator.dart';
import '../services/goal_service.dart';
import '../services/numeric_guard.dart';
import '../services/schedule_service.dart';
import '../widgets/house/nv_exercise_picker.dart';
import '../widgets/house/nv_set_row.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_cards.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_dialog.dart';
import '../widgets/house/nv_sheet.dart';
import '../widgets/house/nv_wavy_progress.dart';
import 'exercise_video_screen.dart';

/// One set inside a running session.
class _LiveSet {
  double weightKg;
  int reps;
  bool completed = false;

  _LiveSet({required this.weightKg, required this.reps});
}

/// One exercise inside a running session, seeded from the routine's target.
class _LiveExercise {
  final String exerciseId; // '' when added ad-hoc mid-session
  final String name;
  final String videoUrl;
  final int restSeconds;
  final String targetLabel;
  final List<_LiveSet> sets;

  /// Completed sets from the last time this exercise was trained.
  String lastPerformance = '';

  _LiveExercise({
    required this.exerciseId,
    required this.name,
    required this.videoUrl,
    required this.restSeconds,
    required this.targetLabel,
    required this.sets,
  });

  int get completedCount => sets.where((s) => s.completed).length;

  double get volumeKg => sets
      .where((s) => s.completed)
      .fold(0.0, (sum, s) => sum + s.weightKg * s.reps);
}

/// Everything Today's "numbers" rows need, resolved by the screen.
///
/// Nulls are meaningful: they mean "not on record", and a row renders a
/// prompt instead of a number. A zero would be a lie.
///
/// Local to this screen rather than `_TodaySummary`: `home_hub.dart` was
/// written for the previous design, and a rebuilt screen composes from
/// `lib/widgets/house/` and the theme only.
class _TodaySummary {
  final int kcalEaten;

  /// The daily calorie target. Nullable so a widget test can exercise the
  /// "no target set" prompt with no database.
  final int? kcalTarget;

  final double? weightKg;
  final double? weightDeltaKg;

  /// Total estimated kcal burned today. Null means no session was logged
  /// today at all. A non-null value of zero or less means a session *was*
  /// logged but no estimate could be made for it, which reads as "estimate
  /// unavailable" rather than denying the session happened.
  final double? burnedTodayKcal;

  /// The goal weight. Null when no goal is configured, in which case the
  /// weight row states the weight without inventing a gap.
  final double? targetWeightKg;

  final double proteinEatenG;

  /// Null until a nutrition plan exists to derive one from.
  final int? proteinTargetG;

  /// Recent weights, oldest first, for the trend line. Fewer than two points
  /// cannot make a line.
  final List<double> weightSeries;

  const _TodaySummary({
    required this.kcalEaten,
    required this.kcalTarget,
    required this.weightKg,
    required this.weightDeltaKg,
    required this.burnedTodayKcal,
    this.targetWeightKg,
    this.proteinEatenG = 0,
    this.proteinTargetG,
    this.weightSeries = const [],
  });
}

/// Each quick action's fixed shape (deviation D13), assigned once here so
/// the same action wears the same shape on every screen.
///
/// No cookie (those are D5's registers, for subject-scale elements only) and
/// no circle (every tile morphs to it when pressed).
@visibleForTesting
const Map<String, LockoutShape> quickActionShapes = {
  'Log food': LockoutShape.bun,
  'Weigh in': LockoutShape.pentagon,
  'Workout': LockoutShape.gem,
  'History': LockoutShape.arch,
  'Custom': LockoutShape.clover4Leaf,
  'Streak': LockoutShape.sunny,
  'Plan': LockoutShape.diamond,
  'Exercises': LockoutShape.slanted,
};

class TodayTab extends StatefulWidget {
  /// Switches tabs by id — 'routines', 'food', 'body', 'log'. Supplied by
  /// MainScreen; null in tests that pump this tab on its own.
  /// Switches tabs by id.
  ///
  /// [segment] is meaningful only for `'progress'`, which hosts both the
  /// weight view and the session history behind one tab id — "Weigh in" and
  /// "History" must not open the same half.
  final void Function(String tabId, {ProgressSegment? segment})? onNavigate;

  /// Whether the Food tab is currently reachable. When false, the hub must
  /// not offer a tap target that silently does nothing.
  final bool foodTabEnabled;
  final VoidCallback? onOpenSettings;
  final ValueChanged<bool>? onSessionChanged;
  final bool presentSessionAsRoute;

  /// The wall clock every live-session reading goes through.
  ///
  /// Injectable for one case the ticker cannot reach on its own: Android
  /// freezes a cached app mid-workout, so the process gets no timer
  /// callbacks for minutes and then resumes with real time having moved.
  /// A test can reproduce that exactly — advance this clock without
  /// advancing the ticker — which is the only way to tell a self-correcting
  /// clock apart from a tick-counted one. `DateTime.now` in production, and
  /// nothing outside `lib/screens/today_tab.dart` passes it.
  final DateTime Function() clock;

  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  TodayTab({
    super.key,
    this.onNavigate,
    this.foodTabEnabled = true,
    this.onOpenSettings,
    this.onSessionChanged,
    this.presentSessionAsRoute = false,
    this.clock = DateTime.now,
  });

  @override
  State<TodayTab> createState() => TodayTabState();
}

class TodayTabState extends State<TodayTab> {
  final _sessionRevision = ValueNotifier<int>(0);
  Route<void>? _workoutRoute;
  bool _openingSession = false;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_workoutRoute != null || _restSheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sessionRevision.value++;
      });
    }
  }

  Future<void> resumeSession() async {
    if (!_sessionActive || !mounted || _workoutRoute != null) return;
    final route = MaterialPageRoute<void>(
      builder: (routeContext) => ValueListenableBuilder<int>(
        valueListenable: _sessionRevision,
        builder: (_, revision, child) => Scaffold(
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildActiveSession(),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_restRunning) _buildRestBar(),
                Padding(
                  padding: const EdgeInsets.all(LockoutTheme.cardPadding),
                  child: _workoutActions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _workoutRoute = route;
    await Navigator.of(context).push(route);
    _workoutRoute = null;
    if (mounted) setState(() {});
  }

  ScheduledDay? _scheduled;
  Routine? _activeRoutine;
  bool _planHasDays = false;
  ScheduledDay? _sessionScheduled;
  List<SessionLog> _recentSessions = [];
  bool _sessionSaving = false;
  bool _confirmingFinish = false;
  bool _restSheetOpen = false;
  bool _isLoading = true;

  /// Settings > Nutrition: whether workout burn widens today's food budget.
  bool _countBurn = true;
  _TodaySummary _summary = const _TodaySummary(
    kcalEaten: 0,
    kcalTarget: null,
    weightKg: null,
    weightDeltaKg: null,
    burnedTodayKcal: null,
  );

  bool _sessionActive = false;
  DateTime? _startedAt;
  String _sessionTitle = '';
  List<_LiveExercise> _liveExercises = [];

  int _elapsedSeconds = 0;

  /// Seconds still to rest. Derived from [_restEndsAt] by `_syncRest`, never
  /// counted down; it is a field only because the label and the bar both
  /// read it on every build.
  int _restSeconds = 0;

  /// When the running rest ends, in wall-clock time.
  ///
  /// The countdown's single source of truth, the way `_startedAt` is the
  /// elapsed clock's. The +/-15s controls move this, not the counter.
  DateTime? _restEndsAt;

  /// The rest duration `_beginRest` was called with, kept so `_buildRestBar`
  /// can paint a remaining-time progress bar. Moves with the +/-15s controls
  /// so the bar's denominator never goes stale.
  int _restTotalSeconds = 0;
  bool _restRunning = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sessionRevision.dispose();
    super.dispose();
  }

  /// The session's wall clock. See `TodayTab.clock`.
  DateTime _now() => widget.clock();

  /// Called by MainScreen when the user returns to this tab, so a routine
  /// edited on the Routines tab, or a log entered on another tab, shows up
  /// here without an app restart.
  ///
  /// `_isLoading` only clears once both loads resolve. Clearing it after
  /// just the schedule load let the hub render its "not on record" prompts
  /// — `SET A GOAL`, `LOG A WEIGHT`, `NO SESSION YET` — for a frame or more
  /// even when the summary data exists but simply hasn't arrived yet, which
  /// reads as a lie rather than a loading state.
  Future<void> reload() async {
    await _loadSchedule();
    await _loadSummary();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadSchedule() async {
    final resolved = await ScheduleService.resolveToday();
    final db = DatabaseService.instance;
    final active = await db.getActiveRoutine();
    final days = active == null
        ? const []
        : await db.getDaysForRoutine(active['id'] as String);
    if (!mounted) return;
    setState(() {
      _scheduled = resolved;
      _activeRoutine = active == null ? null : Routine.fromMap(active);
      _planHasDays = days.isNotEmpty;
    });
  }

  /// Resolves everything the hub shows. Every value can legitimately be
  /// unknown, and the hub renders a prompt for a null rather than a zero.
  Future<void> _loadSummary() async {
    final today = ScheduleService.dateKey(DateTime.now());
    final db = DatabaseService.instance;

    final foodRows = await db.getFoodLogsForDate(today);
    final eaten = foodRows.fold<int>(
      0,
      (sum, row) => sum + (NumericGuard.readInt(row['kcal']) ?? 0),
    );
    // Guarded like the kcal sum above: a hand-edited backup can put a
    // non-numeric protein_g in the table, and an unguarded fold would put a
    // NaN straight into a progress bar.
    final proteinEaten = foodRows.fold<double>(
      0.0,
      (sum, row) => sum + (NumericGuard.read(row['protein_g']) ?? 0.0),
    );

    // snapshot() already fetches body logs for currentWeightKg and resolves
    // the shared calorie target (Ruling A); reuse both instead of a second
    // getBodyLogs() call or re-deriving the target here.
    final snapshot = await GoalService.instance.snapshot();
    final delta = GoalService.weightDeltaKg(snapshot.bodyLogs);

    final sessionRows = await db.getSessionLogsForDate(today);
    final recentRows = await db.getSessionLogs();
    // Null means "no session logged today" — the honest NO SESSION YET case.
    // A session that *was* logged but couldn't be estimated (no bodyweight
    // on record) sums to 0.0, which is a real, different state: the row
    // must not claim there was no session at all. See `HomeHub._burnValue`.
    final countBurn = await BurnService.countsInBudget();
    final burnedToday = sessionRows.isEmpty
        ? null
        : sessionRows.fold<double>(
            0.0,
            (sum, r) => sum + (NumericGuard.read(r['kcal_burned']) ?? 0.0),
          );

    if (!mounted) return;
    setState(() {
      _countBurn = countBurn;
      _recentSessions = recentRows
          .map(SessionLog.fromMap)
          .where((s) => s.status == 'completed')
          .toList();
      _summary = _TodaySummary(
        kcalEaten: eaten,
        kcalTarget: snapshot.calorieTarget,
        weightKg: snapshot.currentWeightKg,
        weightDeltaKg: delta,
        burnedTodayKcal: burnedToday,
        // A target weight of 0 means "not configured" in the stored profile,
        // so it maps to null rather than a goal of zero kilos.
        targetWeightKg: snapshot.profile.targetWeightKg > 0
            ? snapshot.profile.targetWeightKg
            : null,
        proteinEatenG: proteinEaten,
        proteinTargetG: snapshot.nutrition?.proteinG,
        weightSeries: _weightSeries(snapshot.bodyLogs),
      );
    });
  }

  /// The last few weigh-ins, oldest first, for the trend line.
  ///
  /// Capped because the card draws a fixed-width sparkline: past a couple of
  /// dozen points the line stops reading as a direction and starts reading as
  /// noise. Unreadable rows are dropped rather than defaulted — a 0.0 would
  /// put a false cliff in the trend.
  static List<double> _weightSeries(List<Map<String, dynamic>> bodyLogs) {
    final weights = <double>[];
    for (final row in bodyLogs) {
      final w = NumericGuard.read(row['weight_kg']);
      if (w != null && w > 0) weights.add(w);
    }
    final recent = weights.length > 30 ? weights.sublist(0, 30) : weights;
    // getBodyLogs returns newest first; a trend line reads oldest to newest.
    return recent.reversed.toList();
  }

  // --- SESSION LIFECYCLE ---

  /// Starts today's scheduled session.
  ///
  /// Public so the Workout tab's featured-day card can start the session the
  /// user is looking at, rather than sending them to Home to press a second
  /// button. `MainScreen` owns the wiring; this stays the only implementation.
  Future<void> startScheduledSession() => _startScheduledSession();
  Future<void> startDay(ScheduledDay day) async {
    if (_sessionActive) {
      await resumeSession();
      return;
    }
    _scheduled = day;
    await _startScheduledSession();
  }

  Future<void> _startScheduledSession() async {
    if (_sessionActive) {
      await resumeSession();
      return;
    }
    final sched = _scheduled;
    if (sched == null || sched.day.isRestDay || sched.exercises.isEmpty) return;

    final live = <_LiveExercise>[];
    for (final ex in sched.exercises) {
      live.add(
        _LiveExercise(
          exerciseId: ex.id,
          name: ex.name,
          videoUrl: ex.videoUrl,
          restSeconds: ex.restDefaultS,
          targetLabel: ex.targetLabel,
          sets: List.generate(
            ex.targetSets,
            (_) =>
                _LiveSet(weightKg: ex.targetWeightKg, reps: ex.targetRepsMax),
          ),
        ),
      );
    }

    await _beginSession(sched.day.name, live, origin: sched);
  }

  Future<void> _startCustomSession() async {
    if (_sessionActive || _openingSession) {
      await resumeSession();
      return;
    }
    await _beginSession('Custom session', []);
  }

  Future<void> _beginSession(
    String title,
    List<_LiveExercise> exercises, {
    ScheduledDay? origin,
  }) async {
    if (_openingSession || _sessionActive) return;
    _openingSession = true;
    try {
      for (final e in exercises) {
        e.lastPerformance = await _fetchLastPerformance(e.name);
      }
    } catch (_) {
      // A missing history read must not prevent an offline workout.
      for (final e in exercises) {
        e.lastPerformance = 'Previous performance unavailable';
      }
    } finally {
      _openingSession = false;
    }
    if (!mounted) return;

    setState(() {
      _sessionActive = true;
      _sessionScheduled = origin;
      _sessionTitle = title;
      _liveExercises = exercises;
      _startedAt = _now();
      _elapsedSeconds = 0;
      _restSeconds = 0;
      _restEndsAt = null;
      _restTotalSeconds = 0;
      _restRunning = false;
    });
    _startTicker();
    widget.onSessionChanged?.call(true);
    if (widget.presentSessionAsRoute) {
      unawaited(resumeSession());
    }
  }

  Future<String> _fetchLastPerformance(String exerciseName) async {
    final rows = await DatabaseService.instance.getLastPerformance(
      exerciseName,
    );
    if (rows.isEmpty) return '';
    final sets = rows.map(SetLog.fromMap).toList();
    final reps = sets.map((s) => s.reps).join(',');
    final weight = sets.first.weightKg;
    return '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1)}kg x $reps';
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_startedAt != null) {
          _elapsedSeconds = _now().difference(_startedAt!).inSeconds;
        }
        if (_restRunning) _syncRest();
      });
    });
  }

  /// Recomputes the rest countdown from [_restEndsAt], exactly the way the
  /// line above recomputes elapsed time from `_startedAt`.
  ///
  /// Decrementing a counter once per tick instead made the two clocks on
  /// this screen disagree the moment the ticker missed a beat — and the case
  /// where it misses is not an edge case, it is Android freezing a cached
  /// app mid-workout. On resume elapsed snapped back to the truth and rest
  /// did not: a 90s rest still read 60s after three real minutes.
  ///
  /// Call inside `setState`.
  void _syncRest() {
    final endsAt = _restEndsAt;
    if (endsAt == null) {
      _restSeconds = 0;
      _restRunning = false;
      return;
    }
    final msLeft = endsAt.difference(_now()).inMilliseconds;
    if (msLeft <= 0) {
      _restSeconds = 0;
      _restRunning = false;
      _restEndsAt = null;
      return;
    }
    // Rounded up: a tick arriving a few milliseconds late still reads the
    // second it is in. Truncating would skip a number on a slow frame.
    _restSeconds = (msLeft / 1000).ceil();
  }

  void _beginRest(int seconds) {
    setState(() {
      _restEndsAt = _now().add(Duration(seconds: seconds));
      _restTotalSeconds = seconds;
      _restRunning = true;
      _syncRest();
    });
    if (widget.presentSessionAsRoute) unawaited(_openRestTimer());
  }

  double get _sessionVolumeKg =>
      _liveExercises.fold(0.0, (sum, e) => sum + e.volumeKg);

  int get _sessionCompletedSets =>
      _liveExercises.fold(0, (sum, e) => sum + e.completedCount);

  int get _sessionTotalSets =>
      _liveExercises.fold(0, (sum, e) => sum + e.sets.length);

  String get _elapsedLabel => _clockLabel(_elapsedSeconds);

  String _clockLabel(int seconds) {
    final elapsed = seconds < 0 ? 0 : seconds;
    final m = (elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _addExerciseMidSession() async {
    final picked = await showExercisePicker(context);
    if (picked == null || !mounted) return;

    final live = _LiveExercise(
      exerciseId: '',
      name: picked.name,
      videoUrl: '',
      restSeconds: 60,
      targetLabel: picked.repsMin == picked.repsMax
          ? '${picked.sets}x${picked.repsMin}'
          : '${picked.sets}x${picked.repsMin}-${picked.repsMax}',
      sets: List.generate(
        picked.sets,
        (_) => _LiveSet(weightKg: 0, reps: picked.repsMax),
      ),
    );
    live.lastPerformance = await _fetchLastPerformance(picked.name);

    if (!mounted) return;
    setState(() => _liveExercises.add(live));
  }

  Future<void> _finishSession({DateTime? completedAt}) async {
    if (_sessionSaving) return;
    setState(() => _sessionSaving = true);
    try {
      await _saveSession(completedAt: completedAt);
    } finally {
      if (mounted) setState(() => _sessionSaving = false);
    }
  }

  Future<void> _saveSession({DateTime? completedAt}) async {
    if (_sessionCompletedSets == 0) {
      final discard = await _confirmDiscard();
      if (discard != true) return;
      _endSessionState();
      return;
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final ended = completedAt ?? _now();
    final started = _startedAt ?? ended;
    final elapsed = ended.difference(started).inSeconds;
    final duration = elapsed < 0 ? 0 : elapsed;
    final sched = _sessionScheduled;

    // Only completed sets are archived — an untouched set is not a data point.
    final sessionSets = <SetLog>[];
    final setRows = <Map<String, dynamic>>[];
    var seq = 0;
    for (final ex in _liveExercises) {
      for (var i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        if (!s.completed) continue;
        final setLog = SetLog(
          id: '$sessionId-${seq++}',
          sessionExerciseId: ex.exerciseId,
          sessionId: sessionId,
          exerciseName: ex.name,
          setIndex: i + 1,
          weightKg: s.weightKg,
          reps: s.reps,
          isCompleted: true,
        );
        sessionSets.add(setLog);
        setRows.add(setLog.toMap());
      }
    }

    // Bodyweight for the estimate: what the user last logged, else their
    // stated target, else no estimate at all.
    final snapshot = await GoalService.instance.snapshot();
    final bodyweightKg =
        snapshot.currentWeightKg ??
        (snapshot.profile.isConfigured
            ? snapshot.profile.targetWeightKg
            : null);

    final burn = EnergyEstimator.estimate(
      sets: sessionSets,
      dayName: _sessionTitle,
      bodyweightKg: bodyweightKg,
      durationSeconds: duration,
    );

    final session = SessionLog(
      id: sessionId,
      dayName: _sessionTitle,
      dateStr: ScheduleService.dateKey(ended),
      durationSeconds: duration,
      totalVolumeKg: _sessionVolumeKg,
      status: 'completed',
      routineId: sched?.routine.id ?? '',
      dayId: sched?.day.id ?? '',
      totalSets: _sessionCompletedSets,
      kcalBurned: burn ?? 0.0,
    );

    // One transaction, not two writes: a kill between a header insert and
    // its sets leaves a session claiming `totalSets: N` with nothing behind
    // it, which nothing downstream can tell apart from a legitimately
    // detail-free entry. Same argument `deleteSessionLog` and
    // `restoreSessionLog` were given transactions for.
    try {
      await DatabaseService.instance.insertSessionWithSets(
        session.toMap(),
        setRows,
      );
    } catch (_) {
      // Nothing is cleared and the session stays live. This is the one
      // moment the whole workout exists only in this widget's state, so
      // ending the session on a failed write would destroy exactly the data
      // the write failed to keep. Unguarded, the throw escaped this async
      // callback: `_endSessionState` never ran, no snackbar appeared, and in
      // release the user tapped Save and nothing happened at all.
      //
      // `ThemeController.load` guards a write whose loss costs nothing; this
      // one costs a workout, so it is the one that has to say so out loud.
      if (!mounted) return;
      showNvSnackbar(
        context: context,
        message:
            'Session not saved — the write failed. Your sets are still '
            'here; tap Finish to try again.',
      );
      return;
    }

    if (!mounted) return;
    // Refresh BURNED TODAY (and the rest of the summary) so the hub the user
    // lands back on reflects the session just saved, rather than reporting
    // "not on record" about data that was just recorded.
    await _loadSummary();
    if (!mounted) return;
    _endSessionState();
    showNvSnackbar(
      context: context,
      message:
          'Session saved — ${setRows.length} ${setRows.length == 1 ? 'set' : 'sets'}, '
          '${_fmtWeight(session.totalVolumeKg)} kg volume',
    );
    if (widget.presentSessionAsRoute) await _showSavedWorkout(session);
  }

  Future<void> _showSavedWorkout(SessionLog session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => NvPage(
          title: 'Workout saved',
          footer: NvButton(
            variant: NvButtonVariant.filled,
            label: 'Done',
            large: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          children: [
            const Center(
              child: NvIconBadge(
                icon: Icons.check_rounded,
                shape: LockoutShape.achievement,
                size: 120,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                session.dayName,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            NvSurface(
              tone: NvTone.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.durationLabel,
                    style: Theme.of(ctx).textTheme.displayMedium,
                  ),
                  Text(
                    '${session.totalSets} completed ${session.totalSets == 1 ? 'set' : 'sets'} · ${DisplayUnits.format(ctx, session.totalVolumeKg, decimals: 0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SavedBurnCard(
              sessionId: session.id,
              initialKcal: session.kcalBurned,
              onChanged: _loadSummary,
            ),
            const SizedBox(height: 16),
            NvSurface(
              child: NvWeekStrip(
                dates: _recentSessions.map((s) => s.dateStr).toSet(),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.onNavigate != null)
              NvButton(
                variant: NvButtonVariant.tonal,
                label: 'View workout history',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onNavigate?.call(
                    'progress',
                    segment: ProgressSegment.history,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Section 8 allows a dialog for exactly this: a destructive
  /// confirmation. The danger ink lives inside `showNvDestructiveDialog`,
  /// which resolves `false` on a dismissal rather than null, so a caller
  /// cannot read "dismissed" as "confirmed".
  Future<bool?> _confirmDiscard() {
    return showNvDestructiveDialog(
      context: context,
      title: 'Discard session?',
      body: _sessionCompletedSets > 0
          ? '$_sessionCompletedSets logged '
                '${_sessionCompletedSets == 1 ? 'set' : 'sets'} will be lost. '
                'Discard ${_sessionCompletedSets == 1 ? 'it' : 'them'}?'
          : 'No sets were logged, so there is nothing to archive. End the '
                'session?',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep going',
    );
  }

  /// The close button and system back. An empty session just ends; one with
  /// logged sets goes through the same "Discard session?" gate as Finish.
  Future<void> _leaveSession() async {
    if (_sessionCompletedSets > 0) {
      final confirmed = await _confirmDiscard();
      if (confirmed != true || !mounted) return;
    }
    _endSessionState();
  }

  void _endSessionState() {
    final route = _workoutRoute;
    if (route != null && route.isCurrent) Navigator.of(context).pop();
    widget.onSessionChanged?.call(false);
    _ticker?.cancel();
    setState(() {
      _sessionActive = false;
      _sessionScheduled = null;
      _liveExercises = [];
      _startedAt = null;
      _restRunning = false;
      _restSeconds = 0;
      _restEndsAt = null;
      _restTotalSeconds = 0;
      _elapsedSeconds = 0;
    });
  }

  static String _fmtWeight(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _openVideo(String name, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseVideoScreen(exerciseName: name, videoUrl: url),
      ),
    );
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.presentSessionAsRoute || !_sessionActive) {
      return _buildPreSession(context);
    }
    return Scaffold(
      body: PopScope(
        canPop: !_sessionActive,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leaveSession();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(LockoutTheme.screenPadding),
            child: _buildActiveSession(),
          ),
        ),
      ),
      bottomNavigationBar: _restRunning ? _buildRestBar() : null,
    );
  }

  // --- PRE-SESSION (Today's landing surface) ---
  //
  // Rebuilt from the house component catalog rather than adapted from
  // `HomeHub`. The hub was written for the previous design, and adapting it
  // kept that design's decisions — a stack of uniform cards, an all-caps
  // caption, a neutral hero — in places no token could reach.

  Widget _buildPreSession(BuildContext context) {
    final theme = Theme.of(context);
    final sched = _scheduled;
    final sets = sched?.exercises.fold<int>(0, (n, e) => n + e.targetSets) ?? 0;
    final hasPlan = sched != null && !sched.day.isRestDay;
    final recovery =
        _activeRoutine != null &&
        _planHasDays &&
        (sched == null || sched.day.isRestDay);
    final emptyPlan = _activeRoutine != null && !_planHasDays;
    final startable = hasPlan && sched.exercises.isNotEmpty;
    final now = _now();
    final day = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];
    final month = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][now.month - 1];
    final burnedToday = _summary.burnedTodayKcal ?? 0;
    final kcalLeft = BurnService.remainingKcal(
      target: _summary.kcalTarget,
      eaten: _summary.kcalEaten,
      burned: burnedToday,
      countBurn: _countBurn,
    );
    final burnLabel = SessionLog.formatKcal(burnedToday);
    return NvPage(
      title: 'Today',
      subtitle: '$day, ${now.day} $month',
      actions: [
        NvShapeButton(
          key: const ValueKey('open-settings'),
          icon: Icons.settings_outlined,
          label: 'Settings',
          onPressed:
              widget.onOpenSettings ??
              () => widget.onNavigate?.call('settings'),
        ),
      ],
      children: [
        NvSurface(
          tone: NvTone.primary,
          radius: 36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recovery
                              ? 'Recovery day'
                              : emptyPlan
                              ? 'Build your training week'
                              : hasPlan
                              ? sched.day.name
                              : 'Train on your terms',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recovery
                              ? 'No training is planned today. Give yourself time to recover.'
                              : emptyPlan
                              ? 'Add your first training or rest day to ${_activeRoutine!.name}.'
                              : hasPlan
                              ? '${sched.exercises.length} exercises · $sets sets'
                              : 'Choose a plan or start a custom workout.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NvIconBadge(
                    icon: hasPlan
                        ? Icons.fitness_center_rounded
                        : Icons.self_improvement_rounded,
                    shape: hasPlan
                        ? LockoutShape.flower
                        : LockoutShape.softBurst,
                    size: 72,
                    tone: NvTone.surface,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_sessionActive)
                NvButton(
                  variant: NvButtonVariant.filled,
                  label: 'Resume workout',
                  icon: Icons.play_arrow_rounded,
                  onPressed: resumeSession,
                )
              else if (startable)
                NvButton(
                  variant: NvButtonVariant.filled,
                  label: 'Start workout',
                  large: true,
                  icon: Icons.play_arrow_rounded,
                  onPressed: _startScheduledSession,
                )
              else
                NvButton(
                  variant: NvButtonVariant.filled,
                  label: recovery
                      ? 'View training plan'
                      : emptyPlan
                      ? 'Open plan'
                      : hasPlan
                      ? 'Add exercises'
                      : 'Create routine',
                  icon: Icons.add_rounded,
                  onPressed: () => widget.onNavigate?.call('workout'),
                ),
              const SizedBox(height: 8),
              NvButton(
                key: const ValueKey('start-custom-workout'),
                variant: NvButtonVariant.text,
                label: 'Start a custom workout',
                onPressed: _sessionActive ? resumeSession : _startCustomSession,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.foodTabEnabled) ...[
                Expanded(
                  child: NvActionCard(
                    title: 'Log food',
                    subtitle: kcalLeft == null
                        ? 'Add your first meal'
                        : burnLabel.isEmpty
                        ? '${kcalLeft < 0 ? 0 : kcalLeft} kcal left'
                        : '${kcalLeft < 0 ? 0 : kcalLeft} kcal left · '
                              '$burnLabel burned',
                    icon: Icons.restaurant_rounded,
                    shape: LockoutShape.bun,
                    tone: NvTone.secondary,
                    onPressed: () => widget.onNavigate?.call('food'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: NvActionCard(
                  title: 'Weigh in',
                  subtitle: _summary.weightKg == null
                      ? 'Add a measurement'
                      : DisplayUnits.format(context, _summary.weightKg!),
                  icon: Icons.monitor_weight_outlined,
                  shape: LockoutShape.pentagon,
                  tone: NvTone.tertiary,
                  onPressed: () => widget.onNavigate?.call(
                    'progress',
                    segment: ProgressSegment.weight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const NvHeading('This week'),
        NvSurface(
          child: NvWeekStrip(
            dates: _recentSessions.map((s) => s.dateStr).toSet(),
          ),
        ),
        if (_recentSessions.isNotEmpty) ...[
          const NvHeading('Recent workout'),
          NvListItem(
            leading: const NvIconBadge(icon: Icons.fitness_center_rounded),
            title: _recentSessions.first.dayName,
            supporting: _recentSessions.first.kcalLabel.isEmpty
                ? _recentSessions.first.dateStr
                : '${_recentSessions.first.dateStr} · '
                      '${_recentSessions.first.kcalLabel} burned',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => widget.onNavigate?.call(
              'progress',
              segment: ProgressSegment.history,
            ),
          ),
        ],
        const NvHeading('Explore'),
        NvGroupedList(
          children: [
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.calendar_month_outlined,
                shape: LockoutShape.arch,
              ),
              title: 'Workout history',
              supporting: 'Completed sessions and sets',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => widget.onNavigate?.call(
                'progress',
                segment: ProgressSegment.history,
              ),
            ),
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.view_week_outlined,
                shape: LockoutShape.diamond,
                tone: NvTone.tertiary,
              ),
              title: 'Training plans',
              supporting: 'Your routines and exercise library',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => widget.onNavigate?.call('workout'),
            ),
          ],
        ),
      ],
    );
  }

  // --- ACTIVE SESSION ---

  Widget _buildActiveSession() {
    // Sets, not exercises (QA ruling 1). The bar is painted as the last
    // element of the same card whose 88pt numeral counts sets, and it
    // carries no label, so it inherits that numeral's denominator in the
    // reader's head. Per exercise it also sat at exactly 0.0 for the first
    // third of a workout — least informative when feedback matters most.
    final setProgress = _sessionTotalSets == 0
        ? 0.0
        : _sessionCompletedSets / _sessionTotalSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionHeader(setProgress),
        const SizedBox(height: LockoutTheme.spaceMd),
        Expanded(child: _buildExerciseList()),
      ],
    );
  }

  /// Item 0 is the leg-safety notice, the last item is `Add exercise`, and
  /// everything between is one exercise card (or the empty-state message
  /// when there are none) — kept a `ListView.builder` rather than a plain
  /// `ListView` so a long session does not eagerly build every card and
  /// every set row up front.
  Widget _buildExerciseList() {
    final theme = Theme.of(context);
    final hasExercises = _liveExercises.isNotEmpty;
    final showInlineAdd = !widget.presentSessionAsRoute;
    final itemCount =
        (hasExercises ? _liveExercises.length : 1) + (showInlineAdd ? 2 : 1);
    final lastIndex = itemCount - 1;

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: LockoutTheme.spaceMd),
            child: _buildLegSafetyNotice(),
          );
        }
        if (showInlineAdd && index == lastIndex) {
          return NvButton(
            variant: NvButtonVariant.outlined,
            label: 'Add exercise',
            onPressed: _addExerciseMidSession,
          );
        }
        if (!hasExercises) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: LockoutTheme.spaceLg),
            child: Text(
              'No exercises yet. Add one to begin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        return _buildExerciseCard(_liveExercises[index - 1], index - 1);
      },
    );
  }

  /// The header leads with one big number — the sets still to go — beside a
  /// cookie-shaped register marker, then a Duration / Volume row, a Finish
  /// action, and the set-completion bar. The sets figure is deliberately not
  /// repeated in the stat row: one big number per screen, stated once —
  /// which is also why the bar counts sets rather than exercises and is left
  /// unlabelled, instead of making a second, differently-denominated
  /// progress claim inside one card. See `_FinishSummarySheet` for what
  /// tapping Finish opens.
  Widget _buildSessionHeader(double setProgress) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.presentSessionAsRoute)
              NvShapeButton(
                key: const ValueKey('minimize-workout'),
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Minimize workout',
                onPressed: () => Navigator.of(context).pop(),
              )
            else
              NvShapeButton(
                icon: Icons.close_rounded,
                label: 'Leave session',
                onPressed: _leaveSession,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_sessionTitle, style: theme.textTheme.headlineSmall),
            ),
            PopupMenuButton<String>(
              tooltip: 'Workout options',
              onSelected: (v) {
                if (v == 'discard') _leaveSession();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'discard',
                  child: Text('Discard workout'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Workout in progress · $_elapsedLabel',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        NvSurface(
          tone: NvTone.secondary,
          padding: const EdgeInsets.all(LockoutTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_sessionCompletedSets of $_sessionTotalSets sets · ${DisplayUnits.format(context, _sessionVolumeKg, decimals: 0)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              NvWavyProgress(value: setProgress),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!widget.presentSessionAsRoute)
          NvButton(
            variant: NvButtonVariant.filled,
            label: 'Finish',
            onPressed: _confirmFinishSession,
          ),
      ],
    );
  }

  /// Opens the finish summary — the same Duration/Volume/Sets triple the
  /// header shows, so the numbers the log will carry are confirmed before
  /// the write rather than discovered after it. Save preserves the reviewed
  /// completion time; discard ends the session with no write.
  Future<void> _confirmFinishSession() async {
    if (_confirmingFinish || _sessionSaving) return;
    _confirmingFinish = true;
    final reviewedAt = _now();
    final reviewedDuration = reviewedAt
        .difference(_startedAt ?? reviewedAt)
        .inSeconds;
    final action = await showNvEditor<String>(
      context: context,
      title: 'Finish workout',
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NvIconBadge(
            icon: Icons.check_rounded,
            shape: LockoutShape.achievement,
            size: 88,
          ),
          const SizedBox(height: 24),
          Text('Ready to save?', style: Theme.of(ctx).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Text(_sessionTitle, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 20),
          NvSurface(
            tone: NvTone.secondary,
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _SessionStat(
                  label: 'Duration',
                  value: _clockLabel(reviewedDuration),
                ),
                _SessionStat(label: 'Sets', value: '$_sessionCompletedSets'),
                _SessionStat(
                  label: 'Volume',
                  value: '${_fmtWeight(_sessionVolumeKg)} kg',
                ),
              ],
            ),
          ),
          const NvHeading('Your exercises'),
          NvGroupedList(
            children: [
              for (final ex in _liveExercises.where(
                (e) => e.completedCount > 0,
              ))
                NvListItem(
                  title: ex.name,
                  supporting:
                      '${ex.completedCount} completed ${ex.completedCount == 1 ? 'set' : 'sets'} · ${DisplayUnits.format(context, ex.volumeKg, decimals: 0)}',
                ),
            ],
          ),
          if (_sessionCompletedSets == 0)
            const Text(
              'No sets are complete. Keep training or discard this workout.',
            ),
          const SizedBox(height: 24),
          NvButton(
            key: const ValueKey('save-workout'),
            variant: NvButtonVariant.filled,
            label: 'Save workout',
            onPressed: _sessionCompletedSets == 0
                ? null
                : () => Navigator.of(ctx).pop('save'),
          ),
          const SizedBox(height: 12),
          NvButton(
            variant: NvButtonVariant.tonal,
            label: 'Keep training',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          const SizedBox(height: 12),
          NvButton(
            variant: NvButtonVariant.danger,
            label: 'Discard workout',
            onPressed: () => Navigator.of(ctx).pop('discard'),
          ),
        ],
      ),
    );
    _confirmingFinish = false;
    if (!mounted) return;
    if (action == 'save') await _finishSession(completedAt: reviewedAt);
    if (action == 'discard') await _leaveSession();
  }

  Widget _buildLegSafetyNotice() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // An info card rather than a tinted card of its own: section 8 has one
    // card for advisory content, and the warning is carried by the icon and
    // the semantics layer's `warning` role rather than by a whole surface.
    return NvInfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: LockoutSemantics.of(context).warning,
          ),
          const SizedBox(width: LockoutTheme.spaceSm),
          Expanded(
            child: Text(
              'Pain-free movement only. Use moderate load, avoid forcing '
              'painful reps.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(_LiveExercise ex, int exerciseIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: NvSurface(
        tone: exerciseIndex == 0 ? NvTone.primary : NvTone.surface,
        padding: const EdgeInsets.all(LockoutTheme.headingGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NvIconBadge(
                    icon: Icons.fitness_center_rounded,
                    shape: LockoutShape
                        .values[[11, 8, 14, 6, 9][exerciseIndex % 5]],
                    tone: NvTone.values[(exerciseIndex + 1) % 3],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ex.lastPerformance.isEmpty
                              ? 'Target ${ex.targetLabel}'
                              : 'Last time ${ex.lastPerformance}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  NvShapeButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Watch form',
                    tone: NvTone.secondary,
                    shape: LockoutShape.arch,
                    onPressed: () => _openVideo(ex.name, ex.videoUrl),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < ex.sets.length; i++) ...[
              _buildSetRow(ex, exerciseIndex, i, ex.sets[i]),
              const SizedBox(height: 4),
            ],
            NvButton(
              variant: NvButtonVariant.text,
              label: 'Add set',
              icon: Icons.add_rounded,
              onPressed: () {
                final last = ex.sets.lastOrNull;
                setState(
                  () => ex.sets.add(
                    _LiveSet(
                      weightKg: last?.weightKg ?? 0,
                      reps: last?.reps ?? 10,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    _LiveExercise ex,
    int exerciseIndex,
    int setIndex,
    _LiveSet set,
  ) => NvSetRow(
    key: ObjectKey(set),
    index: setIndex + 1,
    weight: set.weightKg,
    reps: set.reps,
    completed: set.completed,
    completionKey: ValueKey('set-complete-$exerciseIndex-$setIndex'),
    onWeight: (v) {
      if (set.weightKg != v) setState(() => set.weightKg = v);
    },
    onReps: (v) {
      if (set.reps != v) setState(() => set.reps = v);
    },
    onDelete: ex.sets.length > 1
        ? () => setState(() => ex.sets.removeAt(setIndex))
        : null,
    onToggle: () {
      final wasDone = set.completed;
      setState(() => set.completed = !wasDone);
      if (!wasDone) _beginRest(ex.restSeconds);
    },
  );

  String get _restLabel =>
      '${(_restSeconds ~/ 60).toString().padLeft(2, '0')}:${(_restSeconds % 60).toString().padLeft(2, '0')}';

  void _adjustRest(int delta) {
    final end = _restEndsAt;
    if (end == null) return;
    setState(() {
      final before = _restSeconds;
      _restEndsAt = delta < 0 && before <= -delta
          ? _now()
          : end.add(Duration(seconds: delta));
      _syncRest();
      final total = delta > 0
          ? _restTotalSeconds + delta
          : _restTotalSeconds - (before - _restSeconds);
      _restTotalSeconds = total < 0 ? 0 : total;
    });
  }

  void _skipRest() => setState(() {
    _restRunning = false;
    _restSeconds = 0;
    _restEndsAt = null;
  });

  Future<void> _openRestTimer() async {
    if (_restSheetOpen || !_restRunning || !mounted) return;
    _restSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: _sessionRevision,
        builder: (_, revision, child) {
          final next = _liveExercises
              .where((e) => e.completedCount < e.sets.length)
              .firstOrNull;
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _restRunning ? 'Rest time' : 'Rest complete',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: NvIconBadge(
                      icon: Icons.timer_outlined,
                      shape: LockoutShape.sunny,
                      size: 88,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _restLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    next == null
                        ? 'All planned sets complete'
                        : 'Next: ${next.name}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      NvButton(
                        variant: NvButtonVariant.tonal,
                        label: '−15 sec',
                        onPressed: _restRunning ? () => _adjustRest(-15) : null,
                      ),
                      NvButton(
                        variant: NvButtonVariant.tonal,
                        label: '+15 sec',
                        onPressed: _restRunning ? () => _adjustRest(15) : null,
                      ),
                      NvButton(
                        variant: NvButtonVariant.filled,
                        label: _restRunning ? 'Skip rest' : 'Keep training',
                        onPressed: () {
                          _skipRest();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    _restSheetOpen = false;
  }

  Widget _workoutActions() {
    final buttons = [
      NvButton(
        variant: NvButtonVariant.tonal,
        label: 'Add exercise',
        onPressed: _addExerciseMidSession,
      ),
      NvButton(
        variant: NvButtonVariant.filled,
        label: _sessionSaving ? 'Saving…' : 'Finish workout',
        onPressed: _sessionSaving ? null : _confirmFinishSession,
      ),
    ];
    return MediaQuery.textScalerOf(context).scale(16) > 20
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[0], const SizedBox(height: 8), buttons[1]],
          )
        : Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 12),
              Expanded(child: buttons[1]),
            ],
          );
  }

  Widget _buildRestBar() {
    final progress = _restTotalSeconds <= 0
        ? 0.0
        : (_restSeconds / _restTotalSeconds).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NvSurface(
        tone: NvTone.secondary,
        padding: const EdgeInsets.all(LockoutTheme.headingGap),
        onPressed: _openRestTimer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const NvIconBadge(
                  icon: Icons.timer_outlined,
                  shape: LockoutShape.sunny,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rest · $_restLabel',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up_rounded),
              ],
            ),
            const SizedBox(height: 8),
            NvWavyProgress(value: progress),
          ],
        ),
      ),
    );
  }
}

/// The Finish confirmation sheet: the same Duration/Volume/Sets triple the
/// session header states, plus the two ways to end the session. Pops with
/// `'save'` or `'discard'` for `_confirmFinishSession` to act on.
class _SessionStat extends StatelessWidget {
  final String label;
  final String value;

  const _SessionStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: LockoutTheme.spaceXs),
        // `maxLines: 1` + ellipsis rather than letting it soft-wrap: a
        // four-digit volume (a routine mid-session figure, e.g. "1234.5 kg")
        // otherwise wraps to a second line at ~390dp and still overflows its
        // `Expanded` column, which clips silently with no exception and no
        // ellipsis. Ellipsis makes that truncation visible instead of mute.
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LockoutTheme.numeric(context, size: 20),
        ),
      ],
    );
  }
}


/// "Your workout burned ~N kcal" with a way to correct it, after the Cal AI
/// burned-calories screen. The estimate is only as good as its inputs, so the
/// user can overwrite it; the correction is stored on this session alone.
class _SavedBurnCard extends StatefulWidget {
  final String sessionId;
  final double initialKcal;
  final Future<void> Function() onChanged;

  const _SavedBurnCard({
    required this.sessionId,
    required this.initialKcal,
    required this.onChanged,
  });

  @override
  State<_SavedBurnCard> createState() => _SavedBurnCardState();
}

class _SavedBurnCardState extends State<_SavedBurnCard> {
  late double _kcal = widget.initialKcal;

  Future<void> _edit() async {
    final value = await showNvSheet<double>(
      context: context,
      title: 'Workout burn',
      child: _BurnForm(initialKcal: _kcal),
    );
    if (value == null || !mounted) return;
    try {
      await DatabaseService.instance.updateSessionBurn(widget.sessionId, value);
    } catch (_) {
      if (mounted) {
        showNvSnackbar(context: context, message: 'Burn not saved. Try again.');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _kcal = value);
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = SessionLog.formatKcal(_kcal);
    return NvSurface(
      tone: NvTone.tertiary,
      child: Row(
        children: [
          const NvIconBadge(
            icon: Icons.local_fire_department_rounded,
            shape: LockoutShape.verySunny,
            tone: NvTone.surface,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your workout burned', style: theme.textTheme.titleMedium),
                Text(
                  label.isEmpty ? 'No estimate yet' : label,
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          NvShapeButton(
            key: const ValueKey('edit-burn'),
            icon: Icons.edit_outlined,
            label: 'Edit burn',
            onPressed: _edit,
          ),
        ],
      ),
    );
  }
}

/// Owns its controller so the field is disposed with the sheet.
class _BurnForm extends StatefulWidget {
  const _BurnForm({required this.initialKcal});

  final double initialKcal;

  @override
  State<_BurnForm> createState() => _BurnFormState();
}

class _BurnFormState extends State<_BurnForm> {
  late final _ctrl = TextEditingController(
    text: widget.initialKcal > 0 ? widget.initialKcal.round().toString() : '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvField(
          label: 'Calories burned (kcal)',
          controller: _ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        NvButton(
          key: const ValueKey('save-burn'),
          variant: NvButtonVariant.filled,
          label: 'Save burn',
          onPressed: () {
            final parsed = NumericGuard.parse(_ctrl.text, min: 0);
            if (parsed == null || parsed > 5000) {
              showNvSnackbar(
                context: context,
                message: 'Enter a number from 0 to 5000.',
              );
              return;
            }
            Navigator.of(context).pop(parsed);
          },
        ),
      ],
    );
  }
}
