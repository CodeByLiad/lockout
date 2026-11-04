import '../widgets/house/nv_activity_chart.dart';
import 'package:flutter/material.dart';
import '../services/display_units.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../services/goal_service.dart';
import '../theme/lockout_shapes.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../widgets/house/nv_segmented_button.dart';
import '../widgets/house/nv_button.dart';
import 'body_tab.dart';
import 'log_tab.dart';
import 'profile_setup_screen.dart';

enum ProgressSegment { weight, history }

class ProgressTab extends StatefulWidget {
  final ProgressSegment initialSegment;
  final VoidCallback? onOpenSettings;
  const ProgressTab({
    super.key,
    this.initialSegment = ProgressSegment.weight,
    this.onOpenSettings,
  });
  @override
  State<ProgressTab> createState() => ProgressTabState();
}

class ProgressTabState extends State<ProgressTab> {
  List<SessionLog> _logs = [];
  GoalSnapshot? _goal;
  String _range = 'Week';
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final logs = await DatabaseService.instance.getSessionLogs();
    final goal = await GoalService.instance.snapshot();
    if (!mounted) return;
    setState(() {
      _logs = logs.map(SessionLog.fromMap).toList();
      _goal = goal;
      _loaded = true;
    });
  }

  Future<void> showSegment(ProgressSegment segment) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => switch (segment) {
          ProgressSegment.weight => BodyTab(logOnOpen: true),
          ProgressSegment.history => LogTab(),
        },
      ),
    );
    if (mounted) await reload();
  }

  Future<void> _measurements() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BodyTab()));
    if (mounted) await reload();
  }

  Map<String, int> _activityBuckets(
    List<SessionLog> logs,
    DateTime start,
    DateTime today,
  ) {
    final dates = logs
        .map((l) => DateTime.tryParse(l.dateStr))
        .whereType<DateTime>()
        .toList();
    if (_range == 'Week') {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return {
        for (var i = 0; i < 7; i++)
          names[i]: dates.where((d) => d.weekday == i + 1).length,
      };
    }
    if (_range == 'Month') {
      final last = DateTime(today.year, today.month + 1, 0).day;
      return {
        for (var day = 1; day <= last; day += 7)
          '$day–${day + 6 > last ? last : day + 6}': dates
              .where((d) => d.day >= day && d.day < day + 7)
              .length,
      };
    }
    if (dates.isEmpty) return {};
    final earliest = dates.map((d) => d.year).reduce((a, b) => a < b ? a : b);
    return {
      for (var year = earliest; year <= today.year; year++)
        '$year': dates.where((d) => d.year == year).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final today = DateTime.now();
    final start = _range == 'Week'
        ? DateTime(
            today.year,
            today.month,
            today.day,
          ).subtract(Duration(days: today.weekday - 1))
        : _range == 'Month'
        ? DateTime(today.year, today.month, 1)
        : DateTime(1900);
    final logs = _logs
        .where(
          (l) =>
              l.status == 'completed' &&
              !(DateTime.tryParse(l.dateStr) ?? DateTime(1900)).isBefore(start),
        )
        .toList();
    final volume = logs.fold<double>(
      0,
      (sum, l) => sum + (l.totalVolumeKg.isFinite ? l.totalVolumeKg : 0),
    );
    final minutes =
        logs.fold<int>(0, (sum, l) => sum + l.durationSeconds) ~/ 60;
    final weight = _goal?.currentWeightKg;
    return NvPage(
      title: 'Progress',
      actions: [
        NvShapeButton(
          key: const ValueKey('open-settings'),
          icon: Icons.settings_outlined,
          label: 'Settings',
          onPressed: widget.onOpenSettings,
        ),
      ],
      children: [
        NvSegmentedButton<String>(
          segments: const [
            NvSegment(value: 'Week', label: 'Week'),
            NvSegment(value: 'Month', label: 'Month'),
            NvSegment(value: 'All time', label: 'All time'),
          ],
          selected: _range,
          onChanged: (v) => setState(() => _range = v),
        ),
        const SizedBox(height: 20),
        NvSurface(
          tone: NvTone.primary,
          radius: 36,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your training',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                '${logs.length} ${logs.length == 1 ? 'workout' : 'workouts'}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 20),
              NvActivityChart(
                buckets: _activityBuckets(logs, start, today),
                caption: _range == 'Week'
                    ? 'Workouts by day'
                    : _range == 'Month'
                    ? 'Workouts by week'
                    : 'Workouts by year',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NvMetric(
                label: 'Total volume',
                value: DisplayUnits.format(context, volume, decimals: 0),
                tone: NvTone.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NvMetric(
                label: 'Training time',
                value: '$minutes min',
                tone: NvTone.tertiary,
              ),
            ),
          ],
        ),
        const NvHeading('Body weight'),
        NvSurface(
          tone: NvTone.tertiary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weight == null
                    ? 'Your first measurement'
                    : DisplayUnits.format(context, weight),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              NvTrend(
                values: (_goal?.bodyLogs ?? []).reversed
                    .map((r) => BodyEntry.fromMap(r).weightKg)
                    .toList(),
              ),
              const SizedBox(height: 16),
              NvButton(
                variant: NvButtonVariant.filled,
                label: 'Weigh in',
                icon: Icons.add_rounded,
                onPressed: () => showSegment(ProgressSegment.weight),
              ),
            ],
          ),
        ),
        const NvHeading('Explore your progress'),
        NvGroupedList(
          children: [
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.history_rounded,
                shape: LockoutShape.arch,
              ),
              title: 'Workout history',
              supporting: 'Your completed sessions and sets',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showSegment(ProgressSegment.history),
            ),
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.monitor_weight_outlined,
                shape: LockoutShape.pentagon,
                tone: NvTone.secondary,
              ),
              title: 'Measurements',
              supporting: 'Body weight and waist history',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _measurements,
            ),
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.flag_outlined,
                shape: LockoutShape.diamond,
                tone: NvTone.tertiary,
              ),
              title: 'Profile & goals',
              supporting: 'Your targets and personal plan',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (pageContext) => ProfileSetupScreen(editing:true,onCompleted:()=>Navigator.of(pageContext).pop()),
                  ),
                );
                if (mounted) await reload();
              },
            ),
          ],
        ),
      ],
    );
  }
}
