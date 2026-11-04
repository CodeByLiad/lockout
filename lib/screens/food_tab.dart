import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/lockout_shapes.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_food_picker.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_wavy_progress.dart';
import '../widgets/house/nv_feedback.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/numeric_guard.dart';
import '../services/goal_service.dart';

class FoodTab extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  FoodTab({super.key, this.onOpenSettings});

  @override
  State<FoodTab> createState() => FoodTabState();
}

class FoodTabState extends State<FoodTab> {
  static const List<String> mealSlots = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  List<FoodEntry> _foodLogs = [];
  int _targetKcal = DatabaseService.defaultCalorieTarget;
  bool _isLoading = true;
  DateTime _date = DateTime.now();
  String? _loadError;
  int _loadRevision = 0;
  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Called by MainScreen when this tab becomes visible again.
  Future<void> reload() => _loadData();

  Future<void> _loadData() async {
    final revision = ++_loadRevision;
    try {
    final db = DatabaseService.instance;
    final dateToday = _dateKey;
    final rows = await db.getFoodLogsForDate(dateToday);
    // Resolved through GoalService — the single place Ruling A's "plan
    // value first, then the manual override, then the default" order lives
    // — so this can never disagree with what HOME shows for the same day.
    final snapshot = await GoalService.instance.snapshot();

    if (!mounted || revision != _loadRevision) return;
    setState(() {
      _foodLogs = rows.map(FoodEntry.fromMap).toList();
      _targetKcal = snapshot.calorieTarget;
      _isLoading = false;
      _loadError = null;
    });
    } catch (_) {
      if (!mounted || revision != _loadRevision) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Food could not be loaded. Please try again.';
      });
    }
  }

  int get _totalKcal => _foodLogs.fold(0, (sum, item) => sum + item.kcal);
  double get _totalProtein => _foodLogs.fold(0.0, (s, i) => s + i.proteinG);
  double get _totalCarb => _foodLogs.fold(0.0, (s, i) => s + i.carbG);
  double get _totalFat => _foodLogs.fold(0.0, (s, i) => s + i.fatG);

  /// Meal slot suggested from the clock, so the common case needs no tap.
  String get _defaultSlot {
    final h = DateTime.now().hour;
    if (h < 11) return 'Breakfast';
    if (h < 16) return 'Lunch';
    if (h < 21) return 'Dinner';
    return 'Snacks';
  }

  /// Catalog picker first, then a confirm sheet with everything prefilled and
  /// still editable — a catalog figure is a starting point, not a fact.
  Future<void> _addFood() => _addFoodForSlot(_defaultSlot);

  Future<void> _addFoodForSlot(String slot) async {
    final picked = await showFoodPicker(context);
    if (picked == null || !mounted) return;
    final saved = await showNvEditor<bool>(
      context: context,
      title: 'Log food',
      builder: (_) =>
          _LogMealForm(picked: picked, defaultSlot: slot, date: _dateKey),
    );
    if (saved == true && mounted) await reload();
  }

  Future<void> _editFood(FoodEntry entry) async {
    final saved = await showNvEditor<bool>(
      context: context,
      title: 'Edit food',
      builder: (_) => _LogMealForm(
        picked: PickedFood(
          name: entry.name,
          kcal: entry.kcal,
          proteinG: entry.proteinG,
          carbG: entry.carbG,
          fatG: entry.fatG,
        ),
        defaultSlot: entry.mealSlot,
        date: entry.dateStr,
        existing: entry,
      ),
    );
    if (saved == true && mounted) await reload();
  }

  /// Same gap Task 9 left BODY's body-log delete with (Finding 3 / Ruling
  /// F): a single tap on a ~36dp target destroys a logged entry with no
  /// confirmation. Deletes immediately, then offers a few seconds to
  /// reverse it through the same `showUndoBanner` BODY uses, rather than a
  /// second, lookalike implementation of the same idea.
  Future<void> _deleteEntry(FoodEntry entry) async {
    await DatabaseService.instance.deleteFoodLog(entry.id);
    if (!mounted) return;
    await reload();
    if (!mounted) return;

    showNvUndo(
      context,
      message: '${entry.name} deleted',
      onUndo: () => _restoreEntry(entry),
    );
  }

  /// Re-inserts [entry] with its original id and every field intact —
  /// `insertFoodLog` uses `ConflictAlgorithm.replace`, so this is a true
  /// restore, not a near-copy with a freshly minted id.
  Future<void> _restoreEntry(FoodEntry entry) async {
    await DatabaseService.instance.insertFoodLog(entry.toMap());
    if (!mounted) return;
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    final date = DateFormat('EEE, d MMM').format(_date);
    final remaining = _targetKcal - _totalKcal;
    final allSlots = [
      ...mealSlots,
      if (_foodLogs.any((f) => !mealSlots.contains(f.mealSlot))) 'Other',
    ];
    return NvPage(
      title: 'Food',
      actions: [
        NvShapeButton(
          key: const ValueKey('open-settings'),
          icon: Icons.settings_outlined,
          label: 'Settings',
          onPressed: widget.onOpenSettings,
        ),
      ],
      footer: NvButton(
        variant: NvButtonVariant.filled,
        label: 'Log food',
        icon: Icons.add_rounded,
        large: true,
        onPressed: _addFood,
      ),
      children: [
        Row(
          children: [
            NvShapeButton(
              key: const ValueKey('previous-food-day'),
              icon: Icons.chevron_left_rounded,
              label: 'Previous day',
              tone: NvTone.secondary,
              onPressed: () {
                setState(() => _date = _date.subtract(const Duration(days: 1)));
                reload();
              },
            ),
            Expanded(
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            NvShapeButton(
              key: const ValueKey('next-food-day'),
              icon: Icons.chevron_right_rounded,
              label: 'Next day',
              tone: NvTone.tertiary,
              onPressed: () {
                setState(() => _date = _date.add(const Duration(days: 1)));
                reload();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        NvSurface(
          tone: NvTone.secondary,
          radius: 36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_totalKcal',
                          style: theme.textTheme.displayLarge,
                        ),
                        Text(
                          'of $_targetKcal kcal',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const NvIconBadge(
                    icon: Icons.restaurant_rounded,
                    shape: LockoutShape.bun,
                    size: 72,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                remaining >= 0
                    ? '$remaining kcal left'
                    : '${-remaining} kcal over target',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              NvWavyProgress(
                value: _targetKcal <= 0
                    ? 0
                    : (_totalKcal / _targetKcal).clamp(0.0, 1.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            NvMetric(
              label: 'Protein',
              value: '${_num(_totalProtein)} g',
              tone: NvTone.primary,
            ),
            NvMetric(
              label: 'Carbs',
              value: '${_num(_totalCarb)} g',
              tone: NvTone.tertiary,
            ),
            NvMetric(
              label: 'Fat',
              value: '${_num(_totalFat)} g',
              tone: NvTone.secondary,
            ),
          ],
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 16),
          Text(_loadError!),
          NvButton(
            variant: NvButtonVariant.tonal,
            label: 'Try again',
            onPressed: reload,
          ),
        ],
        const NvHeading('Your meals'),
        for (var i = 0; i < allSlots.length; i++) ...[
          Builder(
            builder: (_) {
              final slot = allSlots[i];
              final entries = _foodLogs
                  .where(
                    (f) => slot == 'Other'
                        ? !mealSlots.contains(f.mealSlot)
                        : f.mealSlot == slot,
                  )
                  .toList();
              final kcal = entries.fold<int>(0, (sum, f) => sum + f.kcal);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NvListItem(
                    leading: NvIconBadge(
                      icon: [
                        Icons.wb_twilight_rounded,
                        Icons.wb_sunny_outlined,
                        Icons.nightlight_outlined,
                        Icons.apple_outlined,
                        Icons.restaurant_rounded,
                      ][i % 5],
                      shape: LockoutShape.values[[6, 11, 8, 14, 9][i % 5]],
                      tone: NvTone.values[i % 3],
                    ),
                    title: slot,
                    supporting: entries.isEmpty
                        ? 'Nothing logged yet'
                        : '$kcal kcal',
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () => _addFoodForSlot(slot),
                  ),
                  if (entries.isNotEmpty)
                    NvGroupedList(
                      children: [
                        for (final entry in entries)
                          NvListItem(
                            title: entry.name,
                            supporting:
                                '${entry.kcal} kcal · ${_num(entry.proteinG)} g protein',
                            trailing: NvShapeButton(
                              icon: Icons.close_rounded,
                              label: 'Delete ${entry.name}',
                              tone: NvTone.surface,
                              onPressed: () => _deleteEntry(entry),
                            ),
                            onTap: () => _editFood(entry),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

/// One decimal place, trimmed to a whole number when exact. Library-level
/// rather than a method on [FoodTabState] — [_LogMealFormState] is an
/// unrelated widget's `State` and had no business reaching into that one.
String _num(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

// --- FORM WIDGET ---
//
// Owns its own controllers/state as a `StatefulWidget` rather than a builder
// closure fed hoisted `TextEditingController`s — see the doc block at
// routines_tab.dart:807-827 for why: `showLockoutSheet`'s `builder` is
// re-invoked on every drag-driven rebuild of the sheet's own state, so a
// controller created inside the builder gets silently recreated (losing
// typed input), and a controller hoisted into the calling method and
// disposed in a `finally` around the awaited sheet Future gets disposed
// ~200ms before the sheet's exit animation finishes removing it from the
// tree, producing a use-after-dispose. Tying the controllers' lifecycle to
// `State.dispose()` avoids both.
class _LogMealForm extends StatefulWidget {
  final PickedFood picked;
  final String defaultSlot;
  final String date;
  final FoodEntry? existing;

  const _LogMealForm({
    required this.picked,
    required this.defaultSlot,
    required this.date,
    this.existing,
  });

  @override
  State<_LogMealForm> createState() => _LogMealFormState();
}

class _LogMealFormState extends State<_LogMealForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbCtrl;
  late final TextEditingController _fatCtrl;
  late String _slot;
  bool _saving = false;
  double _servings = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.picked.name);
    _kcalCtrl = TextEditingController(text: widget.picked.kcal.toString());
    _proteinCtrl = TextEditingController(text: _num(widget.picked.proteinG));
    _carbCtrl = TextEditingController(text: _num(widget.picked.carbG));
    _fatCtrl = TextEditingController(text: _num(widget.picked.fatG));
    _slot = widget.defaultSlot;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final kcal = int.tryParse(_kcalCtrl.text);
    final protein = NumericGuard.parse(_proteinCtrl.text, min: 0);
    final carb = NumericGuard.parse(_carbCtrl.text, min: 0);
    final fat = NumericGuard.parse(_fatCtrl.text, min: 0);
    if (_nameCtrl.text.trim().isEmpty ||
        kcal == null ||
        kcal < 0 ||
        protein == null ||
        carb == null ||
        fat == null) {
      setState(
        () => _error =
            'Enter a food name and valid, non-negative nutrition values.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DatabaseService.instance.insertFoodLog(
        FoodEntry(
          id:
              widget.existing?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          dateStr: widget.date,
          mealSlot: _slot,
          name: _nameCtrl.text.trim(),
          kcal: kcal,
          proteinG: protein,
          carbG: carb,
          fatG: fat,
        ).toMap(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Food not saved. Your changes are still here. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void changeServing(double next) {
      if (next < .25) return;
      setState(() {
        _servings = next;
        _kcalCtrl.text = (widget.picked.kcal * next).round().toString();
        _proteinCtrl.text = _num(widget.picked.proteinG * next);
        _carbCtrl.text = _num(widget.picked.carbG * next);
        _fatCtrl.text = _num(widget.picked.fatG * next);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const NvIconBadge(
              icon: Icons.restaurant_rounded,
              shape: LockoutShape.bun,
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.picked.name,
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        if (widget.picked.ingredients.isNotEmpty) ...[
          const NvHeading('Ingredients assumed'),
          NvSurface(
            tone: NvTone.secondary,
            child: Text(widget.picked.ingredients),
          ),
        ],
        if (widget.existing == null && widget.picked.kcal > 0) ...[
          const NvHeading('Serving size'),
          Text(widget.picked.serving, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          NvSurface(
            tone: NvTone.primary,
            child: Row(
              children: [
                NvShapeButton(
                  icon: Icons.remove_rounded,
                  label: 'Fewer servings',
                  onPressed: () => changeServing(_servings - .25),
                  tone: NvTone.surface,
                ),
                Expanded(
                  child: Text(
                    '${_num(_servings)} servings',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                NvShapeButton(
                  icon: Icons.add_rounded,
                  label: 'More servings',
                  onPressed: () => changeServing(_servings + .25),
                  tone: NvTone.surface,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        NvField(label: 'Food name', controller: _nameCtrl),
        const SizedBox(height: 16),
        NvField(
          label: 'Calories (kcal)',
          controller: _kcalCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        NvField(
          label: 'Protein (g)',
          controller: _proteinCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        NvField(
          label: 'Carbs (g)',
          controller: _carbCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        NvField(
          label: 'Fat (g)',
          controller: _fatCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const NvHeading('Meal'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in FoodTabState.mealSlots)
              ChoiceChip(
                label: Text(slot),
                selected: _slot == slot,
                onSelected: (_) => setState(() => _slot = slot),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 24),
        NvButton(
          variant: NvButtonVariant.filled,
          label: _saving ? 'Saving…' : 'Save food',
          large: true,
          onPressed: _saving ? null : _save,
        ),
        const SizedBox(height: 12),
        const Text('Adjust values to match your portion.'),
      ],
    );
  }
}
