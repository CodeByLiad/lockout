import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_service.dart';
import '../services/display_units.dart';
import '../services/notification_service.dart';
import '../services/nutrition_planner.dart';
import '../services/profile_setup_service.dart';
import '../services/units.dart';
import '../theme/lockout_shapes.dart';
import '../theme/theme_controller.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_dialog.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_segmented_button.dart';
import '../widgets/house/nv_setup_header.dart';
import '../widgets/house/nv_wavy_progress.dart';

/// The app is not mounted until a valid saved profile exists.
class ProfileGate extends StatefulWidget {
  final Widget child;
  final ProfileSetupService? service;
  const ProfileGate({super.key, required this.child, this.service});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<ProfileSetupState> _load;
  @override
  void initState() {
    super.initState();
    _load = (widget.service ?? ProfileSetupService()).load();
  }

  void _reload() {
    final next = (widget.service ?? ProfileSetupService()).load();
    setState(() {
      _load = next;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ProfileSetupState>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return NvPage(
          title: 'Your profile',
          children: [
            NvEmpty(
              title: 'Could not load your profile',
              message:
                  'Your saved data has not been changed. Retry to continue.',
              icon: Icons.error_outline_rounded,
              action: 'Retry',
              onPressed: _reload,
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const NvPage(
          title: 'Your profile',
          children: [
            Text('Loading your details…'),
            SizedBox(height: 20),
            NvWavyProgress(value: 0),
          ],
        );
      }
      if (!snapshot.data!.needsSetup) return widget.child;
      return ProfileSetupScreen(onCompleted: _reload);
    },
  );
}

/// Required setup and the unified later profile editor use the same fields.
class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool editing;
  final Future<ImportResult> Function()? restoreBackup;
  final Future<void> Function()? refreshReminders;
  const ProfileSetupScreen({
    super.key,
    required this.onCompleted,
    this.editing = false,
    this.restoreBackup,
    this.refreshReminders,
  });
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with WidgetsBindingObserver {
  static const _textKeys = [
    'age',
    'weight',
    'height_cm',
    'height_ft',
    'height_in',
    'target_weight',
    'weeks',
    'days',
  ];
  final _service = ProfileSetupService();
  final _scroll = ScrollController();
  final _fields = <String, TextEditingController>{};
  Map<String, String> _choices = {};
  String _baseline = '';
  int _step = 0;
  bool _loading = true,
      _busy = false,
      _applying = false,
      _submitted = false,
      _returnToReview = false,
      _finished = false,
      _draftFailed = false,
      _allowExit = false;
  String? _error;
  Future<void> _writes = Future.value();
  ProfileSetupDraft _draft({int? step}) => ProfileSetupDraft(
    step: step ?? _step,
    values: {
      ..._choices,
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
    },
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final key in _textKeys) {
      _fields[key] = TextEditingController()..addListener(_changed);
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final field in _fields.values) {
      field.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_loading && !_busy && !_finished) unawaited(_persist());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final state = await _service.load(editing: widget.editing);
      if (!mounted) return;
      _applying = true;
      for (final key in _textKeys) {
        _fields[key]!.text = state.draft[key];
      }
      _choices = Map.of(state.draft.values);
      _baseline = state.baseline;
      _step = state.draft.step;
      _applying = false;
      setState(() {
        _loading = false;
        _error = null;
        _submitted = false;
        _returnToReview = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Your saved details could not be loaded. Retry to continue.';
        });
      }
    }
  }

  void _changed() {
    if (_loading || _applying || _busy || _finished) return;
    setState(() {});
    unawaited(_persist());
  }

  Future<void> _persist({int? page}) {
    if (_loading || _finished || _baseline.isEmpty) return Future.value();
    final draft = _draft(step: page);
    final baseline = _baseline;
    _writes = _writes
        .then((_) async {
          if (_finished) return;
          await _service.saveDraft(
            draft,
            baseline: baseline,
            editing: widget.editing,
          );
          _draftFailed = false;
        })
        .catchError((Object error) {
          _draftFailed = true;
          if (mounted && !_finished) {
            setState(
              () => _error =
                  'Your draft could not be saved. Your inputs are still here. Continue to retry.',
            );
          }
        });
    return _writes;
  }

  void _choose(String key, String? value) {
    if (_busy) return;
    _choices[key] = value ?? '';
    _changed();
  }

