import 'package:flutter/material.dart';
import '../services/display_units.dart';

import '../data/exercise_library.dart';
import '../data/routine_templates.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/numeric_guard.dart';
import '../services/routine_factory.dart';
import '../services/schedule_service.dart';
import '../theme/lockout_theme.dart';
import '../widgets/house/nv_exercise_picker.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_dialog.dart';
import '../widgets/house/nv_sheet.dart';
import '../widgets/house/nv_segmented_button.dart';
import '../widgets/house/nv_switch.dart';
import '../theme/lockout_shapes.dart';
import 'exercise_video_screen.dart';

/// Runs a nested sheet/pick action that resolves whether it changed
/// anything, so the caller knows whether to refresh.
typedef RefreshAfter = Future<void> Function(Future<bool?> Function() action);

/// A fresh row id. Time-based rather than a counter/uuid dependency; every
/// caller inserts immediately, so collision would require two inserts in the
/// same microsecond.
String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

class RoutinesTab extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  final ValueChanged<ScheduledDay>? onStartDay;

  /// Starts today's scheduled session from the featured-day card.
  ///
  /// `MainScreen` wires this to the Home tab's own session starter, so the
  /// user presses Start once here instead of being sent to Home to press a
  /// second button. Null when the tab is pumped standalone (widget tests), in
  /// which case the card simply offers no Start.
  final VoidCallback? onStartToday;

  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  RoutinesTab({
    super.key,
    this.onStartToday,
    this.onOpenSettings,
    this.onStartDay,
  });

  @override
  State<RoutinesTab> createState() => RoutinesTabState();
}

