import 'package:flutter/material.dart';
import '../services/display_units.dart';

import '../services/database_service.dart';
import '../widgets/house/nv_app_navigation.dart';
import '../widgets/house/nv_button.dart';
import '../widgets/house/nv_expressive.dart';
import 'food_tab.dart';
import 'progress_tab.dart';
import 'routines_tab.dart';
import 'settings_screen.dart';
import 'settings_hub.dart';
import 'today_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selected = 'home';
  bool _foodEnabled = true;
  bool _loaded = false;
  bool _workoutActive = false;
  final _today = GlobalKey<TodayTabState>();
  final _training = GlobalKey<RoutinesTabState>();
  final _food = GlobalKey<FoodTabState>();
  final _progress = GlobalKey<ProgressTabState>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await DisplayUnits.load();
    final enabled = await DatabaseService.instance.getSetting(
      'food_tab_enabled',
      defaultValue: 'true',
    );
    if (!mounted) return;
    setState(() {
      _foodEnabled = enabled == 'true';
      if (!_foodEnabled && _selected == 'food') _selected = 'home';
      _loaded = true;
    });
    _refresh();
  }

  void _refresh() {
    switch (_selected) {
      case 'home':
        _today.currentState?.reload();
      case 'workout':
        _training.currentState?.reload();
      case 'progress':
        _progress.currentState?.reload();
      case 'food':
        _food.currentState?.reload();
    }
  }

  void _go(String id, {ProgressSegment? segment}) {
    if (id == 'settings' || id == 'profile') {
      _openSettings();
      return;
    }
    if (id == 'food' && !_foodEnabled) return;
    setState(() => _selected = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
      if (id == 'progress' && segment != null) {
        _progress.currentState?.showSegment(segment);
      }
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsHub(
          onSettingsUpdated: _loadSettings,
          workoutActive: _workoutActive,
        ),
      ),
    );
    if (mounted) await _loadSettings();
  }

  void _startToday() => _today.currentState?.startScheduledSession();

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tabs = NvAppNavigation.visibleTabs(foodTabEnabled: _foodEnabled);
    final index = tabs.indexWhere((t) => t.id == _selected);
    final screens = <Widget>[
      TodayTab(
        key: _today,
        onNavigate: _go,
        onOpenSettings: _openSettings,
        foodTabEnabled: _foodEnabled,
        presentSessionAsRoute: true,
        onSessionChanged: (active) {
          if (mounted) setState(() => _workoutActive = active);
        },
      ),
      RoutinesTab(
        key: _training,
        onStartToday: _startToday,
        onStartDay: (day) => _today.currentState?.startDay(day),
        onOpenSettings: _openSettings,
      ),
      ProgressTab(key: _progress, onOpenSettings: _openSettings),
      if (_foodEnabled) FoodTab(key: _food, onOpenSettings: _openSettings),
    ];
    return PopScope(
      canPop: _selected == 'home' && !_workoutActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selected != 'home') {
          _go('home');
        } else if (_workoutActive) {
          _today.currentState?.resumeSession();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: IndexedStack(
          index: index < 0 ? 0 : index,
          children: [
            for (var i = 0; i < screens.length; i++)
              TickerMode(enabled: i == index, child: screens[i]),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: SettingsBody.importInFlight,
          builder: (context, busy, _) => AbsorbPointer(
            absorbing: busy,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_workoutActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: NvSurface(
                      tone: NvTone.secondary,
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Workout in progress')),
                          NvButton(
                            key: const ValueKey('resume-workout'),
                            variant: NvButtonVariant.filled,
                            label: 'Resume',
                            onPressed: () =>
                                _today.currentState?.resumeSession(),
                          ),
                        ],
                      ),
                    ),
                  ),
                NvAppNavigation(
                  currentIndex: index < 0 ? 0 : index,
                  foodTabEnabled: _foodEnabled,
                  onTap: (i) => _go(tabs[i].id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
