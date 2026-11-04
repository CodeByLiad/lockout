import 'package:flutter/material.dart';
import '../services/display_units.dart';

import '../theme/lockout_shapes.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_feedback.dart';
import 'profile_setup_screen.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/goal_service.dart';
import '../services/numeric_guard.dart';
import '../services/routine_factory.dart';
import '../services/units.dart';
import '../theme/lockout_theme.dart';

class BodyTab extends StatefulWidget {
  final bool logOnOpen;
  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  BodyTab({super.key, this.logOnOpen = false});

  @override
  State<BodyTab> createState() => BodyTabState();
}

class BodyTabState extends State<BodyTab> {
  List<BodyEntry> _bodyLogs = [];
  // `_HistoryList` inside an already-open LOG HISTORY sheet reads this
  // directly rather than the plain `_bodyLogs` field above (Finding 1):
  // `showNvEditor`'s modal route lives in the root `Overlay`, a sibling
  // of this State's own Element subtree rather than a descendant of it, so
  // `setState` here cannot reach back into an already-built sheet. A
  // `ValueNotifier` does, because `ValueListenableBuilder` subscribes to
  // the object itself, not to an ancestor rebuild — so an UNDO tapped from
  // the banner while the sheet is still open (the banner is deliberately
  // reachable without closing it) updates that list live instead of only
  // the next time the sheet opens.
  final ValueNotifier<List<BodyEntry>> _bodyLogsNotifier =
      ValueNotifier<List<BodyEntry>>(const []);
  GoalSnapshot? _goal;
  String _heightUnit = 'cm';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      if (mounted && widget.logOnOpen) _openMeasurementSheet();
    });
  }

  @override
  void dispose() {
    _bodyLogsNotifier.dispose();
    super.dispose();
  }

  /// Called by MainScreen so a height or goal changed in Settings shows here.
  Future<void> reload() => _loadData();

  Future<void> _loadData() async {
    await DisplayUnits.load();
    final db = DatabaseService.instance;
    final unit = await db.getSetting('height_unit', defaultValue: 'cm');
    final goal = await GoalService.instance.snapshot();

    if (!mounted) return;
    // Derived from `goal.bodyLogs` rather than a second `getBodyLogs()`
    // call: the sparkline/latest-weight series and the delta `build()`
    // computes from `_goal.bodyLogs` used to come from two separate
    // queries that happened to agree in practice but had no structural
    // reason to — one list, one query, so they cannot drift apart.
    final logs = goal.bodyLogs.map(BodyEntry.fromMap).toList();
    setState(() {
      _bodyLogs = logs;
      _heightUnit = unit == 'ft' ? 'ft' : 'cm';
      _goal = goal;
      _isLoading = false;
    });
    _bodyLogsNotifier.value = logs;
  }

  Future<void> _openMeasurementSheet() async {
    await showNvEditor<void>(
      context: context,
      title: 'Log measurement',
      builder: (ctx) => _MeasurementForm(),
    );
    if (!mounted) return;
    await reload();
  }

  /// Deletes [log] immediately, then offers a few seconds to reverse it —
  /// this destroys logged history that cannot be reconstructed, and nothing
  /// short of a real undo window is an acceptable guard on a single 40dp
  /// tap (Finding 3 / Ruling F). See the doc on `showUndoBanner` for why it
  /// uses the root `Overlay` rather than a `ScaffoldMessenger` SnackBar, and
  /// why undo keeps working after the LOG HISTORY sheet that triggered the
  /// delete has been closed.
  Future<void> _deleteLog(BodyEntry log) async {
    await DatabaseService.instance.deleteBodyLog(log.id);
    // A removed weight changes TDEE, so the calorie target moves too.
    await GoalService.instance.recalculateAndSaveTarget();
    if (!mounted) return;
    await reload();
    if (!mounted) return;

    showNvUndo(
      context,
      message: '${log.weightKg.toStringAsFixed(1)} kg entry deleted',
      onUndo: () => _restoreLog(log),
    );
  }

  /// Re-inserts [log] with its original id and every field intact —
  /// `insertBodyLog` uses `ConflictAlgorithm.replace`, so this is a true
  /// restore, not a near-copy with a freshly minted id.
  Future<void> _restoreLog(BodyEntry log) async {
    await DatabaseService.instance.insertBodyLog(log.toMap());
    await GoalService.instance.recalculateAndSaveTarget();
    if (!mounted) return;
    await reload();
  }

  /// [sheetContext] is the RECOMMENDED PLAN sheet's own `BuildContext`
  /// (`builder: (ctx) => ...` in `_buildPlanCard`'s caller), captured here
  /// rather than reached for after the `await` below (Finding 7): if the
  /// sheet is dragged away while `createFromTemplate` is in flight, its
  /// route pops itself, and `Navigator.of(context).maybePop()` — `context`
  /// being this State's own, long-lived one — would then pop whatever is
  /// *next* topmost on that same Navigator instead, which in the app is
  /// `MainScreen`'s own route. `ModalRoute.of`/`Navigator.of` are read
  /// synchronously, before the `await`, while `sheetContext` is definitely
  /// still valid; `route.isCurrent` afterwards is a plain property read on
  /// the `Route` object itself, safe even if the underlying widget is long
  /// gone, and answers "is this specific sheet still the one on top" rather
  /// than "is *something* poppable".
  Future<void> _createRecommendedRoutine(BuildContext sheetContext) async {
    final rec = _goal?.training;
    if (rec == null) return;

    final route = ModalRoute.of(sheetContext);
    final navigator = Navigator.of(sheetContext);

    await RoutineFactory.createFromTemplate(
      name: rec.template.name,
      mode: SchedulingMode.weekday,
      template: rec.template,
      makeActive: true,
    );
    if (!mounted) return;

    // This button lives inside the RECOMMENDED PLAN sheet. A SnackBar shown
    // from here attaches to this tab's Scaffold, which sits *below* the
    // sheet's own modal-route OverlayEntry — measured at 390x844, the sheet
    // occupies y=158..844 and the SnackBar would render at y=765..844,
    // entirely behind the sheet and its barrier, so the routine was created
    // but nothing visibly happened (Finding 1). Popping the sheet first
    // puts this tab's Scaffold back on top before the SnackBar is queued —
    // but only if that sheet is still the thing on top to pop.
    if (route != null && route.isCurrent) {
      navigator.pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${rec.template.name} created and set active. '
          'Open the Workout tab.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final latest = _bodyLogs.firstOrNull?.weightKg;
    return NvPage(
      title: 'Measurements',
      back: Navigator.of(context).canPop(),
      footer: NvButton(
        variant: NvButtonVariant.filled,
        label: 'Log measurement',
        icon: Icons.add_rounded,
        large: true,
        onPressed: _openMeasurementSheet,
      ),
      children: [
        NvSurface(
          tone: NvTone.primary,
          radius: 36,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest == null
                          ? 'No measurement yet'
                          : DisplayUnits.format(context, latest),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest == null
                          ? 'Start with your first weigh-in.'
                          : 'Latest · ${_bodyLogs.first.dateStr}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const NvIconBadge(
                icon: Icons.monitor_weight_outlined,
                shape: LockoutShape.pentagon,
                tone: NvTone.surface,
                size: 64,
              ),
            ],
          ),
        ),
        const NvHeading('Weight trend'),
        NvSurface(
          tone: NvTone.tertiary,
          child: NvTrend(
            values: _bodyLogs.reversed.map((e) => e.weightKg).toList(),
          ),
        ),
        const NvHeading('Your plan'),
        NvGroupedList(
          children: [
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.flag_outlined,
                shape: LockoutShape.diamond,
                tone: NvTone.secondary,
              ),
              title: 'Goals & plan',
              supporting:
                  _goal?.profile.targetWeightKg != null &&
                      _goal!.profile.targetWeightKg > 0
                  ? 'Target ${_goal!.profile.targetWeightKg.toStringAsFixed(1)} kg'
                  : 'Set a target that works for you',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showNvEditor<void>(
                context: context,
                title: 'Goals & plan',
                builder: (_) => _buildGoalCard(),
              ),
            ),
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.straighten_rounded,
                shape: LockoutShape.arch,
                tone: NvTone.tertiary,
              ),
              title: 'About your BMI',
              supporting: _goal?.bmi == null
                  ? 'Uses weight and height only'
                  : _goal!.bmi!.toStringAsFixed(1),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showNvEditor<void>(
                context: context,
                title: 'About your BMI',
                builder: (_) => _buildBmiCard(),
              ),
            ),
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.fitness_center_rounded,
                shape: LockoutShape.gem,
              ),
              title: 'Recommended training',
              supporting:
                  _goal?.training?.template.name ??
                  'Complete your profile for a suggestion',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showNvEditor<void>(
                context: context,
                title: 'Recommended training',
                builder: (ctx) => _buildPlanCard(ctx),
              ),
            ),
          ],
        ),
        const NvHeading('Recent entries'),
        if (_bodyLogs.isEmpty)
          const Text('Your measurements will appear here after you log one.'),
        NvGroupedList(
          children: [
            for (final log in _bodyLogs)
              NvListItem(
                title: DisplayUnits.format(context, log.weightKg),
                supporting:
                    '${log.dateStr}${log.waistCm > 0 ? ' · Waist ${log.waistCm} cm' : ''}',
                trailing: NvShapeButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete entry',
                  tone: NvTone.surface,
                  onPressed: () => _deleteLog(log),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _editGoals() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => ProfileSetupScreen(editing:true,onCompleted:()=>Navigator.of(pageContext).pop()),
      ),
    );
    if (mounted) await reload();
  }

  Widget _buildBmiCard() {
    final goal = _goal;
    final height = goal?.profile.heightCm ?? 0;
    final metres = height / 100;
    final weight = goal?.currentWeightKg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NvSurface(
          tone: NvTone.tertiary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal?.bmi?.toStringAsFixed(1) ?? 'Not available',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Text('Body mass index'),
              const SizedBox(height: 8),
              const Text('An estimate, not a diagnosis.'),
            ],
          ),
        ),
        const NvHeading('How it is calculated'),
        NvGroupedList(
          children: [
            NvListItem(
              title: 'Weight',
              supporting: weight == null
                  ? 'Log a measurement first'
                  : '${weight.toStringAsFixed(1)} kg',
            ),
            NvListItem(
              title: 'Height',
              supporting: Units.formatHeight(height, _heightUnit),
            ),
            if (weight != null && height > 0)
              NvListItem(
                title: 'Calculation',
                supporting:
                    '${weight.toStringAsFixed(1)} ÷ (${metres.toStringAsFixed(2)} × ${metres.toStringAsFixed(2)})',
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'BMI uses weight and height. It does not distinguish muscle from body fat. Waist is tracked separately and is not used in this calculation.',
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    final snap = _goal;
    final plan = snap?.nutrition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan == null || snap == null)
          NvEmpty(
            title: 'Set a goal that fits you',
            message:
                'Add your weight, age and target to calculate your daily plan.',
            action: 'Edit profile & goals',
            onPressed: _editGoals,
            icon: Icons.flag_outlined,
          )
        else ...[
          NvSurface(
            tone: NvTone.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target ${snap.profile.targetWeightKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '${snap.currentWeightKg?.toStringAsFixed(1) ?? 'Not measured'} kg now',
                ),
                Text(
                  '${plan.weeks} weeks · ${plan.weeklyRatePct.toStringAsFixed(2)}% bodyweight per week',
                ),
              ],
            ),
          ),
          if (plan.warning != null) ...[
            const SizedBox(height: 16),
            NvSurface(tone: NvTone.tertiary, child: Text(plan.warning!)),
          ],
          const NvHeading('Daily nutrition'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              NvMetric(
                label: 'Daily target',
                value: '${plan.targetKcal} kcal',
                tone: NvTone.secondary,
              ),
              NvMetric(label: 'Protein', value: '${plan.proteinG} g'),
              NvMetric(label: 'Carbs', value: '${plan.carbG} g'),
              NvMetric(label: 'Fat', value: '${plan.fatG} g'),
            ],
          ),
          const NvHeading('How this is calculated'),
          NvGroupedList(
            children: [
              NvListItem(
                title: 'Resting energy',
                supporting: '${plan.bmr.round()} kcal',
              ),
              NvListItem(
                title: 'Activity multiplier',
                supporting: '× ${snap.profile.activity.multiplier}',
              ),
              NvListItem(
                title: 'Maintenance estimate',
                supporting: '${plan.tdee.round()} kcal',
              ),
              NvListItem(
                title: 'Goal adjustment',
                supporting: '${plan.dailyDeltaKcal} kcal',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'These are estimates based on your saved profile and measurements.',
          ),
          const SizedBox(height: 24),
          NvButton(
            variant: NvButtonVariant.filled,
            label: 'Edit goal',
            onPressed: _editGoals,
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCard(BuildContext sheetContext) {
    final rec = _goal?.training;
    if (rec == null) {
      return NvEmpty(
        title: 'Build your personal plan',
        message:
            'Complete your profile and log a measurement for a training recommendation.',
        action: 'Edit profile & goals',
        onPressed: _editGoals,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NvSurface(
          tone: NvTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rec.template.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text('${rec.daysPerWeek} training days a week'),
            ],
          ),
        ),
        const NvHeading('Why this split'),
        Text(rec.rationale),
        const NvHeading('How to load it'),
        Text(rec.loadingAdvice),
        const NvHeading('Conditioning'),
        Text(rec.cardioAdvice),
        const SizedBox(height: 24),
        NvButton(
          variant: NvButtonVariant.filled,
          label: 'Create this routine',
          icon: Icons.add_rounded,
          onPressed: () => _createRecommendedRoutine(sheetContext),
        ),
      ],
    );
  }
}