class RoutinesTabState extends State<RoutinesTab> {
  List<Routine> _routines = [];
  final Map<String, List<TrainingDay>> _routineDays = {};
  final Map<String, List<ExerciseDef>> _dayExercises = {};
  final Map<String, List<WarmupItem>> _dayWarmups = {};
  final Map<String, List<FinisherItem>> _dayFinishers = {};
  String _activeRoutineId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRoutinesData();
  }

  /// Called by MainScreen when this tab becomes visible again.
  Future<void> reload() => _loadAllRoutinesData();

  Future<void> _loadAllRoutinesData() async {
    final db = DatabaseService.instance;
    final routines = (await db.getRoutines()).map(Routine.fromMap).toList();

    final days = <String, List<TrainingDay>>{};
    final exercises = <String, List<ExerciseDef>>{};
    final warmups = <String, List<WarmupItem>>{};
    final finishers = <String, List<FinisherItem>>{};

    for (final r in routines) {
      final dayList = (await db.getDaysForRoutine(
        r.id,
      )).map(TrainingDay.fromMap).toList();
      days[r.id] = dayList;

      for (final d in dayList) {
        exercises[d.id] = (await db.getExercisesForDay(
          d.id,
        )).map(ExerciseDef.fromMap).toList();
        warmups[d.id] = (await db.getWarmupsForDay(
          d.id,
        )).map(WarmupItem.fromMap).toList();
        finishers[d.id] = (await db.getFinishersForDay(
          d.id,
        )).map(FinisherItem.fromMap).toList();
      }
    }

    final active = await db.getActiveRoutine();

    if (!mounted) return;
    setState(() {
      _routines = routines;
      _routineDays
        ..clear()
        ..addAll(days);
      _dayExercises
        ..clear()
        ..addAll(exercises);
      _dayWarmups
        ..clear()
        ..addAll(warmups);
      _dayFinishers
        ..clear()
        ..addAll(finishers);
      _activeRoutineId = active == null ? '' : active['id'] as String;
      _isLoading = false;
    });
  }

  void _openVideo(String name, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseVideoScreen(exerciseName: name, videoUrl: url),
      ),
    );
  }

  /// A [TrainingDay] loaded from the DB never carries its exercises inline —
  /// they live in [_dayExercises], loaded separately. Hydrate a copy so
  /// [dayRowSummary] and [DayRow] see the real count.
  // --- CREATE ROUTINE ---

  /// Opens the create-routine form. `_CreateRoutineForm` owns its own
  /// controller and selection state (see its class doc for why that, rather
  /// than hoisting, is what keeps typed state alive across a non-dismissing
  /// drag without also reintroducing a use-after-dispose).
  Future<void> _openCreateRoutineSheet() async {
    final saved = await showNvEditor<bool>(
      context: context,
      title: 'Create routine',
      builder: (ctx) => _CreateRoutineForm(),
    );
    if (saved == true && mounted) await reload();
  }

  // --- ADD / EDIT TRAINING DAY ---

  /// Opens the training-day form. Resolves `true` only when the day was
  /// actually saved, so a caller that must close a parent sheet (the day
  /// detail sheet, on an edit) can tell a save apart from a dismiss.
  Future<bool?> _openDayFormSheet(String routineId, {TrainingDay? existing}) {
    final dayCount = (_routineDays[routineId] ?? []).length;
    return showNvEditor<bool>(
      context: context,
      title: existing == null ? 'Add training day' : 'Edit day',
      builder: (ctx) => _DayForm(
        routineId: routineId,
        existing: existing,
        dayCount: dayCount,
      ),
    );
  }

  // --- WARMUP / FINISHER ROWS ---

  /// Opens the warm-up/finisher item form. Resolves `true` only if an item
  /// was actually added.
  Future<bool?> _openSubItemSheet({
    required String dayId,
    required bool isWarmup,
    required int index,
  }) {
    return showNvEditor<bool>(
      context: context,
      title: isWarmup ? 'Add warm-up' : 'Add finisher',
      builder: (ctx) =>
          _SubItemForm(dayId: dayId, isWarmup: isWarmup, index: index),
    );
  }

  // --- ADD / EDIT EXERCISE ---

  /// Resolves `true` only if an exercise was added; `null`/`false` for a
  /// cancelled pick or a dismissed sheet.
  Future<bool?> _addExerciseToDay(String dayId) async {
    final picked = await showExercisesPicker(context);
    if (picked == null || picked.isEmpty || !mounted) return null;
    final start = (_dayExercises[dayId] ?? []).length;
    final batch = _newId();
    try {
      await DatabaseService.instance.insertExercises([
        for (var i = 0; i < picked.length; i++)
          ExerciseDef(
            id: '$batch-$i',
            dayId: dayId,
            name: picked[i].name,
            targetSets: picked[i].sets,
            targetRepsMin: picked[i].repsMin,
            targetRepsMax: picked[i].repsMax,
            muscleGroup: picked[i].muscleGroup,
            orderIndex: start + i,
          ).toMap(),
      ]);
      return true;
    } catch (_) {
      if (mounted) {
        showNvSnackbar(
          context: context,
          message: 'Exercises not added. Please try again.',
        );
      }
      return false;
    }
  }

  /// Resolves `true` if the exercise was saved or removed — either way the
  /// caller's list is stale and must refresh.
  Future<bool?> _openExerciseSheet(ExerciseDef ex, {bool isNew = false}) {
    return showNvEditor<bool>(
      context: context,
      title: isNew ? 'Add exercise' : 'Edit exercise',
      builder: (ctx) =>
          _ExerciseForm(ex: ex, isNew: isNew, onWatch: _openVideo),
    );
  }

  Future<void> _confirmDeleteRoutine(Routine routine) async {
    final confirmed = await showNvDestructiveDialog(
      context: context,
      title: 'Delete routine?',
      body:
          '"${routine.name}" and its planned days and exercises will be removed. Completed workouts stay in your history.',
      confirmLabel: 'Delete',
      cancelLabel: 'Keep routine',
    );
    if (!confirmed || !mounted) return;
    await DatabaseService.instance.deleteRoutine(routine.id);
    if (mounted) await reload();
  }

  Future<void> _setActive(Routine routine) async {
    await DatabaseService.instance.setActiveRoutine(routine.id);
    if (!mounted) return;
    await _loadAllRoutinesData();
  }

  // --- DAY DETAIL SHEET ---

  /// Opens a day's detail in a sheet rather than expanding it inline.
  ///
  /// The routine list was three levels of bordered box deep; a sheet gives
  /// the detail the whole screen and leaves the week scannable behind it.
  Future<void> _openDaySheet(Routine routine, TrainingDay day) async {
    await showNvEditor<void>(
      context: context,
      title: '${_dayLabel(day.tag)} · ${day.name}',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) {
          final exercises = _dayExercises[day.id] ?? [];
          final warmups = _dayWarmups[day.id] ?? [];
          final finishers = _dayFinishers[day.id] ?? [];
          final accent = Theme.of(context).colorScheme.primaryContainer;
          final onAccent = Theme.of(context).colorScheme.onPrimaryContainer;
          return _buildDayDetail(
            ctx,
            setSheet,
            routine,
            day,
            exercises,
            warmups,
            finishers,
            accent,
            onAccent,
          );
        },
      ),
    );
    // No trailing `reload()` here: every mutation path reachable from
    // `_buildDayDetail` (`refreshAfter`, the warm-up/finisher remove
    // handlers, EDIT DAY, DELETE DAY) already calls `_loadAllRoutinesData()`
    // itself the moment it changes something, so `RoutinesTabState` is
    // already current by the time this sheet closes. Reloading again here
    // would re-run the N+1x3 query walk over every routine and day for
    // nothing — whether or not anything changed.
  }

  Widget _buildDayDetail(
    BuildContext sheetCtx,
    StateSetter setSheet,
    Routine routine,
    TrainingDay day,
    List<ExerciseDef> exercises,
    List<WarmupItem> warmups,
    List<FinisherItem> finishers,
    Color accent,
    Color onAccent,
  ) {
    Future<void> refresh(Future<bool?> Function() action) async {
      final changed = await action();
      if (changed != true || !mounted) return;
      await reload();
      if (sheetCtx.mounted) setSheet(() {});
    }

    Widget extras(
      String title,
      List<(String, String, VoidCallback)> items,
      VoidCallback add,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NvHeading(title),
        if (items.isNotEmpty)
          NvGroupedList(
            children: [
              for (final item in items)
                NvListItem(
                  title: item.$1,
                  supporting: item.$2,
                  leading: const NvIconBadge(
                    icon: Icons.self_improvement_rounded,
                    shape: LockoutShape.arch,
                    tone: NvTone.tertiary,
                  ),
                  trailing: NvShapeButton(
                    icon: Icons.close_rounded,
                    label: 'Remove ${item.$1}',
                    onPressed: item.$3,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        NvButton(
          variant: NvButtonVariant.tonal,
          label: 'Add ${title == 'Warm-up' ? 'warm-up' : 'finisher'}',
          icon: Icons.add_rounded,
          onPressed: add,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (day.focus.isNotEmpty)
          Text(day.focus, style: Theme.of(sheetCtx).textTheme.titleMedium),
        if (day.note.isNotEmpty) ...[
          const SizedBox(height: 12),
          NvSurface(tone: NvTone.tertiary, child: Text(day.note)),
        ],
        if (day.isRestDay)
          const NvEmpty(
            title: 'Recovery is part of the plan',
            message:
                'Take the day to recover. Your next session will be ready when you are.',
            icon: Icons.bedtime_outlined,
          )
        else ...[
          extras(
            'Warm-up',
            warmups
                .map(
                  (w) => (
                    w.name,
                    w.amt,
                    () async {
                      await DatabaseService.instance.deleteWarmup(w.id);
                      await reload();
                      if (sheetCtx.mounted) setSheet(() {});
                    },
                  ),
                )
                .toList(),
            () => refresh(
              () => _openSubItemSheet(
                dayId: day.id,
                isWarmup: true,
                index: warmups.length,
              ),
            ),
          ),
          NvHeading('Exercises', action: Text('${exercises.length}')),
          if (exercises.isEmpty)
            const Text('Add an exercise to build this session.'),
          NvGroupedList(
            children: [
              for (var i = 0; i < exercises.length; i++)
                NvListItem(
                  leading: NvIconBadge(
                    icon: Icons.fitness_center_rounded,
                    shape: LockoutShape.values[[8, 11, 7, 14, 4][i % 5]],
                    tone: NvTone.values[i % 3],
                  ),
                  title: exercises[i].name,
                  supporting: exercises[i].targetLabel,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => refresh(() => _openExerciseSheet(exercises[i])),
                ),
            ],
          ),
          const SizedBox(height: 12),
          NvButton(
            variant: NvButtonVariant.tonal,
            label: 'Add exercise',
            icon: Icons.add_rounded,
            onPressed: () => refresh(() => _addExerciseToDay(day.id)),
          ),
          extras(
            'Finisher',
            finishers
                .map(
                  (w) => (
                    w.name,
                    w.amt,
                    () async {
                      await DatabaseService.instance.deleteFinisher(w.id);
                      await reload();
                      if (sheetCtx.mounted) setSheet(() {});
                    },
                  ),
                )
                .toList(),
            () => refresh(
              () => _openSubItemSheet(
                dayId: day.id,
                isWarmup: false,
                index: finishers.length,
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            NvButton(
              variant: NvButtonVariant.tonal,
              label: 'Edit day',
              icon: Icons.edit_outlined,
              onPressed: () async {
                final saved = await _openDayFormSheet(
                  routine.id,
                  existing: day,
                );
                if (saved != true || !mounted) return;
                await reload();
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              },
            ),
            NvButton(
              variant: NvButtonVariant.danger,
              label: 'Delete day',
              onPressed: () async {
                final confirmed = await showNvDestructiveDialog(
                  context: sheetCtx,
                  title: 'Delete this day?',
                  body:
                      'This removes the day and its planned exercises. Completed workouts stay in your history.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Keep day',
                );
                if (!confirmed || !mounted) return;
                await DatabaseService.instance.deleteDay(day.id);
                await reload();
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              },
            ),
          ],
        ),
        if (!day.isRestDay &&
            exercises.isNotEmpty &&
            widget.onStartDay != null) ...[
          const SizedBox(height: 20),
          NvButton(
            variant: NvButtonVariant.filled,
            label: 'Start workout',
            icon: Icons.play_arrow_rounded,
            large: true,
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              widget.onStartDay!(
                ScheduledDay(routine: routine, day: day, exercises: exercises),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _openRoutine(Routine routine) async {
    await showNvEditor<void>(
      context: context,
      title: routine.name,
      builder: (ctx) => StatefulBuilder(
        builder: (_, update) {
          final days = _routineDays[routine.id] ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NvSurface(
                tone: NvTone.primary,
                child: Row(
                  children: [
                    const NvIconBadge(
                      icon: Icons.fitness_center_rounded,
                      shape: LockoutShape.flower,
                      size: 64,
                      tone: NvTone.surface,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.id == _activeRoutineId
                                ? 'Active plan'
                                : 'Training plan',
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                          Text(
                            '${days.length} ${days.length == 1 ? 'day' : 'days'} · ${routine.schedulingMode == SchedulingMode.weekday ? 'Weekly schedule' : 'Rotating cycle'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const NvHeading('Your week'),
              if (days.isEmpty)
                const Text('No days yet. Add your first training or rest day.'),
              NvGroupedList(
                children: [
                  for (var i = 0; i < days.length; i++)
                    NvListItem(
                      leading: NvIconBadge(
                        icon: days[i].isRestDay
                            ? Icons.bedtime_outlined
                            : Icons.fitness_center_rounded,
                        shape: LockoutShape.values[[11, 8, 14, 6, 9][i % 5]],
                        tone: NvTone.values[i % 3],
                      ),
                      title: days[i].name,
                      supporting:
                          '${_dayLabel(days[i].tag)} · ${(_dayExercises[days[i].id] ?? []).length} exercises',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await _openDaySheet(routine, days[i]);
                        if (ctx.mounted) update(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              NvButton(
                variant: NvButtonVariant.filled,
                label: 'Add day',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final changed = await _openDayFormSheet(routine.id);
                  if (changed == true) {
                    await reload();
                    if (ctx.mounted) update(() {});
                  }
                },
              ),
              const SizedBox(height: 12),
              if (routine.id != _activeRoutineId)
                NvButton(
                  variant: NvButtonVariant.tonal,
                  label: 'Use this plan',
                  onPressed: () async {
                    await _setActive(routine);
                    if (ctx.mounted) update(() {});
                  },
                ),
              const SizedBox(height: 16),
              NvButton(
                variant: NvButtonVariant.danger,
                label: 'Delete routine',
                onPressed: () async {
                  await _confirmDeleteRoutine(routine);
                  await reload();
                  if (ctx.mounted &&
                      !_routines.any((r) => r.id == routine.id)) {
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _dayLabel(String code) => code.isEmpty
      ? 'Unscheduled'
      : '${code[0]}${code.substring(1).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final active = _routines.where((r) => r.id == _activeRoutineId).firstOrNull;
    return NvPage(
      title: 'Training',
      actions: [
        NvShapeButton(
          key: const ValueKey('open-settings'),
          icon: Icons.settings_outlined,
          label: 'Settings',
          onPressed: widget.onOpenSettings,
        ),
      ],
      children: [
        if (active != null)
          NvSurface(
            tone: NvTone.primary,
            radius: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        active.name,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    const NvIconBadge(
                      icon: Icons.fitness_center_rounded,
                      shape: LockoutShape.flower,
                      size: 72,
                      tone: NvTone.surface,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_routineDays[active.id] ?? []).length} ${(_routineDays[active.id] ?? []).length == 1 ? 'day' : 'days'} in your plan',
                ),
                const SizedBox(height: 20),
                if (active.schedulingMode == SchedulingMode.weekday)
                  NvWeekStrip(
                    dates: const {},
                    plannedWeekdays: {
                      for (final day
                          in _routineDays[active.id] ?? <TrainingDay>[])
                        if (!day.isRestDay)
                          const [
                                'mon',
                                'tue',
                                'wed',
                                'thu',
                                'fri',
                                'sat',
                                'sun',
                              ].indexOf(day.tag.trim().toLowerCase()) +
                              1,
                    },
                  )
                else ...[
                  const Text('Training cycle'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final day
                          in _routineDays[active.id] ?? <TrainingDay>[])
                        Tooltip(
                          message: day.name,
                          child: NvSurface(
                            padding: const EdgeInsets.all(LockoutTheme.spaceSm),
                            tone: NvTone.secondary,
                            child: Text(
                              '${day.orderIndex + 1} · ${day.isRestDay ? 'Rest' : day.name}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                NvButton(
                  variant: NvButtonVariant.filled,
                  label: 'Open plan',
                  onPressed: () => _openRoutine(active),
                ),
              ],
            ),
          ),
        if (_routines.isEmpty)
          NvEmpty(
            title: 'Build your training week',
            message:
                'Start with a ready-made split or create a routine of your own.',
            action: 'Create routine',
            onPressed: _openCreateRoutineSheet,
          ),
        const NvHeading('Your routines'),
        NvGroupedList(
          children: [
            for (var i = 0; i < _routines.length; i++)
              NvListItem(
                leading: NvIconBadge(
                  icon: Icons.fitness_center_rounded,
                  shape: LockoutShape.values[[11, 8, 14, 6, 9][i % 5]],
                  tone: NvTone.values[i % 3],
                ),
                title: _routines[i].name,
                supporting: _routines[i].id == _activeRoutineId
                    ? 'Active plan'
                    : '${(_routineDays[_routines[i].id] ?? []).length} ${(_routineDays[_routines[i].id] ?? []).length == 1 ? 'day' : 'days'}',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openRoutine(_routines[i]),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_routines.isNotEmpty)
          NvButton(
            variant: NvButtonVariant.filled,
            label: 'Create routine',
            icon: Icons.add_rounded,
            onPressed: _openCreateRoutineSheet,
          ),
        const NvHeading('Exercise library'),
        NvListItem(
          leading: const NvIconBadge(
            icon: Icons.search_rounded,
            shape: LockoutShape.arch,
            tone: NvTone.secondary,
          ),
          title: 'Explore exercises',
          supporting: 'Search by name, muscle or equipment',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final picked = await showExercisePicker(context);
            if (picked != null && mounted) _openVideo(picked.name, '');
          },
        ),
      ],
    );
  }
}

// --- FORM WIDGETS ---
//
// Each of the four sheet forms below is its own `StatefulWidget` rather than
// a builder function fed hoisted controllers/locals. `showNvEditor`'s
// `builder` is re-invoked on every rebuild of the sheet's own drag-handling
// state (`_BottomSheetState._handleDragStart`/`_handleDragEnd`, both call
// `setState`), but re-invoking a builder only recreates the `Widget`
// description — a `StatefulWidget`'s `State` (and everything it owns,
// including its `TextEditingController`s) survives that exactly the way a
// `StatefulBuilder`'s closure state used to. The difference is disposal:
// `State.dispose()` runs when the widget is actually removed from the tree,
// which for a modal route is when its exit animation finishes — not when
// `showNvEditor`'s returned Future completes, which fires when the pop
// *starts* (`Route.didPop` -> `didComplete`), roughly 200ms earlier while
// the sheet is still mounted and rebuilding. Disposing controllers in a
// `finally` around that `await` (the previous fix wave's approach) tore them
// down while `EditableText` was still subscribed to them, producing a
// use-after-dispose the instant a field had been focused/edited before
// close. Owning the controllers in `State` ties disposal to the same
// lifecycle event that removes the widget, so there is no window where the
// controller is gone but something in the tree still points at it.

class _CreateRoutineForm extends StatefulWidget {
  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  _CreateRoutineForm();

  @override
  State<_CreateRoutineForm> createState() => _CreateRoutineFormState();
}

class _CreateRoutineFormState extends State<_CreateRoutineForm> {
  final _nameCtrl = TextEditingController();
  var _mode = SchedulingMode.weekday;

  // Deliberately null, not `RoutineTemplate.all.first`. That first entry is
  // `blank`, so a pre-selected default meant the fastest path through this
  // form — type a name, hit SAVE — produced a routine with no days, while
  // the empty state behind the sheet promises every day arrives already
  // filled in. Nothing is ticked until the user picks, and SAVE waits.
  RoutineTemplate? _template;
  var _showTemplateError = false;
  var _showNameError = false;
  var _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your starting point',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < RoutineTemplate.all.length; i++) ...[
          NvSurface(
            key: ValueKey('routine-template-${RoutineTemplate.all[i].key}'),
            tone: _template?.key == RoutineTemplate.all[i].key
                ? NvTone.primary
                : NvTone.values[(i + 1) % 3],
            selected: _template?.key == RoutineTemplate.all[i].key,
            onPressed: () => setState(() {
              _template = RoutineTemplate.all[i];
              _showTemplateError = false;
            }),
            child: Row(
              children: [
                NvIconBadge(
                  icon: i == 0
                      ? Icons.edit_outlined
                      : Icons.fitness_center_rounded,
                  shape: LockoutShape.values[[14, 11, 8, 6, 9][i % 5]],
                  tone: NvTone.surface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i == 0 ? 'Custom routine' : RoutineTemplate.all[i].name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        RoutineTemplate.all[i].blurb,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _template?.key == RoutineTemplate.all[i].key
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (_showTemplateError)
          Text(
            'Choose a starter plan or a custom routine.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        const SizedBox(height: 20),
        NvField(
          label: 'Routine name',
          controller: _nameCtrl,
          hint: 'Name your plan',
        ),
        if (_showNameError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Enter a routine name',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const NvHeading('Scheduling'),
        NvSegmentedButton<SchedulingMode>(
          segments: const [
            NvSegment(value: SchedulingMode.weekday, label: 'Weekdays'),
            NvSegment(value: SchedulingMode.rotating, label: 'Rotating'),
          ],
          selected: _mode,
          onChanged: (v) => setState(() => _mode = v),
        ),
        const SizedBox(height: 12),
        Text(
          _mode == SchedulingMode.weekday
              ? 'Train on specific weekdays.'
              : 'Days cycle in order, one per calendar day.',
        ),
        const SizedBox(height: 24),
        NvButton(
          variant: NvButtonVariant.filled,
          label: _saving ? 'Creating…' : 'Save routine',
          onPressed: _saving
              ? null
              : () async {
                  final template = _template;
                  if (template == null) {
                    setState(() => _showTemplateError = true);
                    return;
                  }
                  final name = _nameCtrl.text.trim().isNotEmpty
                      ? _nameCtrl.text.trim()
                      : template.key == 'blank'
                      ? ''
                      : template.name;
                  if (name.isEmpty) {
                    setState(() => _showNameError = true);
                    return;
                  }
                  setState(() => _saving = true);
                  try {
                    await RoutineFactory.createFromTemplate(
                      name: name,
                      mode: _mode,
                      template: template,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (context.mounted) {
                      setState(() => _saving = false);
                      showNvSnackbar(
                        context: context,
                        message: 'Routine not saved. Please try again.',
                      );
                    }
                  }
                },
        ),
      ],
    );
  }
}

class _DayForm extends StatefulWidget {
  final String routineId;
  final TrainingDay? existing;
  final int dayCount;

  const _DayForm({
    required this.routineId,
    required this.dayCount,
    this.existing,
  });

  @override
  State<_DayForm> createState() => _DayFormState();
}

class _DayFormState extends State<_DayForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _focusCtrl;
  late final TextEditingController _noteCtrl;
  late String _tag;
  late bool _isRest;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _focusCtrl = TextEditingController(text: existing?.focus ?? '');
    _noteCtrl = TextEditingController(text: existing?.note ?? '');
    _tag = existing?.tag ?? ScheduleService.weekdayPickerOrder.first;
    _isRest = existing?.isRestDay ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Day of week', style: theme.textTheme.labelMedium),
        const SizedBox(height: LockoutTheme.spaceSm),
        Wrap(
          spacing: LockoutTheme.spaceSm,
          runSpacing: LockoutTheme.spaceSm,
          children: ScheduleService.weekdayPickerOrder.map((d) {
            final selected = _tag == d;
            return ChoiceChip(
              label: Text('${d[0]}${d.substring(1).toLowerCase()}'),
              selected: selected,
              onSelected: (_) => setState(() => _tag = d),
            );
          }).toList(),
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(label: 'Day name', controller: _nameCtrl, hint: 'e.g. Push'),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(
          label: 'Focus (muscle groups)',
          controller: _focusCtrl,
          hint: 'e.g. Chest - Shoulders - Triceps',
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(label: 'Day note (optional)', controller: _noteCtrl),
        // Guidance the user needs before typing, not a hint hidden inside
        // the field until focus — `LockoutField` has no `helperText` slot
        // (out of scope for this file), so this stands in for one.
        const SizedBox(height: LockoutTheme.spaceXs),
        Text(
          'Injury cautions, tempo rules...',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: LockoutTheme.spaceSm),
        NvSwitchRow(
          title: 'Mark as rest day',
          value: _isRest,
          onChanged: (v) => setState(() => _isRest = v),
        ),
        const SizedBox(height: LockoutTheme.spaceSm),
        NvSaveButton(
          onSave: () async {
            if (_nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter a name before saving')),
              );
              return;
            }
            await DatabaseService.instance.insertDay(
              TrainingDay(
                id: existing?.id ?? _newId(),
                routineId: widget.routineId,
                name: _nameCtrl.text.trim(),
                tag: _tag,
                orderIndex: existing?.orderIndex ?? widget.dayCount,
                focus: _focusCtrl.text.trim(),
                note: _noteCtrl.text.trim(),
                isRestDay: _isRest,
              ).toMap(),
            );
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },
          // 'Create day', not 'Add day': the week expander's own action is
          // already called Add day, and two controls with the same words
          // one tap apart is ambiguous.
          label: widget.existing == null ? 'Create day' : 'Save day',
        ),
      ],
    );
  }
}

class _SubItemForm extends StatefulWidget {
  final String dayId;
  final bool isWarmup;
  final int index;

  const _SubItemForm({
    required this.dayId,
    required this.isWarmup,
    required this.index,
  });

  @override
  State<_SubItemForm> createState() => _SubItemFormState();
}

class _SubItemFormState extends State<_SubItemForm> {
  final _nameCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NvField(
          label: 'Movement',
          controller: _nameCtrl,
          hint: widget.isWarmup ? 'e.g. Arm circles' : 'e.g. Push-ups',
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(
          label: 'Amount',
          controller: _amtCtrl,
          hint: widget.isWarmup ? 'e.g. 3-4 min' : 'e.g. 12-15 reps',
        ),
        const SizedBox(height: LockoutTheme.spaceSm),
        NvSaveButton(
          onSave: () async {
            if (_nameCtrl.text.trim().isEmpty) return;
            final db = DatabaseService.instance;
            if (widget.isWarmup) {
              await db.insertWarmup(
                WarmupItem(
                  id: _newId(),
                  dayId: widget.dayId,
                  name: _nameCtrl.text.trim(),
                  amt: _amtCtrl.text.trim(),
                  orderIndex: widget.index,
                ).toMap(),
              );
            } else {
              await db.insertFinisher(
                FinisherItem(
                  id: _newId(),
                  dayId: widget.dayId,
                  name: _nameCtrl.text.trim(),
                  amt: _amtCtrl.text.trim(),
                  orderIndex: widget.index,
                ).toMap(),
              );
            }
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },
          label: 'Add',
        ),
      ],
    );
  }
}

class _ExerciseForm extends StatefulWidget {
  final ExerciseDef ex;
  final bool isNew;
  final void Function(String name, String videoUrl) onWatch;

  const _ExerciseForm({
    required this.ex,
    required this.onWatch,
    this.isNew = false,
  });

  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsMinCtrl;
  late final TextEditingController _repsMaxCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _restCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _videoCtrl;

  @override
  void initState() {
    super.initState();
    final ex = widget.ex;
    _setsCtrl = TextEditingController(text: ex.targetSets.toString());
    _repsMinCtrl = TextEditingController(text: ex.targetRepsMin.toString());
    _repsMaxCtrl = TextEditingController(text: ex.targetRepsMax.toString());
    _weightCtrl = TextEditingController(
      text: ex.targetWeightKg == 0
          ? ''
          : DisplayUnits.value(ex.targetWeightKg).toString(),
    );
    _restCtrl = TextEditingController(text: ex.restDefaultS.toString());
    _noteCtrl = TextEditingController(text: ex.note);
    _videoCtrl = TextEditingController(text: ex.videoUrl);
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsMinCtrl.dispose();
    _repsMaxCtrl.dispose();
    _weightCtrl.dispose();
    _restCtrl.dispose();
    _noteCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = widget.ex;
    final group = ex.muscleGroup.isNotEmpty
        ? ex.muscleGroup
        : ExerciseLibrary.groupFor(ex.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Not a titleLarge: the SheetScaffold title above
                  // ("ADD EXERCISE" / "EDIT EXERCISE") already carries that
                  // weight, so this is a secondary line, not a second
                  // heading.
                  Text(ex.name, style: theme.textTheme.titleMedium),
                  if (group.isNotEmpty) ...[
                    const SizedBox(height: LockoutTheme.spaceXs),
                    Chip(
                      label: Text(group),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
            NvButton(
              variant: NvButtonVariant.tonal,
              onPressed: () {
                widget.onWatch(ex.name, _videoCtrl.text.trim());
              },
              icon: Icons.play_arrow_rounded,
              label: 'Watch form',
            ),
          ],
        ),
        const SizedBox(height: LockoutTheme.spaceLg),
        Row(
          children: [
            Expanded(
              child: NvField(
                label: 'Sets',
                controller: _setsCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: LockoutTheme.spaceSm),
            Expanded(
              child: NvField(
                label: 'Min reps',
                controller: _repsMinCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: LockoutTheme.spaceSm),
            Expanded(
              child: NvField(
                label: 'Max reps',
                controller: _repsMaxCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: NvField(
                label: 'Weight (${DisplayUnits.unit})',
                controller: _weightCtrl,
                hint: '0',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: LockoutTheme.spaceSm),
            Expanded(
              child: NvField(
                label: 'Rest (sec)',
                controller: _restCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(label: 'Note', controller: _noteCtrl),
        // Guidance the user needs before typing, not a hint hidden inside
        // the field until focus — `LockoutField` has no `helperText` slot
        // (out of scope for this file), so this stands in for one.
        const SizedBox(height: LockoutTheme.spaceXs),
        Text('Cues, injury notes, tempo...', style: theme.textTheme.bodySmall),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(label: 'Pinned video URL (optional)', controller: _videoCtrl),
        const SizedBox(height: LockoutTheme.spaceXs),
        Text(
          'Empty video URL means Watch opens a YouTube search for a 3D / '
          'animated form demo of this exercise. Paste a link to pin one.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvSaveButton(
          onSave: () async {
            final targetSets = int.tryParse(_setsCtrl.text);
            final minReps = int.tryParse(_repsMinCtrl.text);
            final parsedMax = int.tryParse(_repsMaxCtrl.text);
            final rest = int.tryParse(_restCtrl.text);
            if (targetSets == null ||
                targetSets < 1 ||
                minReps == null ||
                minReps < 1 ||
                parsedMax == null ||
                parsedMax < minReps ||
                rest == null ||
                rest < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Use positive sets and reps, a valid rep range, and a non-negative rest time.',
                  ),
                ),
              );
              return;
            }
            var maxReps = int.tryParse(_repsMaxCtrl.text) ?? ex.targetRepsMax;
            if (maxReps < minReps) maxReps = minReps;

            await DatabaseService.instance.insertExercise(
              ex
                  .copyWith(
                    targetSets: targetSets,
                    targetRepsMin: minReps,
                    targetRepsMax: maxReps,
                    // `double.tryParse` accepts 'Infinity' and 'NaN', and this
                    // field has no `inputFormatters`. A non-finite target weight
                    // is copied into every live set the exercise starts,
                    // multiplied into the session's `total_volume_kg`, and
                    // persisted — after which LOG's `toInt()` throws on every
                    // launch and the archive row that would let the user delete
                    // the session is the thing that fails to paint.
                    // `NumericGuard.sanitiseKg` is the same guard Settings and
                    // BODY's measurement form already apply.
                    targetWeightKg: DisplayUnits.toKg(
                      NumericGuard.sanitiseKg(_weightCtrl.text),
                    ),
                    restDefaultS:
                        int.tryParse(_restCtrl.text) ?? ex.restDefaultS,
                    note: _noteCtrl.text.trim(),
                    videoUrl: _videoCtrl.text.trim(),
                    muscleGroup: group,
                  )
                  .toMap(),
            );
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },
          label: widget.isNew ? 'Add to day' : 'Save changes',
        ),
        if (!widget.isNew) ...[
          const SizedBox(height: LockoutTheme.spaceSm),
          NvSaveButton(
            variant: NvButtonVariant.danger,
            onSave: () async {
              await DatabaseService.instance.deleteExercise(ex.id);
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            label: 'Remove exercise',
          ),
        ],
      ],
    );
  }
}
