import 'package:flutter/material.dart';
import 'about_screen.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/goal_service.dart';
import '../services/notification_service.dart';
import '../services/numeric_guard.dart';
import '../services/nutrition_planner.dart';
import '../services/units.dart';
import '../theme/accents.dart';
import '../theme/cookie_border.dart';
import '../theme/lockout_motion.dart';
import '../theme/lockout_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_dialog.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_segmented_button.dart';
import '../widgets/house/nv_sheet.dart';
import '../widgets/house/nv_status_badge.dart';
import '../widgets/house/nv_switch.dart';
import '../widgets/house/nv_text_field.dart';

/// The settings content, independent of how it is presented.
///
/// Split from its route so the Profile tab can host the same body without an
/// `AppBar`: a tab has nothing to pop back to, and a tab that grew its own bar
/// would sit a bar taller than its neighbours.
class SettingsBody extends StatefulWidget {
  final VoidCallback onSettingsUpdated;

  /// False when hosted as the Profile tab, where the surrounding screen owns
  /// the title and there is no route to pop.
  final bool showAppBar;

  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  SettingsBody({
    super.key,
    required this.onSettingsUpdated,
    this.showAppBar = true,
  });

  @override
  State<SettingsBody> createState() => SettingsBodyState();
}

/// The pushed-route form of settings.
///
/// Kept so anything that still navigates to a settings page - a notification
/// tap, a deep link, an older test - lands somewhere with a back button, even
/// though the primary entry point is now the Profile tab.
class SettingsScreen extends StatelessWidget {
  final VoidCallback onSettingsUpdated;

  // ignore: prefer_const_constructors_in_immutables
  SettingsScreen({super.key, required this.onSettingsUpdated});

  @override
  Widget build(BuildContext context) =>
      SettingsBody(onSettingsUpdated: onSettingsUpdated, showAppBar: true);
}

class SettingsBodyState extends State<SettingsBody> {
  final _heightCmCtrl = TextEditingController();
  final _heightFtCtrl = TextEditingController();
  final _heightInCtrl = TextEditingController();
  final _calorieCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _weeksCtrl = TextEditingController();

  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  int _daysPerWeek = 4;
  NutritionPlan? _plan;