// --- FORM WIDGET ---
//
// Owns its own controllers as a `StatefulWidget` rather than a builder
// closure fed hoisted `TextEditingController`s — see the doc block at
// routines_tab.dart:807-827 for why: `showNvEditor`'s `builder` is
// re-invoked on every drag-driven rebuild of the sheet's own state, so a
// controller created inside the builder gets silently recreated (losing
// typed input), and a controller hoisted into the calling method and
// disposed in a `finally` around the awaited sheet Future gets disposed
// ~200ms before the sheet's exit animation finishes removing it from the
// tree, producing a use-after-dispose. Tying the controllers' lifecycle to
// `State.dispose()` avoids both. The pre-Task-10 version of this form built
// its controllers inline in `_showAddEntryModal` outside the builder, which
// avoided the reset bug but never disposed them at all (a leak); this fixes
// that too.
class _MeasurementForm extends StatefulWidget {
  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  _MeasurementForm();

  @override
  State<_MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<_MeasurementForm> {
  final _weightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    super.dispose();
  }

  /// Parses a required, strictly-positive, finite weight. `null` means
  /// "reject": `double.tryParse` happily accepts `Infinity`/`-Infinity`
  /// (which then renders as `INFINITY KG` in the hero and breaks the
  /// sparkline's normalisation into NaN) and a non-numeric string used to
  /// silently fall back to a bogus `0`. The rule itself lives in
  /// `NumericGuard`, shared with Settings and the routine builder's weight
  /// field so all four write sites cannot drift apart.
  double? _parseWeight(String raw) =>
      NumericGuard.parse(raw, min: 0.0, minExclusive: true);

