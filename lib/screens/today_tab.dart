import 'dart:async';
import 'package:flutter/material.dart';

import 'progress_tab.dart' show ProgressSegment;
import '../theme/cookie_border.dart';
import '../theme/lockout_motion.dart';
import '../theme/lockout_semantics.dart';
import '../theme/lockout_theme.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/energy_estimator.dart';
import '../services/goal_service.dart';
import '../services/numeric_guard.dart';
import '../services/schedule_service.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_cards.dart';
import '../widgets/house/nv_empty_state.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_hero_card.dart';
import '../widgets/house/nv_icon_tile.dart';
import '../widgets/lockout_card.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/sparkline.dart';
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

  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  TodayTab({
    super.key,
    this.onNavigate,
    this.foodTabEnabled = true,
  });

  @override
  State<TodayTab> createState() => TodayTabState();
}

class TodayTabState extends State<TodayTab> {
  ScheduledDay? _scheduled;
  bool _isLoading = true;

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
  int _restSeconds = 0;
  // The rest duration `_beginRest` was called with, kept only so
  // `_buildRestBar` can paint a remaining-time progress bar; the countdown
  // itself is still driven solely by `_restSeconds`/`_restRunning` below.
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
    super.dispose();
  }

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
    if (!mounted) return;
    setState(() => _scheduled = resolved);
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
    // Null means "no session logged today" — the honest NO SESSION YET case.
    // A session that *was* logged but couldn't be estimated (no bodyweight
    // on record) sums to 0.0, which is a real, different state: the row
    // must not claim there was no session at all. See `HomeHub._burnValue`.
    final burnedToday = sessionRows.isEmpty
        ? null
        : sessionRows.fold<double>(
            0.0,
            (sum, r) => sum + (NumericGuard.read(r['kcal_burned']) ?? 0.0),
          );

    if (!mounted) return;
    setState(() {
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

  Future<void> _startScheduledSession() async {
    final sched = _scheduled;
    if (sched == null) return;

    final live = <_LiveExercise>[];
    for (final ex in sched.exercises) {
      live.add(_LiveExercise(
        exerciseId: ex.id,
        name: ex.name,
        videoUrl: ex.videoUrl,
        restSeconds: ex.restDefaultS,
        targetLabel: ex.targetLabel,
        sets: List.generate(
          ex.targetSets,
          (_) => _LiveSet(weightKg: ex.targetWeightKg, reps: ex.targetRepsMax),
        ),
      ));
    }

    await _beginSession('${sched.day.tag} - ${sched.day.name}', live);
  }

  Future<void> _startCustomSession() async {
    await _beginSession('Custom Session', []);
  }

  Future<void> _beginSession(String title, List<_LiveExercise> exercises) async {
    for (final e in exercises) {
      e.lastPerformance = await _fetchLastPerformance(e.name);
    }
    if (!mounted) return;

    setState(() {
      _sessionActive = true;
      _sessionTitle = title;
      _liveExercises = exercises;
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
      _restSeconds = 0;
      _restTotalSeconds = 0;
      _restRunning = false;
    });
    _startTicker();
  }

  Future<String> _fetchLastPerformance(String exerciseName) async {
    final rows = await DatabaseService.instance.getLastPerformance(exerciseName);
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
          _elapsedSeconds = DateTime.now().difference(_startedAt!).inSeconds;
        }
        if (_restRunning) {
          if (_restSeconds > 0) {
            _restSeconds--;
          } else {
            _restRunning = false;
          }
        }
      });
    });
  }

  void _beginRest(int seconds) {
    setState(() {
      _restSeconds = seconds;
      _restTotalSeconds = seconds;
      _restRunning = true;
    });
  }

  double get _sessionVolumeKg =>
      _liveExercises.fold(0.0, (sum, e) => sum + e.volumeKg);

  int get _sessionCompletedSets =>
      _liveExercises.fold(0, (sum, e) => sum + e.completedCount);

  int get _sessionTotalSets =>
      _liveExercises.fold(0, (sum, e) => sum + e.sets.length);

  String get _elapsedLabel {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
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

  Future<void> _finishSession() async {
    if (_sessionCompletedSets == 0) {
      final discard = await _confirmDiscard();
      if (discard != true) return;
      _endSessionState();
      return;
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final started = _startedAt ?? DateTime.now();
    final duration = DateTime.now().difference(started).inSeconds;
    final sched = _scheduled;

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
    final bodyweightKg = snapshot.currentWeightKg ??
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
      dateStr: ScheduleService.dateKey(DateTime.now()),
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
    await DatabaseService.instance
        .insertSessionWithSets(session.toMap(), setRows);

    if (!mounted) return;
    // Refresh BURNED TODAY (and the rest of the summary) so the hub the user
    // lands back on reflects the session just saved, rather than reporting
    // "not on record" about data that was just recorded.
    await _loadSummary();
    if (!mounted) return;
    _endSessionState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Session saved — ${setRows.length} sets, ${_fmtWeight(session.totalVolumeKg)} kg volume',
        ),
      ),
    );
  }

  Future<bool?> _confirmDiscard() {
    final semantics = LockoutSemantics.of(context);
    return showDialog<bool>(
      context: context,
      // No `backgroundColor`/`shape` here — `LockoutTheme.build`'s
      // `dialogTheme` already supplies both.
      builder: (ctx) => AlertDialog(
        title: const Text('Discard session?'),
        content: Text(
          _sessionCompletedSets > 0
              ? '$_sessionCompletedSets logged '
                  '${_sessionCompletedSets == 1 ? 'set' : 'sets'} will be '
                  'lost. Discard ${_sessionCompletedSets == 1 ? 'it' : 'them'}?'
              : 'No sets were logged, so there is nothing to archive. End the session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            // `semantics.danger`, not `colorScheme.error` — this is a
            // destructive confirmation, exactly what that role is reserved
            // for (see `LockoutSemantics`'s doc on `danger` vs `error`, and
            // `log_tab.dart`'s DELETE ENTRY for the same rule).
            style: TextButton.styleFrom(foregroundColor: semantics.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _endSessionState() {
    _ticker?.cancel();
    setState(() {
      _sessionActive = false;
      _liveExercises = [];
      _startedAt = null;
      _restRunning = false;
      _restSeconds = 0;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // SafeArea(bottom: false): MainScreen dropped its global AppBar in the
      // five-tab restructure, so each tab now owns its top inset. Without
      // this the header paints under the status bar on an edge-to-edge
      // window and swallows taps. Bottom is left alone — BottomNav carries
      // its own inset, and this tab's content should scroll under it.
      body: SafeArea(
        bottom: false,
        child: _sessionActive
            ? Padding(
                padding: const EdgeInsets.all(LockoutTheme.screenPadding),
                child: _buildActiveSession(),
              )
            : _buildPreSession(context),
      ),
      // Kept visible while the exercise list scrolls, rather than inline in
      // the body. This is TodayTab's own Scaffold (nested inside MainScreen's
      // IndexedStack), so it does not compete with MainScreen's BottomNav.
      bottomNavigationBar:
          (_sessionActive && _restRunning) ? _buildRestBar() : null,
    );
  }

  // --- PRE-SESSION (Today's landing surface) ---
  //
  // Rebuilt from the house component catalog rather than adapted from
  // `HomeHub`. The hub was written for the previous design, and adapting it
  // kept that design's decisions — a stack of uniform cards, an all-caps
  // caption, a neutral hero — in places no token could reach.

  /// One tile in the quick-action grid.
  ///
  /// Local to this screen rather than `ActionItem` from `action_grid.dart`:
  /// a rebuilt screen composes from `lib/widgets/house/` and the theme only.
  Widget _quickActionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NvIconTile(icon: icon, color: color, label: label, onTap: onTap);
  }

  Widget _buildPreSession(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = LockoutSemantics.of(context);
    final sched = _scheduled;
    final code = ScheduleService.weekdayCode(DateTime.now());
    final isRest = sched == null;
    // A day can be scheduled with no exercises on it yet (routine still
    // being built). That is not a rest day, but it also has nothing to
    // start live — offer guidance to the Routines tab instead of a session
    // that would open with zero exercises.
    final isEmptyDay = sched != null && sched.exercises.isEmpty;
    final setCount =
        sched?.exercises.fold<int>(0, (sum, e) => sum + e.targetSets) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: LockoutTheme.scrollBottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 7.1: a tab screen starts with a large title, not a top
          // app bar.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LockoutTheme.screenPadding,
              LockoutTheme.screenPadding,
              LockoutTheme.screenPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRest ? 'Rest day' : sched.day.name,
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: LockoutTheme.spaceXs),
                Text(
                  'Today · $code',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LockoutTheme.headingGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: NvHeroCard(
              title: isRest ? 'Nothing scheduled' : sched.day.name,
              value: '$setCount',
              unit: setCount == 1 ? 'set' : 'sets',
              // The one subject-scale element on this screen, and the only
              // place a lobed shape belongs: the lobe count is the register,
              // 4 for rest and 6 for training.
              marker: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: isRest ? CookieBorder.rest : CookieBorder.training,
                  color: semantics.categoryAt(isRest ? 7 : 0),
                ),
                child: const SizedBox(width: 56, height: 56),
              ),
              actions: [
                if (!isRest && !isEmptyDay)
                  NvButton(
                    variant: NvButtonVariant.accent,
                    label: 'Start session',
                    onPressed: _startScheduledSession,
                  ),
                NvButton(
                  variant: NvButtonVariant.tonal,
                  label: 'Custom session',
                  onPressed: _startCustomSession,
                ),
              ],
            ),
          ),
          const SizedBox(height: LockoutTheme.sectionGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: _buildDayBody(context, sched, isRest: isRest),
          ),
          const SizedBox(height: LockoutTheme.sectionGap),
          _buildSectionHeading(context, "Today's numbers"),
          const SizedBox(height: LockoutTheme.headingGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: NvGroupedList(children: _summaryRows(context)),
          ),
          const SizedBox(height: LockoutTheme.sectionGap),
          _buildSectionHeading(context, 'Quick actions'),
          const SizedBox(height: LockoutTheme.headingGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LockoutTheme.cardPadding,
            ),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: _quickActions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LockoutTheme.screenPadding,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  /// The day's own block: the exercise list, or the honest empty case.
  Widget _buildDayBody(
    BuildContext context,
    ScheduledDay? sched, {
    required bool isRest,
  }) {
    if (isRest) {
      return NvEmptyState(
        headline: 'No session today',
        body: 'Nothing is scheduled. Train off-plan or take the day.',
        actionLabel: 'Start a custom session',
        onAction: _startCustomSession,
      );
    }

    if (sched!.exercises.isEmpty) {
      return const NvTbaCard(
        message: 'This training day has no exercises yet. Add them on the '
            'Routines tab, then come back to start the session.',
      );
    }

    return NvGroupedList(
      children: [
        for (final exercise in sched.exercises)
          NvListItem(
            title: exercise.name,
            supporting: '${exercise.targetSets} '
                '${exercise.targetSets == 1 ? 'set' : 'sets'}',
          ),
      ],
    );
  }

  /// What the hub's weight and nutrition cards used to say, as grouped-list
  /// rows.
  ///
  /// The composition changed; the information did not. A null still means
  /// "not on record" and renders a prompt rather than a zero.
  List<Widget> _summaryRows(BuildContext context) {
    final semantics = LockoutSemantics.of(context);
    final rows = <Widget>[];

    final series = _summary.weightSeries;
    rows.add(
      NvListItem(
        title: 'Weight',
        supporting: _weightSupporting(),
        // Fewer than two points cannot make a line, and a flat stub would
        // read as a trend that is not there.
        trailing: series.length >= 2
            ? SizedBox(
                width: 72,
                child: Sparkline(
                  values: series,
                  lineColor: semantics.chartLine,
                  height: 28,
                ),
              )
            : null,
        onTap: () => widget.onNavigate?.call(
          'progress',
          segment: ProgressSegment.weight,
        ),
      ),
    );

    if (widget.foodTabEnabled) {
      rows.add(
        NvListItem(
          title: 'Calories',
          supporting: _caloriesSupporting(),
          onTap: () => widget.onNavigate?.call('food'),
        ),
      );
      rows.add(
        NvListItem(
          title: 'Protein',
          supporting: _proteinSupporting(),
          onTap: () => widget.onNavigate?.call('food'),
        ),
      );
    }

    rows.add(
      NvListItem(
        title: 'Burned today',
        supporting: _burnSupporting(),
        onTap: () => widget.onNavigate?.call(
          'progress',
          segment: ProgressSegment.history,
        ),
      ),
    );

    return rows;
  }

  String _weightSupporting() {
    final weight = _summary.weightKg;
    if (weight == null) return 'No weight on record yet';

    final parts = <String>['${weight.toStringAsFixed(1)} kg'];

    final delta = _summary.weightDeltaKg;
    if (delta != null && delta != 0) {
      final sign = delta > 0 ? '+' : '-';
      parts.add('$sign${delta.abs().toStringAsFixed(1)} kg');
    }

    final target = _summary.targetWeightKg;
    if (target != null) {
      final gap = (weight - target).abs();
      parts.add(
        gap < 0.05
            ? 'target reached'
            : '${gap.toStringAsFixed(1)} kg to go',
      );
    }

    return parts.join(' · ');
  }

  String _caloriesSupporting() {
    final target = _summary.kcalTarget;
    if (target == null) return '${_summary.kcalEaten} kcal · no target set';

    final left = target - _summary.kcalEaten;
    // Never a negative "left": past the target it reads as over, which is
    // the arithmetic a reader can do in their head.
    final tail = left >= 0 ? '$left kcal left' : '${left.abs()} kcal over';
    return '${_summary.kcalEaten} of $target kcal · $tail';
  }

  String _proteinSupporting() {
    final eaten = _summary.proteinEatenG.round();
    final target = _summary.proteinTargetG;
    if (target == null) return '$eaten g';

    final left = target - eaten;
    final tail = left >= 0 ? '$left g left' : '${left.abs()} g over';
    return '$eaten of $target g · $tail';
  }

  String _burnSupporting() {
    final burned = _summary.burnedTodayKcal;
    // Null means no session was logged today at all. A value of zero or less
    // means a session *was* logged but no estimate could be made for it, and
    // saying "no session yet" there would deny something that happened.
    if (burned == null) return 'No session logged yet';
    if (burned <= 0) return 'Estimate unavailable';
    return '${burned.round()} kcal';
  }

  List<Widget> _quickActions(BuildContext context) {
    final go = widget.onNavigate;
    final semantics = LockoutSemantics.of(context);

    return [
      // Hidden entirely when the Food tab is off, rather than left as a tile
      // that taps to nowhere: `_goToTab` already no-ops for a hidden tab id,
      // so a visible "Log food" tile would silently do nothing.
      if (widget.foodTabEnabled)
        _quickActionTile(
          label: 'Log food',
          icon: Icons.restaurant,
          color: semantics.categoryAt(0),
          onTap: () => go?.call('food'),
        ),
      _quickActionTile(
        label: 'Weigh in',
        icon: Icons.monitor_weight,
        color: semantics.categoryAt(1),
        onTap: () => go?.call('progress', segment: ProgressSegment.weight),
      ),
      _quickActionTile(
        label: 'Workout',
        icon: Icons.fitness_center,
        color: semantics.categoryAt(2),
        onTap: () => go?.call('workout'),
      ),
      _quickActionTile(
        label: 'History',
        icon: Icons.calendar_month,
        color: semantics.categoryAt(3),
        onTap: () => go?.call('progress', segment: ProgressSegment.history),
      ),
      _quickActionTile(
        label: 'Custom',
        icon: Icons.add,
        color: semantics.categoryAt(4),
        onTap: _startCustomSession,
      ),
      _quickActionTile(
        label: 'Streak',
        icon: Icons.local_fire_department,
        color: semantics.categoryAt(5),
        onTap: () => go?.call('progress', segment: ProgressSegment.history),
      ),
      _quickActionTile(
        label: 'Plan',
        icon: Icons.insights,
        color: semantics.categoryAt(6),
        onTap: () => go?.call('progress', segment: ProgressSegment.weight),
      ),
      _quickActionTile(
        label: 'Exercises',
        icon: Icons.list,
        color: semantics.categoryAt(7),
        onTap: () => go?.call('workout'),
      ),
    ];
  }


  // --- ACTIVE SESSION ---

  Widget _buildActiveSession() {
    final totalExercises = _liveExercises.length;
    final completedExercises = totalExercises == 0
        ? 0
        : _liveExercises
            .where((e) => e.sets.isNotEmpty && e.completedCount == e.sets.length)
            .length;
    final exerciseProgress =
        totalExercises == 0 ? 0.0 : completedExercises / totalExercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionHeader(exerciseProgress),
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
    final itemCount = (hasExercises ? _liveExercises.length : 1) + 2;
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
        if (index == lastIndex) {
          // Plain text, not `.icon` — an `Icons.add` glyph here would sit
          // alongside the weight/rep stepper's own plus buttons and get
          // swept into any test that walks every `Icons.add` on screen
          // expecting a stepper.
          return OutlinedButton(
            onPressed: _addExerciseMidSession,
            child: const Text('Add exercise'),
          );
        }
        if (!hasExercises) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: LockoutTheme.spaceLg,
            ),
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
  /// lobed register marker, then a Duration / Volume row, a Finish action,
  /// and the exercise-completion bar. The sets figure is deliberately not
  /// repeated in the stat row: one big number per screen, stated once. See
  /// `_FinishSummarySheet` for what tapping Finish opens.
  Widget _buildSessionHeader(double exerciseProgress) {
    final theme = Theme.of(context);
    return LockoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v1's `HeroCard` stated "IN SESSION - $_sessionTitle" so a live
          // session always named which day was running; the rebuilt header
          // otherwise never paints `_sessionTitle` anywhere on screen.
          Text(
            _sessionTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LockoutTheme.spaceXs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The lobed marker reads as register: 6 lobes while a session
              // is running, 4 when the day is rest. It is a subject-scale
              // element, which is the only place a lobed shape is allowed.
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: _sessionTotalSets > 0
                      ? CookieBorder.training
                      : CookieBorder.rest,
                ),
                child: Icon(
                  _sessionTotalSets > 0
                      ? Icons.bolt_outlined
                      : Icons.bedtime_outlined,
                  size: 22,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: LockoutTheme.spaceMd),
              Text(
                '${_sessionTotalSets - _sessionCompletedSets}',
                style: LockoutTheme.countdown(theme.colorScheme),
              ),
              const SizedBox(width: LockoutTheme.spaceSm),
              // Flexible, not a bare Padding: at 360dp the marker, the 88pt
              // numeral and their gaps leave the label about 136dp, and a
              // wide-metric face spills past that. It wraps rather than
              // overflowing the header.
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _sessionTotalSets - _sessionCompletedSets == 1
                        ? 'set left'
                        : 'sets left',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LockoutTheme.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _SessionStat(label: 'Duration', value: _elapsedLabel),
              ),
              Expanded(
                child: _SessionStat(
                  // The unit lives in the label, not the value: at 360dp
                  // the three stats share ~69dp each once the `Finish`
                  // button takes its own ~88dp, and a four-digit
                  // `1234.5 kg` needs ~110dp at `numeric(size: 20)` — it
                  // ellipsises long before the figure itself would.
                  // Dropping " kg" from the value buys back exactly the
                  // width the unit cost.
                  label: 'Volume (kg)',
                  value: _fmtWeight(_sessionVolumeKg),
                ),
              ),
              FilledButton.tonal(
                onPressed: _confirmFinishSession,
                child: const Text('Finish'),
              ),
            ],
          ),
          const SizedBox(height: LockoutTheme.spaceMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(LockoutTheme.radiusPill),
            child: LinearProgressIndicator(value: exerciseProgress),
          ),
        ],
      ),
    );
  }

  /// Opens the finish summary — the same Duration/Volume/Sets triple the
  /// header shows, so the numbers the log will carry are confirmed before
  /// the write rather than discovered after it. `Save` calls the existing
  /// `_finishSession` unchanged; `Discard` ends the session with no write.
  Future<void> _confirmFinishSession() async {
    final action = await showLockoutSheet<String>(
      context: context,
      title: 'Finish session',
      builder: (_) => _FinishSummarySheet(
        duration: _elapsedLabel,
        volume: _fmtWeight(_sessionVolumeKg),
        sets: '$_sessionCompletedSets/$_sessionTotalSets',
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'save') {
      await _finishSession();
    } else if (action == 'discard') {
      // A session with logged sets is real data, not an empty draft — the
      // same "Discard session?" gate `_finishSession` already applies when
      // there is nothing logged must also guard the one-tap Discard here
      // once there is something to lose.
      if (_sessionCompletedSets > 0) {
        final confirmed = await _confirmDiscard();
        if (confirmed != true || !mounted) return;
      }
      _endSessionState();
    }
  }

  Widget _buildLegSafetyNotice() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LockoutCard(
      color: colors.tertiaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: colors.onTertiaryContainer),
          const SizedBox(width: LockoutTheme.spaceSm),
          Expanded(
            child: Text(
              'Pain-free movement only. Use moderate load, avoid forcing '
              'painful reps.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(_LiveExercise ex, int exerciseIndex) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: LockoutTheme.spaceMd),
      child: LockoutCard(
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
                      Text(ex.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: LockoutTheme.spaceXs),
                      Text(
                        'Target ${ex.targetLabel}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: LockoutTheme.spaceXs),
                      Text(
                        ex.lastPerformance.isEmpty
                            ? 'No previous data'
                            : 'Last ${ex.lastPerformance}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Watch video',
                  onPressed: () => _openVideo(ex.name, ex.videoUrl),
                  icon: const Icon(Icons.play_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: LockoutTheme.spaceSm),
            for (var i = 0; i < ex.sets.length; i++)
              _buildSetRow(ex, exerciseIndex, i, ex.sets[i]),
            Align(
              alignment: Alignment.centerLeft,
              // Plain text, not `.icon` — see the "Add exercise" button above
              // for why an `Icons.add` glyph does not belong here either.
              child: TextButton(
                onPressed: () {
                  final last = ex.sets.isNotEmpty ? ex.sets.last : null;
                  setState(() => ex.sets.add(_LiveSet(
                        weightKg: last?.weightKg ?? 0,
                        reps: last?.reps ?? 10,
                      )));
                },
                child: const Text('Add set'),
              ),
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
  ) {
    final theme = Theme.of(context);
    final semantics = LockoutSemantics.of(context);
    // Two lines, not one: SET + PREVIOUS + delete + the complete tick on top,
    // the two steppers beneath. A single `Row` carrying all of it needs
    // ~332dp of non-shrinkable children (set number, both steppers, the
    // filled complete button) before the row's own padding, which overflows
    // a 360-390dp phone.
    //
    // The tick lives on the *first* line rather than sitting beside the
    // steppers: that line only otherwise carries a 24dp set number and a
    // 48dp delete button, with an ellipsised label taking whatever is left,
    // so a fifth 48dp control fits it without pressure. That leaves the
    // second line for the two steppers alone — each `Expanded` half gets
    // ~140dp at 360dp width. Putting the tick beside the steppers instead
    // (the previous layout) left the value only ~20dp of that, forcing
    // `FittedBox` to shrink a multi-digit weight far below the reps column's
    // single digit — the two columns visibly changed scale against each
    // other, which is what `LockoutTheme.numeric` exists to prevent.
    // `_numberStepper` below caps the value's slot at an explicit width
    // rather than letting it silently take whatever the ~140dp has left
    // over from the steppers' buttons, so the value's scale stops
    // depending on incidental neighbour layout — see its own comment.
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LockoutTheme.spaceSm,
        vertical: LockoutTheme.spaceXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: LockoutTheme.spaceLg,
                child: Text(
                  '${setIndex + 1}',
                  style: LockoutTheme.numeric(context, size: 14),
                ),
              ),
              Expanded(
                child: Text(
                  ex.lastPerformance.isEmpty ? '-' : ex.lastPerformance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              IconButton(
                tooltip: 'Remove set',
                icon: const Icon(Icons.close),
                onPressed: ex.sets.length > 1
                    ? () => setState(() => ex.sets.removeAt(setIndex))
                    : null,
              ),
              IconButton.filled(
                key: ValueKey('set-complete-$exerciseIndex-$setIndex'),
                tooltip: set.completed
                    ? 'Mark set incomplete'
                    : 'Mark set complete',
                style: IconButton.styleFrom(
                  backgroundColor: set.completed
                      ? semantics.success
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: set.completed
                      ? semantics.onSuccess
                      : theme.colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.check),
                onPressed: () {
                  final wasDone = set.completed;
                  setState(() => set.completed = !wasDone);
                  if (!wasDone) _beginRest(ex.restSeconds);
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _numberStepper(
                  label: 'weight',
                  value: _fmtWeight(set.weightKg),
                  onMinus: () {
                    if (set.weightKg >= 2.5) {
                      setState(() => set.weightKg -= 2.5);
                    } else if (set.weightKg > 0) {
                      setState(() => set.weightKg = 0);
                    }
                  },
                  onPlus: () => setState(() => set.weightKg += 2.5),
                ),
              ),
              Expanded(
                child: _numberStepper(
                  label: 'reps',
                  value: '${set.reps}',
                  onMinus: () {
                    if (set.reps > 1) setState(() => set.reps--);
                  },
                  onPlus: () => setState(() => set.reps++),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // A completed row tints its whole background, not just the tick — a
    // TweenAnimationBuilder rather than a plain DecoratedBox so the tint
    // fades in instead of snapping, while the keyed widget the tests read
    // stays a real `DecoratedBox`.
    //
    // `effects` is the tier for colour and opacity: 200ms on an ease-out,
    // with none of the spring tiers' overshoot, since a colour that passes
    // its target lands on a hue nobody authored. Taken through
    // `durationFor` so the fade collapses to nothing when the user has
    // asked the OS to remove animations.
    final targetColor = set.completed
        ? semantics.success.withValues(alpha: 0.12)
        : Colors.transparent;
    return TweenAnimationBuilder<Color?>(
      key: ObjectKey(set),
      tween: ColorTween(end: targetColor),
      duration: LockoutMotion.effects.durationFor(context),
      curve: LockoutMotion.effects.curve,
      builder: (context, color, child) => DecoratedBox(
        key: ValueKey('set-row-$exerciseIndex-$setIndex'),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
        ),
        child: child,
      ),
      child: rowContent,
    );
  }

  Widget _numberStepper({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    const constraints = BoxConstraints(
      minWidth: LockoutTheme.minTouchTarget,
      minHeight: LockoutTheme.minTouchTarget,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Decrease $label',
          icon: const Icon(Icons.remove),
          constraints: constraints,
          onPressed: onMinus,
        ),
        // `Flexible` still, so this can never overflow its Row regardless
        // of what else shares the line — but capped with an explicit
        // `maxWidth` rather than left to take "whatever is left": the
        // previous uncapped `Flexible` grew or shrank with viewport *and*
        // sibling layout together, so it could match the reps column's
        // scale by coincidence at one combination and diverge from it at
        // the next (round-2 finding B). `LockoutTheme.spaceXl + spaceMd`
        // (48dp) is the budget: each stepper's own two 48dp buttons leave
        // ~44dp of its ~140dp `Expanded` half at 360dp width (140 - 96 =
        // 44), and a five-character value at `numeric(size: 14)` needs
        // ~43dp at the default text scale, so 48dp fits it at 1.0 scale
        // with a small margin rather than forcing `FittedBox` to shrink it
        // below the reps column's scale. It still shrinks below 48dp if a
        // neighbour (e.g. the complete tick, wrongly sharing this line)
        // leaves less room than that — capping the budget states the
        // assumption; it does not remove the squeeze.
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LockoutTheme.spaceXl + LockoutTheme.spaceMd,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: LockoutTheme.numeric(context, size: 14),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Increase $label',
          icon: const Icon(Icons.add),
          constraints: constraints,
          onPressed: onPlus,
        ),
      ],
    );
  }

  Widget _buildRestBar() {
    final theme = Theme.of(context);
    final progress = _restTotalSeconds <= 0
        ? 0.0
        : (_restSeconds / _restTotalSeconds).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LockoutTheme.spaceMd,
            LockoutTheme.spaceSm,
            LockoutTheme.spaceMd,
            LockoutTheme.spaceSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(LockoutTheme.radiusPill),
                child: LinearProgressIndicator(value: progress),
              ),
              const SizedBox(height: LockoutTheme.spaceSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_restSeconds}s',
                    style: LockoutTheme.numeric(context, size: 28),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          // `_restTotalSeconds` is the progress bar's
                          // denominator, so it has to shrink by the same
                          // amount `_restSeconds` does — otherwise the bar
                          // reads a stale, too-large total. And when this
                          // adjustment reaches zero, `_restRunning` clears
                          // immediately rather than waiting up to a second
                          // for the next ticker frame to notice.
                          final next =
                              _restSeconds > 15 ? _restSeconds - 15 : 0;
                          final spent = _restSeconds - next;
                          final remainingTotal = _restTotalSeconds - spent;
                          _restTotalSeconds =
                              remainingTotal < 0 ? 0 : remainingTotal;
                          _restSeconds = next;
                          if (_restSeconds == 0) _restRunning = false;
                        }),
                        child: const Text('-15s'),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          // Symmetric with the total above: extending the
                          // rest also extends what "full" means for the bar,
                          // or +15s would pin it at 100% until the clock
                          // fell back under the original total.
                          _restSeconds += 15;
                          _restTotalSeconds += 15;
                        }),
                        child: const Text('+15s'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _restRunning = false),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Finish confirmation sheet: the same Duration/Volume/Sets triple the
/// session header states, plus the two ways to end the session. Pops with
/// `'save'` or `'discard'` for `_confirmFinishSession` to act on.
class _FinishSummarySheet extends StatelessWidget {
  final String duration;
  final String volume;
  final String sets;

  const _FinishSummarySheet({
    required this.duration,
    required this.volume,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SessionStat(label: 'Duration', value: duration)),
            Expanded(
              child: _SessionStat(label: 'Volume (kg)', value: volume),
            ),
            Expanded(child: _SessionStat(label: 'Sets', value: sets)),
          ],
        ),
        const SizedBox(height: LockoutTheme.spaceLg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, 'discard'),
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: LockoutTheme.spaceMd),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The Duration/Volume/Sets caption-over-value pairing shared by the session
/// header (`_buildSessionHeader`) and the finish summary sheet
/// (`_FinishSummarySheet`) — the whole point of the sheet is that it states
/// the same triple the header does, so both render through the one widget.
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