  String _number(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  void _weightUnit(String? unit) {
    if (unit == null || unit == _draft().weightUnit) return;
    final old = _draft();
    _applying = true;
    for (final entry in {
      'weight': old.weightKg,
      'target_weight': old.targetKg,
    }.entries) {
      if (entry.value != null) {
        _fields[entry.key]!.text = _number(
          unit == 'lb' ? Units.kgToLb(entry.value!) : entry.value!,
        );
      }
    }
    _choices['weight_unit'] = unit;
    _applying = false;
    _changed();
  }

  void _heightUnit(String? unit) {
    if (unit == null || unit == _draft().heightUnit) return;
    final cm = _draft().heightCm;
    _applying = true;
    if (cm != null) {
      _fields['height_cm']!.text = _number(cm);
      final split = Units.cmToFeetInches(cm);
      _fields['height_ft']!.text = '${split.feet}';
      _fields['height_in']!.text = _number(split.inches);
    }
    _choices['height_unit'] = unit;
    _applying = false;
    _changed();
  }

  String? get _direction {
    final d = _draft();
    if (d.weightKg == null || d.targetKg == null) {
      return _choices['goal_intent'];
    }
    final delta = d.targetKg! - d.weightKg!;
    return delta.abs() < .5
        ? 'maintain'
        : delta < 0
        ? 'lose'
        : 'gain';
  }

  void _goal(String? value) {
    if (value == null) return;
    final d = _draft();
    _applying = true;
    _choices['goal_intent'] = value;
    if (value == 'maintain') {
      _fields['target_weight']!.text = _fields['weight']!.text;
    } else if (d.weightKg != null &&
        d.targetKg != null &&
        ((value == 'lose' && d.targetKg! >= d.weightKg!) ||
            (value == 'gain' && d.targetKg! <= d.weightKg!))) {
      _fields['target_weight']!.clear();
    }
    _applying = false;
    _changed();
  }

  Future<void> _move(int page, {bool returnToReview = false}) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    await _persist(page: page);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!_draftFailed) {
        _step = page;
        _submitted = false;
        _error = null;
        _returnToReview = returnToReview;
      }
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _back() async {
    if (_busy) return;
    if (_returnToReview) {
      await _move(4);
      return;
    }
    if (widget.editing && _step == 4) {
      await _persist();
      if (!mounted) return;
      setState(() => _allowExit = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (_step > 0) {
      await _move(_step - 1);
      return;
    }
    await _persist();
    if (mounted) await SystemNavigator.pop();
  }

  Future<void> _next() async {
    if (_busy || _finished) return;
    setState(() => _submitted = true);
    if (_step == 4) {
      await _finish();
      return;
    }
    if (_draft().errorsAt(_step).isNotEmpty) return;
    if (_step < 4) {
      await _move(_returnToReview ? 4 : _step + 1);
      return;
    }
  }

  Future<void> _finish() async {
    final draft = _draft();
    final errors = draft.errors;
    if (errors.isNotEmpty) {
      final page = List.generate(
        4,
        (i) => i,
      ).firstWhere((i) => draft.errorsAt(i).isNotEmpty);
      await _move(page, returnToReview: true);
      if (mounted) setState(() => _submitted = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await _writes;
      await _service.complete(
        draft,
        expectedBaseline: _baseline,
        editing: widget.editing,
      );
      DisplayUnits.weightUnit.value = draft.weightUnit;
      if (!mounted) return;
      _finished = true;
      _allowExit = true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Your profile could not be saved. Your details are still here. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_finished && mounted) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) widget.onCompleted();
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final confirmed = await showNvDestructiveDialog(
      context: context,
      title: 'Restore backup?',
      body:
          'A validated backup replaces any data already on this device, including this setup draft.',
      confirmLabel: 'Choose backup',
    );
    if (!confirmed || !mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await _writes;
      final result =
          await (widget.restoreBackup?.call() ??
              BackupService.instance.pickAndImport());
      if (!mounted) return;
      if (!result.ok) {
        if (result.message != 'Import cancelled.') {
          setState(() => _error = result.message);
        }
        return;
      }
      await DisplayUnits.load();
      await ThemeController.instance.load();
      try {
        await (widget.refreshReminders?.call() ??
            NotificationService.instance.rescheduleAll());
      } catch (_) {
        /* Settings exposes reminder recovery after restore. */
      }
      final state = await _service.load();
      if (!mounted) return;
      if (!state.needsSetup) {
        _finished = true;
        widget.onCompleted();
      } else {
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Backup could not be restored. Your setup details are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _input(
    String key,
    String label, {
    String? errorKey,
    bool decimal = false,
  }) => NvField(
    controller: _fields[key]!,
    label: label,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    errorText: _submitted ? _draft().errors[errorKey ?? key] : null,
  );
  Widget _errorFor(String key) => _submitted && _draft().errors.containsKey(key)
      ? Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _draft().errors[key]!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        )
      : const SizedBox.shrink();
  Widget _intro(String title, String body, IconData icon, LockoutShape shape) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NvIconBadge(
            icon: icon,
            shape: shape,
            size: 72,
            tone: _step.isEven ? NvTone.primary : NvTone.secondary,
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 28),
        ],
      );
  Widget _about() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _intro(
        'Make it yours',
        'A few details to build your starting plan. Everything stays on your device.',
        Icons.person_outline_rounded,
        LockoutShape.flower,
      ),
      _input('age', 'Age (years)'),
      const SizedBox(height: 24),
      Text(
        'Sex for calorie estimates',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      NvSegmentedButton<String?>(
        segments: const [
          NvSegment(value: 'male', label: 'Male'),
          NvSegment(value: 'female', label: 'Female'),
        ],
        selected: _choices['sex']?.isEmpty ?? true ? null : _choices['sex'],
        onChanged: (v) => _choose('sex', v),
      ),
      _errorFor('sex'),
      const SizedBox(height: 12),
      const Text('Used by the calorie equation. You can edit this later.'),
    ],
  );
  Widget _measurements() {
    final d = _draft();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          'Your starting point',
          'Log your current weight and height together.',
          Icons.monitor_weight_outlined,
          LockoutShape.pentagon,
        ),
        Text('Current weight', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        NvSegmentedButton<String>(
          segments: const [
            NvSegment(value: 'kg', label: 'kg'),
            NvSegment(value: 'lb', label: 'lb'),
          ],
          selected: d.weightUnit,
          onChanged: _weightUnit,
        ),
        const SizedBox(height: 12),
        _input('weight', 'Weight (${d.weightUnit})', decimal: true),
        const NvHeading('Height'),
        NvSegmentedButton<String>(
          segments: const [
            NvSegment(value: 'cm', label: 'cm'),
            NvSegment(value: 'ft', label: 'ft / in'),
          ],
          selected: d.heightUnit,
          onChanged: _heightUnit,
        ),
        const SizedBox(height: 12),
        if (d.heightUnit == 'cm')
          _input('height_cm', 'Height (cm)', errorKey: 'height', decimal: true)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _input('height_ft', 'Height (ft)', errorKey: 'height'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _input(
                  'height_in',
                  'Height (in)',
                  errorKey: 'height',
                  decimal: true,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Text(
          widget.editing
              ? 'A changed weight adds a measurement without rewriting your history.'
              : 'This becomes your first measurement when you finish setup.',
        ),
      ],
    );
  }

  Widget _goalPage() {
    final d = _draft();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          'Where do you want to go?',
          'Choose a target and a timeframe that work for you.',
          Icons.track_changes_rounded,
          LockoutShape.clover4Leaf,
        ),
        NvSegmentedButton<String?>(
          segments: const [
            NvSegment(value: 'lose', label: 'Lose'),
            NvSegment(value: 'maintain', label: 'Maintain'),
            NvSegment(value: 'gain', label: 'Gain'),
          ],
          selected: _direction,
          onChanged: _goal,
        ),
        const SizedBox(height: 20),
        _input(
          'target_weight',
          'Target weight (${d.weightUnit})',
          decimal: true,
        ),
        const SizedBox(height: 16),
        _input('weeks', 'Timeframe (weeks)'),
        const SizedBox(height: 20),
        NvSurface(
          tone: NvTone.tertiary,
          child: Text('Starting weight: ${d['weight']} ${d.weightUnit}'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your estimates will explain if the requested pace needs adjusting.',
        ),
      ],
    );
  }

  Widget _activity() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _intro(
        'Fit your real life',
        'Your usual activity helps estimate your starting targets.',
        Icons.directions_walk_rounded,
        LockoutShape.arch,
      ),
      NvGroupedList(
        children: [
          for (final level in ActivityLevel.values)
            NvListItem(
              title: level.label,
              supporting: level.blurb,
              leading: NvIconBadge(
                icon: _choices['activity'] == level.name
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                shape: LockoutShape.gem,
                tone: _choices['activity'] == level.name
                    ? NvTone.primary
                    : NvTone.secondary,
              ),
              onTap: () => _choose('activity', level.name),
            ),
        ],
      ),
      _errorFor('activity'),
      const NvHeading('Training days per week'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NvShapeButton(
            icon: Icons.remove_rounded,
            label: 'Fewer training days',
            onPressed: () => _adjustDays(-1),
          ),
          const SizedBox(width: 12),
          Expanded(child: _input('days', 'Days')),
          const SizedBox(width: 12),
          NvShapeButton(
            icon: Icons.add_rounded,
            label: 'More training days',
            onPressed: () => _adjustDays(1),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text('You can build your routine after setup.'),
    ],
  );
  void _adjustDays(int delta) {
    final now = int.tryParse(_fields['days']!.text) ?? 0;
    _fields['days']!.text = '${(now + delta).clamp(1, 7)}';
  }

  Widget _review() {
    final d = _draft();
    final age = d['age'];
    final sex = d['sex'] == 'female'
        ? 'Female'
        : d['sex'] == 'male'
        ? 'Male'
        : 'Not set';
    final height = d.heightCm;
    final level = ActivityLevel.values
        .where((v) => v.name == d['activity'])
        .firstOrNull;
    Widget editRow(String title, String value, int page) => NvListItem(
      title: title,
      supporting: value,
      trailing: NvButton(
        variant: NvButtonVariant.text,
        label: 'Edit',
        onPressed: () => _move(page, returnToReview: true),
      ),
      onTap: () => _move(page, returnToReview: true),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          'Review your details',
          'Confirm your starting point before we save it.',
          Icons.check_rounded,
          LockoutShape.achievement,
        ),
        const NvHeading('About you'),
        NvGroupedList(
          children: [
            editRow('Age and sex', '$age years · $sex', 0),
            editRow(
              'Current measurements',
              '${d['weight']} ${d.weightUnit} · ${height == null ? 'Not set' : Units.formatHeight(height, d.heightUnit)}',
              1,
            ),
          ],
        ),
        const NvHeading('Your goal'),
        NvGroupedList(
          children: [
            editRow(
              'Target weight',
              '${d['target_weight']} ${d.weightUnit}',
              2,
            ),
            editRow('Timeframe', '${d['weeks']} weeks', 2),
          ],
        ),
        const NvHeading('Your activity'),
        NvGroupedList(
          children: [
            editRow(
              level?.label ?? 'Choose your activity',
              '${d['days']} training days per week',
              3,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Saved only on this device. You can edit these details later in Profile.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const NvPage(
        title: 'Your profile',
        children: [
          Text('Loading your details…'),
          SizedBox(height: 20),
          NvWavyProgress(value: 0),
        ],
      );
    }
    if (_baseline.isEmpty) {
      return NvPage(
        title: 'Your profile',
        children: [
          NvEmpty(
            title: 'Could not load your details',
            message: _error ?? 'Retry to continue.',
            icon: Icons.error_outline_rounded,
            action: 'Retry',
            onPressed: _load,
          ),
        ],
      );
    }
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: NvSetupHeader(step: _step + 1),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: AbsorbPointer(
                    absorbing: _busy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        switch (_step) {
                          0 => _about(),
                          1 => _measurements(),
                          2 => _goalPage(),
                          3 => _activity(),
                          _ => _review(),
                        },
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          NvButton(
                            variant: NvButtonVariant.text,
                            label: 'Reload saved details',
                            onPressed: _busy ? null : _load,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_busy) ...[
                      const NvWavyProgress(value: 0),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (_step > 0 || widget.editing) ...[
                          Expanded(
                            flex: 2,
                            child: NvButton(
                              variant: NvButtonVariant.tonal,
                              label: 'Back',
                              onPressed: _busy ? null : _back,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 3,
                          child: NvButton(
                            variant: NvButtonVariant.filled,
                            label: _step == 4
                                ? (widget.editing
                                      ? 'Save profile'
                                      : 'Finish setup')
                                : (_returnToReview
                                      ? 'Review changes'
                                      : 'Continue'),
                            onPressed: _busy ? null : _next,
                          ),
                        ),
                      ],
                    ),
                    if (_step == 0 && !widget.editing) ...[
                      const SizedBox(height: 10),
                      NvButton(
                        variant: NvButtonVariant.text,
                        label: 'Restore backup',
                        onPressed: _busy ? null : _restore,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