  /// Parses an optional waist measurement. Blank text and a literal "0"
  /// both mean "not measured" and store `0.0` — before this fix, blank
  /// silently stored `0.0` but typing the more explicit "0" was rejected as
  /// invalid, two different answers to the same question. `null` means
  /// "reject": `Infinity`/`-Infinity` and a negative value are not a real
  /// waist measurement either way. Shares `NumericGuard` with the weight
  /// parse above; only the empty-means-zero rule is local to waist.
  double? _parseWaist(String raw) {
    if (raw.trim().isEmpty) return 0.0;
    return NumericGuard.parse(raw, min: 0.0);
  }

  Future<void> _save() async {
    // Guards against two fast taps inserting two rows.
    if (_saving) return;

    final weight = _parseWeight(_weightCtrl.text);
    if (weight == null) {
      setState(() => _error = 'Enter a valid weight in ${DisplayUnits.unit}.');
      return;
    }
    final waist = _parseWaist(_waistCtrl.text);
    if (waist == null) {
      setState(() => _error = 'Waist must be a valid measurement in cm.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final entry = BodyEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        dateStr: DateTime.now().toIso8601String().split('T').first,
        weightKg: DisplayUnits.toKg(weight),
        waistCm: waist,
      );
      await DatabaseService.instance.insertBodyLog(entry.toMap());
      // A new weight changes TDEE, so the calorie target moves too.
      await GoalService.instance.recalculateAndSaveTarget();
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NvField(
          label: 'Weight (${DisplayUnits.unit})',
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvField(
          label: 'Waist (cm) - optional',
          controller: _waistCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        if (_error != null) ...[
          const SizedBox(height: LockoutTheme.spaceSm),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: LockoutTheme.spaceXs),
        Text(
          'Waist is tracked on its own. It is not used in the BMI figure — '
          'BMI is weight and height only.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        // The `_saving` re-entrancy guard used to be invisible — SAVE
        // MEASUREMENT looked identically pressable mid-save. `IgnorePointer`
        // stops a second tap from reaching `_save` at all (belt-and-braces
        // with the guard inside it), and the dimmed opacity plus relabel
        // make that state visible instead of just structurally prevented.
        // Full-width for the same reason as `_buildPlanCard`'s primary
        // action (Finding 5): a bare `FilledButton` here renders left-aligned
        // at intrinsic width instead of matching the tab-level primary
        // action's `SizedBox(width: double.infinity)`.
        SizedBox(
          width: double.infinity,
          child: Opacity(
            opacity: _saving ? 0.6 : 1.0,
            child: IgnorePointer(
              ignoring: _saving,
              child: NvButton(
                variant: NvButtonVariant.filled,
                onPressed: _saving ? null : _save,
                label: _saving ? 'Saving…' : 'Save measurement',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