  bool _foodTabEnabled = true;
  bool _remindersEnabled = false;
  bool _streakAlertsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);

  /// 'cm' or 'ft' — controls which height inputs are shown.
  String _heightUnit = 'cm';

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _heightCmCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();
    _calorieCtrl.dispose();
    _ageCtrl.dispose();
    _targetWeightCtrl.dispose();
    _weeksCtrl.dispose();
    super.dispose();
  }

  /// Re-reads every setting. Public so `ProfileTab` can refresh the hosted
  /// body the same way the other tabs are refreshed on the way in.
  Future<void> reload() => _loadSettings();

  Future<void> _loadSettings() async {
    final db = DatabaseService.instance;
    final c = await db.getSetting(
      'calorie_target',
      defaultValue: '${DatabaseService.defaultCalorieTarget}',
    );
    final f = await db.getSetting('food_tab_enabled', defaultValue: 'true');
    final u = await db.getSetting('height_unit', defaultValue: 'cm');
    final rEnabled =
        await db.getSetting('reminders_enabled', defaultValue: 'false');
    final rHour = await db.getSetting('reminder_hour', defaultValue: '18');
    final rMin = await db.getSetting('reminder_minute', defaultValue: '0');
    final sAlerts =
        await db.getSetting('streak_alerts_enabled', defaultValue: 'true');

    final goal = await GoalService.instance.loadProfile();
    final snap = await GoalService.instance.snapshot();

    // Height comes from the profile, not a second raw read of the same row:
    // `GoalService.loadProfile` is where `height_cm` is clamped, and
    // `Units.cmToFeetInches` does `totalInches ~/ 12.0`, which throws
    // `Unsupported operation: Infinity or NaN toInt` on a non-finite value.
    // Parsing the row again here reintroduced exactly that throw — inside
    // `_loadSettings`, ahead of its `setState`, so a backup carrying
    // `height_cm = 'Infinity'` (import writes `user_settings` verbatim) left
    // Settings with every field empty and no plan, and took the reschedule,
    // the `onSettingsUpdated` callback and the "Import complete" toast in
    // `_import` down with it.
    final cm = goal.heightCm;
    final split = Units.cmToFeetInches(cm);

    if (!mounted) return;
    setState(() {
      _heightCmCtrl.text = cm.toStringAsFixed(cm % 1 == 0 ? 0 : 1);
      _heightFtCtrl.text = split.feet.toString();
      _heightInCtrl.text =
          split.inches.toStringAsFixed(split.inches % 1 == 0 ? 0 : 1);
      _calorieCtrl.text = c;
      _foodTabEnabled = f == 'true';
      _heightUnit = u == 'ft' ? 'ft' : 'cm';
      _remindersEnabled = rEnabled == 'true';
      _streakAlertsEnabled = sAlerts == 'true';
      _reminderTime = TimeOfDay(
        hour: int.tryParse(rHour) ?? 18,
        minute: int.tryParse(rMin) ?? 0,
      );

      _ageCtrl.text = goal.age > 0 ? goal.age.toString() : '';
      _targetWeightCtrl.text =
          goal.targetWeightKg > 0 ? goal.targetWeightKg.toString() : '';
      _weeksCtrl.text = goal.weeks.toString();
      _sex = goal.sex;
      _activity = goal.activity;
      _daysPerWeek = goal.daysPerWeek;
      _plan = snap.nutrition;
    });
  }

  /// Persists the training-days stepper the instant it changes.
  ///
  /// The Training card has no save button of its own — before this, its two
  /// controls lived nowhere near a writer, so `_daysPerWeek` only ever
  /// reached `training_days_per_week` if the user also opened the Food card
  /// and pressed "Calculate my target". `MainScreen` calls `reload()` on
  /// every tab switch, and `reload()` re-reads the database, so a stepper tap
  /// followed by switching tabs silently reverted with no feedback. Written
  /// directly rather than routed through `_saveGoalAndRecalculate`: that
  /// method also recalculates and reports a new calorie target, which is the
  /// Food card's action, not this one, and `training_days_per_week` does not
  /// feed the nutrition calculation at all (it only feeds the training
  /// recommendation `GoalService.snapshot()` derives on the fly, which is
  /// never persisted). A direct write here is the same shape
  /// `_saveHeightSettings` already takes for `height_cm` — a setting saved
  /// from more than one place in this file — and it matches the pattern this
  /// card's own reminder toggles already use: persist on change, no button.
  Future<void> _setDaysPerWeek(int days) async {
    setState(() => _daysPerWeek = days);
    await DatabaseService.instance
        .saveSetting('training_days_per_week', days.toString());
  }

  /// Persists the activity-level radio the instant it changes. See
  /// [_setDaysPerWeek] for why this is a direct write rather than a route
  /// through `_saveGoalAndRecalculate`.
  Future<void> _setActivity(ActivityLevel activity) async {
    setState(() => _activity = activity);
    await DatabaseService.instance.saveSetting('activity_level', activity.name);
    final snap = await GoalService.instance.snapshot();
    if (!mounted) return;
    setState(() => _plan = snap.nutrition);
  }

  /// Persists only the height fields. Split from the food/nutrition save
  /// action below so each grouped card commits what it actually owns.
  Future<void> _saveHeightSettings() async {
    final db = DatabaseService.instance;
    final cm = _resolveHeightCm();
    await db.saveSetting('height_cm', cm.toStringAsFixed(2));
    await db.saveSetting('height_unit', _heightUnit);
    widget.onSettingsUpdated();
    _toast('Saved height ${Units.formatHeight(cm, _heightUnit)}.');
  }

  /// Persists the manual calorie override and the nutrition tab toggle.
  Future<void> _saveFoodSettings() async {
    final db = DatabaseService.instance;
    await db.saveSetting('calorie_target', _calorieCtrl.text);
    await db.saveSetting(
      'food_tab_enabled',
      _foodTabEnabled ? 'true' : 'false',
    );
    widget.onSettingsUpdated();
    _toast('Saved food settings.');
  }

  /// Persists the goal inputs, then recomputes the calorie target from them.
  /// The target is derived, never typed — that is the whole point.
  Future<void> _saveGoalAndRecalculate() async {
    final db = DatabaseService.instance;
    await db.saveSetting('height_cm', _resolveHeightCm().toStringAsFixed(2));
    await db.saveSetting('height_unit', _heightUnit);
    await db.saveSetting('age', _ageCtrl.text.trim());
    await db.saveSetting('sex', _sex.name);
    await db.saveSetting('activity_level', _activity.name);
    await db.saveSetting(
      'target_weight_kg',
      _sanitisedTargetWeightKg(_targetWeightCtrl.text),
    );
    await db.saveSetting('goal_weeks', _weeksCtrl.text.trim());
    await db.saveSetting('training_days_per_week', _daysPerWeek.toString());

    final plan = await GoalService.instance.recalculateAndSaveTarget();
    if (!mounted) return;

    setState(() {
      _plan = plan;
      if (plan != null) _calorieCtrl.text = plan.targetKcal.toString();
    });
    widget.onSettingsUpdated();

    if (plan == null) {
      _toast(
        'Add your age, target weight and one body-weight entry to calculate a target.',
        warn: true,
      );
    } else {
      _toast('Target set to ${plan.targetKcal} kcal/day.');
    }
  }

  /// The target weight as it may be persisted.
  ///
  /// `double.tryParse` accepts 'Infinity', '-Infinity' and 'NaN', so saving
  /// the field's raw text let a non-finite value reach `target_weight_kg`.
  /// `GoalService.loadProfile` parses it back unchanged, which made the BODY
  /// screen's TARGET tile render 'Infinity kg' and poisoned every calculation
  /// downstream of the goal profile. Anything that is not a finite,
  /// non-negative number is stored as '0' — exactly where unparseable text
  /// already lands on read, and the value that leaves `isConfigured` false so
  /// the user is asked for a real target rather than shown a fabricated
  /// plan. The finite/non-negative rule itself is `NumericGuard`'s, shared
  /// with BODY's measurement form and the routine builder's weight field.
  static String _sanitisedTargetWeightKg(String raw) {
    final text = raw.trim();
    return NumericGuard.parse(text, min: 0.0) == null ? '0' : text;
  }

  /// Height in cm from whichever unit the user is currently editing.
  ///
  /// Guarded the same way [_sanitisedTargetWeightKg] is, and for the same
  /// reason: `double.tryParse` accepts 'Infinity' and 'NaN', `Infinity > 0`
  /// is true, and `double.infinity.toStringAsFixed(2)` is the literal string
  /// 'Infinity'. No numeric field here carries `inputFormatters`, so paste or
  /// a letters keyboard reaches this. A non-finite height stored to
  /// `height_cm` made `NutritionPlanner.build` throw `Unsupported operation:
  /// Infinity or NaN toInt` out of `GoalService.snapshot()` — which BODY,
  /// FOOD, TODAY and Settings itself all call, so one typed word bricked four
  /// screens until the row was overwritten. Anything not finite and positive
  /// falls back to the same 175.0 default unparseable text already lands on.
  double _resolveHeightCm() {
    if (_heightUnit == 'ft') {
      final feet = int.tryParse(_heightFtCtrl.text.trim()) ?? 0;
      final inches = NumericGuard.parse(_heightInCtrl.text) ?? 0;
      final cm = Units.feetInchesToCm(feet, inches);
      return _usableHeightCm(cm);
    }
    final cm = NumericGuard.parse(_heightCmCtrl.text) ?? 0;
    return _usableHeightCm(cm);
  }

  static double _usableHeightCm(double cm) =>
      NumericGuard.finite(cm, min: 0.0, minExclusive: true) ?? 175.0;

  /// Keeps the hidden unit's fields in sync so switching units never loses
  /// the value the user just typed.
  void _switchHeightUnit(String unit) {
    final cm = _resolveHeightCm();
    setState(() {
      _heightUnit = unit;
      _heightCmCtrl.text = cm.toStringAsFixed(cm % 1 == 0 ? 0 : 1);
      final split = Units.cmToFeetInches(cm);
      _heightFtCtrl.text = split.feet.toString();
      _heightInCtrl.text =
          split.inches.toStringAsFixed(split.inches % 1 == 0 ? 0 : 1);
    });
  }

  void _toast(String message, {bool warn = false}) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: warn ? colors.errorContainer : colors.inverseSurface,
        content: Text(
          message,
          style: TextStyle(
            color: warn ? colors.onErrorContainer : colors.onInverseSurface,
          ),
        ),
      ),
    );
  }

  // --- THEME ---

  // Two handlers rather than one, because the picker is two independent
  // axes: a brightness tap must not disturb the accent, and vice versa.
  // Each persists through `ThemeController`; a throw there (storage
  // failure) must not vanish as a silent, unhandled async error — surface
  // it the same way every other write on this screen does.
  //
  // The `setState` is not redundant with the controller's own notification:
  // this body reads `ThemeController.instance` directly rather than through
  // a `ListenableBuilder`, so without it the segmented button and the
  // swatches would keep painting the previous selection until something
  // else rebuilt the screen.

  Future<void> _applyBrightness(LockoutBrightnessChoice choice) async {
    try {
      await ThemeController.instance.selectBrightness(choice);
    } catch (_) {
      _toast('Could not apply the theme.', warn: true);
    }
    if (mounted) setState(() {});
  }

  Future<void> _applyAccent(LockoutAccent accent) async {
    try {
      await ThemeController.instance.selectAccent(accent);
    } catch (_) {
      _toast('Could not apply the accent.', warn: true);
    }
    if (mounted) setState(() {});
  }

  // --- REMINDERS ---

  Future<void> _toggleReminders(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        _toast('Notification permission denied in system settings.', warn: true);
        return;
      }
    }

    await DatabaseService.instance
        .saveSetting('reminders_enabled', value ? 'true' : 'false');
    if (!mounted) return;
    setState(() => _remindersEnabled = value);

    await NotificationService.instance.rescheduleAll();
    _toast(value ? 'Reminders scheduled.' : 'Reminders switched off.');
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null || !mounted) return;

    setState(() => _reminderTime = picked);
    final db = DatabaseService.instance;
    await db.saveSetting('reminder_hour', picked.hour.toString());
    await db.saveSetting('reminder_minute', picked.minute.toString());
    await NotificationService.instance.rescheduleAll();

    if (!mounted) return;
    _toast('Reminder set for ${picked.format(context)}.');
  }

  Future<void> _toggleStreakAlerts(bool value) async {
    await DatabaseService.instance
        .saveSetting('streak_alerts_enabled', value ? 'true' : 'false');
    if (!mounted) return;
    setState(() => _streakAlertsEnabled = value);
    await NotificationService.instance.rescheduleAll();
  }

  // --- BACKUP ---

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await BackupService.instance.exportAndShare();
    } catch (e) {
      _toast('Export failed: $e', warn: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    // Routed through the house destructive dialog (section 8: a dialog is
    // allowed for one thing only, a destructive confirmation). The trigger
    // that opens it is a neutral `NvButtonVariant.outlined` — "Neutral
    // alternatives" per the design doc's button table — so the `danger` ink
    // lives only on this confirmation, not on the button that merely offers
    // it.
    final confirmed = await showNvDestructiveDialog(
      context: context,
      title: 'Replace all data?',
      body: 'Importing a backup deletes every routine, workout, meal and '
          'body entry currently on this device and replaces them with the '
          'file\'s contents. This cannot be undone — export a backup first '
          'if you are not sure.',
      confirmLabel: 'Choose file',
    );

    if (!confirmed) return;

    setState(() => _busy = true);
    final result = await BackupService.instance.pickAndImport();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.ok) {
      _toast(result.message, warn: true);
      return;
    }

    // Restored settings include the theme, so re-read everything.
    // `load()` rather than a read-then-select pair: it is the one place that
    // knows both axes and the legacy formats, and an imported backup can
    // carry a `theme_key` written by any older build.
    await ThemeController.instance.load();
    if (!mounted) return;

    // A belt, and deliberately kept as one now that both braces hold:
    // `BackupService` coerces numeric columns on import, and every read on
    // the far side of this `await` goes through `NumericGuard` rather than
    // a cast, so nothing arriving through an import can still throw here.
    // What that leaves is an unenumerable class — any future failure in
    // `_loadSettings`, from a schema the running build does not know to a
    // disk error — and the consequence has not changed: unguarded, the
    // throw takes the reschedule, the callback and the toast with it, so
    // the import applies while the OS keeps the pre-restore reminder
    // schedule and the user is told nothing.
    // Re-reading settings is best-effort; everything after it is not.
    var reloaded = true;
    try {
      await _loadSettings();
    } catch (_) {
      reloaded = false;
    }
    await NotificationService.instance.rescheduleAll();
    widget.onSettingsUpdated();

    if (!mounted) return;
    // Two different things can be worth warning about, and they are
    // independent. `reloaded` is the belt above failing — rare, and now
    // unreachable from an import. `coercedValues` is the common one: the
    // restore succeeded by rewriting cells it could not read as `0`, and
    // saying only "Import complete" there reports a silent edit of the
    // user's own data as an unqualified success.
    final rewritten = result.coercedValues > 0;
    _toast(
      reloaded
          ? 'Import complete. ${result.rowsRestored} rows restored.'
              '${ImportResult.coercionNote(result.coercedValues)}'
          : 'Import complete. ${result.rowsRestored} rows restored, but some '
              'of them could not be read back. Check the backup file.',
      warn: !reloaded || rewritten,
    );
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Null when hosted as the Profile tab: that screen owns the title, and
      // a pushed route is the only presentation with something to pop back to.
      appBar: widget.showAppBar ? AppBar(title: const Text('Settings')) : null,
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          // Padding rather than a `SafeArea`: this route has an `AppBar` but
          // no `bottomNavigationBar`, so on an edge-to-edge window the list
          // runs to the physical bottom of the screen and the nav bar inset
          // cannot be cleared by a fixed padding alone. The tab screens
          // escape this only because `BottomNav` carries its own `SafeArea`.
          // Padding keeps content scrolling UNDER the bar, which a `SafeArea`
          // would stop, while still letting the user scroll the last line
          // clear of it.
          //
          // `paddingOf`, not `viewPaddingOf`: `resizeToAvoidBottomInset` has
          // already shortened this body when the keyboard is up, and
          // `viewPadding` ignores insets, so it would reserve another chunk
          // of dead space above the keyboard. `padding.bottom` collapses to 0
          // in exactly that case.
          padding: EdgeInsets.fromLTRB(
            LockoutTheme.screenPadding,
            LockoutTheme.spaceMd,
            LockoutTheme.screenPadding,
            LockoutTheme.spaceMd + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: LockoutTheme.sectionGap),
              _buildAppearanceCard(context),
              _buildUnitsCard(context),
              _buildTrainingCard(context),
              _buildFoodCard(context),
              _buildNotificationsCard(context),
              _buildDataCard(context),
              _buildAboutSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// The frame every section shares: a sentence-case heading, the rows that
  /// are genuinely rows inside an [NvGroupedList], and anything else — a
  /// field, a calculated summary, the section's own save button — below the
  /// group but still inside the section's frame.
  ///
  /// Replaces the old `LockoutCard` wrapper and the all-caps
  /// `_sectionCaption` this screen used to call ahead of every card: a
  /// grouped list reads as one object on its own, so the section no longer
  /// needs a bounding card to say the same thing twice.
  Widget _section(
    BuildContext context, {
    required String heading,
    required List<Widget> rows,
    List<Widget> extras = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LockoutTheme.screenPadding,
          ),
          child: Text(heading, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: LockoutTheme.headingGap),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LockoutTheme.cardPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rows.isNotEmpty) NvGroupedList(children: rows),
              if (extras.isNotEmpty) ...[
                const SizedBox(height: LockoutTheme.spaceMd),
                ...extras,
              ],
            ],
          ),
        ),
        const SizedBox(height: LockoutTheme.sectionGap),
      ],
    );
  }

  /// Section 12.2's header: a large cookie avatar and the app name.
  ///
  /// The house spec also asks for a name, an email and a Pro badge, but this
  /// app has no account and no Pro tier (deviation D2) — there is nothing
  /// for either to say, so inventing one would be fiction rather than data.
  /// The 12-lobe register is section 5.3's "Profile avatar (large)".
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: colors.secondaryContainer,
            shape: const CookieBorder(lobes: 12, amplitude: 0.04),
          ),
          child: Icon(
            Icons.fitness_center,
            size: 32,
            color: colors.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: LockoutTheme.spaceMd),
        Text('Lockout', style: theme.textTheme.headlineSmall),
      ],
    );
  }

  /// The appearance picker: two independent axes, nothing else.
  ///
  /// Brightness is a segmented button rather than a switch because "system"
  /// is a real third choice, not the absence of the other two. Accent is a
  /// row of swatches with no text beside them — the colour *is* the label,
  /// and each swatch carries its name in semantics so a screen reader is
  /// not left reading five identical buttons.
  Widget _buildAppearanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ThemeController.instance;

    return _section(
      context,
      heading: 'Look and feel',
      rows: const [],
      extras: [
        Text('Applies instantly.', style: theme.textTheme.bodySmall),
        const SizedBox(height: LockoutTheme.headingGap),
        NvSegmentedButton<LockoutBrightnessChoice>(
          segments: const [
            NvSegment(
              value: LockoutBrightnessChoice.system,
              label: 'System',
            ),
            NvSegment(
              value: LockoutBrightnessChoice.light,
              label: 'Light',
            ),
            NvSegment(
              value: LockoutBrightnessChoice.dark,
              label: 'Dark',
            ),
          ],
          selected: controller.brightnessChoice,
          onChanged: _applyBrightness,
        ),
        const SizedBox(height: LockoutTheme.sectionGap),
        Text('Accent', style: theme.textTheme.titleLarge),
        const SizedBox(height: LockoutTheme.headingGap),
        // A `Wrap`, not a `Row`: five 48dp targets plus their gaps clear
        // 360dp only just, and a device at a large display scale has less
        // room than that. Wrapping onto a second line is the one failure
        // mode here that is not an overflow stripe.
        Wrap(
          spacing: LockoutTheme.spaceSm,
          runSpacing: LockoutTheme.spaceSm,
          children: [
            for (final accent in LockoutAccent.all)
              _AccentSwatch(
                accent: accent,
                selected: controller.accent == accent,
                onTap: () => _applyAccent(accent),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitsCard(BuildContext context) {
    return _section(
      context,
      heading: 'Units',
      rows: const [],
      extras: [
        NvSegmentedButton<String>(
          segments: const [
            NvSegment(value: 'cm', label: 'Centimetres'),
            NvSegment(value: 'ft', label: 'Feet / inches'),
          ],
          selected: _heightUnit,
          onChanged: _switchHeightUnit,
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        if (_heightUnit == 'ft')
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NvTextField(
                  label: 'Height (ft)',
                  controller: _heightFtCtrl,
                  hintText: '5',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: LockoutTheme.spaceSm),
              Expanded(
                child: NvTextField(
                  label: 'Height (in)',
                  controller: _heightInCtrl,
                  hintText: '9',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          )
        else
          NvTextField(
            label: 'Height (cm)',
            controller: _heightCmCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvButton(
          variant: NvButtonVariant.filled,
          label: 'Save height',
          onPressed: _saveHeightSettings,
        ),
      ],
    );
  }

  Widget _buildTrainingCard(BuildContext context) {
    final theme = Theme.of(context);

    return _section(
      context,
      heading: 'Training',
      rows: [
        NvListItem(
          title: 'Days per week',
          supporting: '$_daysPerWeek',
          onTap: () => _openDaysPerWeekSheet(context),
        ),
        for (final a in ActivityLevel.values)
          NvListItem(
            title: a.label,
            supporting: a.blurb,
            onTap: () => _setActivity(a),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('x${a.multiplier}', style: theme.textTheme.labelMedium),
                if (a == _activity) ...[
                  const SizedBox(height: LockoutTheme.spaceXs),
                  const NvStatusBadge(
                    label: 'Selected',
                    kind: NvBadgeKind.accent,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// The "Days per week" stepper, opened from its row rather than drawn
  /// inline — section 8 prefers a sheet for a choice over a row that grows
  /// its own controls.
  Future<void> _openDaysPerWeekSheet(BuildContext context) {
    return showNvSheet<void>(
      context: context,
      title: 'Days per week',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _daysPerWeek > 2
                  ? () {
                      _setDaysPerWeek(_daysPerWeek - 1);
                      setSheetState(() {});
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: LockoutTheme.minTouchTarget,
                minHeight: LockoutTheme.minTouchTarget,
              ),
            ),
            const SizedBox(width: LockoutTheme.spaceMd),
            Text('$_daysPerWeek', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: LockoutTheme.spaceMd),
            IconButton(
              onPressed: _daysPerWeek < 6
                  ? () {
                      _setDaysPerWeek(_daysPerWeek + 1);
                      setSheetState(() {});
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: LockoutTheme.minTouchTarget,
                minHeight: LockoutTheme.minTouchTarget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _plan;

    return _section(
      context,
      heading: 'Food',
      rows: [
        NvSwitchRow(
          title: 'Enable nutrition tab',
          value: _foodTabEnabled,
          onChanged: (val) => setState(() => _foodTabEnabled = val),
        ),
      ],
      extras: [
        Text(
          'Calories are calculated from these, not guessed — BMR by the '
          'Mifflin-St Jeor equation, then activity, then the deficit or '
          'surplus your goal needs.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: NvTextField(
                label: 'Age',
                controller: _ageCtrl,
                hintText: '28',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: LockoutTheme.spaceSm),
            Expanded(
              child: NvTextField(
                label: 'Target weight (kg)',
                controller: _targetWeightCtrl,
                hintText: '72',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvSegmentedButton<Sex>(
          segments: const [
            NvSegment(value: Sex.male, label: 'Male'),
            NvSegment(value: Sex.female, label: 'Female'),
          ],
          selected: _sex,
          onChanged: (sex) => setState(() => _sex = sex),
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvTextField(
          label: 'Timeframe (weeks)',
          controller: _weeksCtrl,
          hintText: '12',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        // The section's primary action — the one filled button section 8
        // allows per section. "Save food settings" below is the second
        // action this section needs, so it takes the tonal variant instead.
        NvButton(
          variant: NvButtonVariant.filled,
          label: 'Calculate my target',
          onPressed: _saveGoalAndRecalculate,
        ),
        if (plan != null) ...[
          const SizedBox(height: LockoutTheme.spaceMd),
          Container(
            padding: const EdgeInsets.all(LockoutTheme.cardPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(LockoutTheme.radiusCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily target',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                    NvStatusBadge(
                      label: plan.directionLabel,
                      kind: NvBadgeKind.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: LockoutTheme.spaceXs),
                Text(
                  '${plan.targetKcal} kcal',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: LockoutTheme.spaceSm),
                Text(
                  'BMR ${plan.bmr.round()} -> TDEE ${plan.tdee.round()} -> '
                  '${plan.dailyDeltaKcal >= 0 ? '+' : ''}${plan.dailyDeltaKcal} kcal/day',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: LockoutTheme.spaceXs),
                Text(
                  'P ${plan.proteinG}g  ·  C ${plan.carbG}g  ·  F ${plan.fatG}g',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (plan.warning != null) ...[
            const SizedBox(height: LockoutTheme.spaceSm),
            Container(
              padding: const EdgeInsets.all(LockoutTheme.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
              ),
              child: Text(
                plan.warning!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ],
        const Divider(height: LockoutTheme.sectionGap),
        NvTextField(
          label: 'Daily calorie target (kcal)',
          controller: _calorieCtrl,
          keyboardType: TextInputType.number,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: LockoutTheme.spaceSm),
          child: Text(
            'Set automatically by "Calculate my target" above. Override it '
            'here only if you already know what you are doing.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        NvButton(
          variant: NvButtonVariant.tonal,
          label: 'Save food settings',
          onPressed: _saveFoodSettings,
        ),
      ],
    );
  }

  Widget _buildNotificationsCard(BuildContext context) {
    return _section(
      context,
      heading: 'Notifications',
      rows: [
        NvSwitchRow(
          title: 'Daily training nudge',
          supporting: 'Scheduled on this device. Nothing is sent anywhere.',
          value: _remindersEnabled,
          onChanged: _toggleReminders,
        ),
        if (_remindersEnabled) ...[
          NvListItem(
            title: 'Reminder time',
            supporting: _reminderTime.format(context),
            onTap: _pickReminderTime,
          ),
          NvSwitchRow(
            title: 'Streak warning at 21:00',
            value: _streakAlertsEnabled,
            onChanged: _toggleStreakAlerts,
          ),
        ],
      ],
      extras: _remindersEnabled
          ? [
              NvButton(
                variant: NvButtonVariant.tonal,
                label: 'Send test notification',
                onPressed: () async {
                  await NotificationService.instance.showTestNotification();
                  _toast('Test notification sent.');
                },
              ),
            ]
          : const [],
    );
  }

  Widget _buildDataCard(BuildContext context) {
    final theme = Theme.of(context);

    return _section(
      context,
      heading: 'Data',
      rows: const [],
      extras: [
        Text(
          'Export writes every routine, workout, set, meal, body entry and '
          'setting to a single JSON file. Import replaces everything on this '
          'device with the contents of a backup.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: LockoutTheme.spaceMd),
        NvButton(
          variant: NvButtonVariant.filled,
          label: _busy ? 'Working…' : 'Export backup JSON',
          onPressed: _busy ? null : _export,
        ),
        const SizedBox(height: LockoutTheme.spaceSm),
        // Neutral, not `danger`: this button only offers to replace every
        // row on the device — it does not do it. The destructive ink lives
        // on `showNvDestructiveDialog`'s confirm button inside `_import`,
        // the one control that actually fires the replacement, per the
        // design doc's button table ("Outlined: neutral alternatives" vs.
        // "Danger: Remove, Delete"). Splitting it this way is also what
        // gives `NvButtonVariant.outlined` its one real consumer in the
        // house catalog.
        NvButton(
          key: const Key('importBackupButton'),
          variant: NvButtonVariant.outlined,
          label: _busy ? 'Working…' : 'Import backup JSON',
          onPressed: _busy ? null : _import,
        ),
      ],
    );
  }

  /// The licence, version and data-handling notes used to sit inline here.
  /// Task 10 lifted that body onto its own route — [AboutScreen] — so this
  /// section is now a single row that pushes it.
  ///
  /// It is the FIRST such row in the app: `Icons.chevron_right` appears
  /// nowhere else under `lib/screens/`, and the house catalog has no
  /// navigation-row component yet. Treat this as the thing a second one
  /// should be factored out of, not as an established convention — the
  /// shape it sets is a title, a chevron and a push, nothing more.
  ///
  /// Named a section, not a card: it returns a `_section`, and every
  /// `_buildXCard` sibling around it has been one of these for a while now.
  /// Renaming the rest is out of this task's scope; shipping a fresh one
  /// under the wrong noun is not.
  Widget _buildAboutSection(BuildContext context) {
    return _section(
      context,
      heading: 'About',
      rows: [
        NvListItem(
          title: 'About Lockout',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
          ),
        ),
      ],
    );
  }
}

/// One accent choice.
///
/// The swatch is the one place in the app where the shape language is itself
/// the content, so it wears a lobed outline rather than a rounded rectangle,
/// and the outline is what changes when it is chosen.
///
/// The `Semantics` wrapper is what makes the swatch addressable at all: it
/// draws no text, so without a label a screen reader would announce five
/// identical buttons. `selected` is set on both states rather than only the
/// chosen one, so an unselected swatch reads as "not selected" instead of
/// as something with no selection state to report.
class _AccentSwatch extends StatelessWidget {
  final LockoutAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  /// The swatch at rest and when chosen. Both sit inside
  /// [LockoutTheme.minTouchTarget], so growing one never grows the target
  /// it lives in — the tap area is the same 48dp either way.
  static const double _restDiameter = 34;
  static const double _selectedDiameter = 44;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tier = LockoutMotion.springFast;

    return Semantics(
      label: accent.name,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        // The ripple takes the swatch's own outline. A `CircleBorder` at
        // the 48dp target's radius splashed well outside the 34dp disc it
        // belonged to, which read as the wrong swatch lighting up.
        customBorder: const CookieBorder(
          lobes: 6,
          amplitude: 0.07,
        ),
        child: SizedBox(
          width: LockoutTheme.minTouchTarget,
          height: LockoutTheme.minTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: tier.durationFor(context),
              curve: tier.curve,
              width: selected ? _selectedDiameter : _restDiameter,
              height: selected ? _selectedDiameter : _restDiameter,
              decoration: ShapeDecoration(
                color: accent.accent,
                // The lobe count is held fixed across both states on
                // purpose: `CookieBorder` refuses to interpolate between two
                // counts, so only the amplitude and the outline may animate.
                shape: CookieBorder(
                  lobes: CookieBorder.training.lobes,
                  // Both states carry a visible lobe. Halving the rest
                  // amplitude put peak-to-trough at about 1.1px on a 34dp
                  // disc, so the swatch read as a plain circle until it was
                  // chosen — and the shape language is meant to be the
                  // content here, not the reward for tapping.
                  amplitude: selected
                      ? CookieBorder.training.amplitude * 1.4
                      : CookieBorder.training.amplitude,
                  side: BorderSide(
                    color: selected ? colors.onSurface : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 18, color: accent.ink)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
