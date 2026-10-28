import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/bottom_nav.dart';
import 'food_tab.dart';
import 'profile_tab.dart';
import 'progress_tab.dart';
import 'routines_tab.dart';
import 'settings_screen.dart';
import 'today_tab.dart';

class MainScreen extends StatefulWidget {
  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _foodTabEnabled = true;
  bool _settingsLoaded = false;

  // Tabs live inside an IndexedStack so an in-progress live session survives a
  // trip to another tab. Keys let us refresh a tab on the way back in, since
  // its initState no longer re-runs on every switch.
  final _routinesKey = GlobalKey<RoutinesTabState>();
  final _todayKey = GlobalKey<TodayTabState>();
  final _foodKey = GlobalKey<FoodTabState>();
  final _progressKey = GlobalKey<ProgressTabState>();
  final _profileKey = GlobalKey<ProfileTabState>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabledStr = await DatabaseService.instance
        .getSetting('food_tab_enabled', defaultValue: 'true');
    if (!mounted) return;
    setState(() {
      _foodTabEnabled = enabledStr == 'true';
      _settingsLoaded = true;
    });
    _refreshVisibleTab();
  }

  /// `BottomNav.visibleTabs` is the single source of truth for order and
  /// visibility; `_screens` and `_tabIds` are both derived from it so they
  /// cannot silently drift apart from what the nav bar actually shows.
  List<String> get _tabIds => BottomNav.visibleTabs(foodTabEnabled: _foodTabEnabled)
      .map((t) => t.id)
      .toList();

  List<Widget> get _screens =>
      BottomNav.visibleTabs(foodTabEnabled: _foodTabEnabled)
          .map((t) => _screenFor(t.tab))
          .toList();

  /// A switch *expression* over the `NavTab` enum: the compiler rejects this
  /// if a case is missing, so a tab added to `BottomNav._allTabs` without a
  /// matching branch here is a compile error rather than the runtime
  /// `StateError` a `String`-keyed switch could only catch with a
  /// remembered `default`.
  Widget _screenFor(NavTab tab) => switch (tab) {
        NavTab.home => TodayTab(
            key: _todayKey,
            onNavigate: _goToTab,
            foodTabEnabled: _foodTabEnabled,
          ),
        NavTab.workout => RoutinesTab(
            key: _routinesKey,
            onStartToday: _startTodaySession,
          ),
        NavTab.progress => ProgressTab(key: _progressKey),
        NavTab.food => FoodTab(key: _foodKey),
        NavTab.profile => ProfileTab(
            key: _profileKey,
            onSettingsUpdated: _loadSettings,
          ),
      };

  /// Re-reads the data behind whichever tab is on screen.
  ///
  /// Dispatches over the `NavTab` enum, not over `_tabIds`, for the reason
  /// [_screenFor] already gives: a `String`-keyed switch is not exhaustive,
  /// so a tab added to `BottomNav._allTabs` simply never refreshed — no
  /// `StateError`, no missing screen, just a tab showing stale data for the
  /// life of the session. A switch over the enum is a compile error until
  /// the new tab is handled here too.
  void _refreshVisibleTab() {
    final tabs = BottomNav.visibleTabs(foodTabEnabled: _foodTabEnabled);
    if (_currentIndex >= tabs.length) return;
    switch (tabs[_currentIndex].tab) {
      case NavTab.home:
        _todayKey.currentState?.reload();
      case NavTab.workout:
        _routinesKey.currentState?.reload();
      case NavTab.progress:
        _progressKey.currentState?.reload();
      case NavTab.food:
        _foodKey.currentState?.reload();
      case NavTab.profile:
        _profileKey.currentState?.reload();
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    // Pull fresh data after the frame so the new tab is mounted first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshVisibleTab());
  }

  /// Lets HOME's action grid switch tabs by id. Ids rather than indices,
  /// because hiding the Food tab shifts every index after it.
  ///
  /// [segment] is honoured only for `'progress'`, the one tab with two
  /// destinations behind a single id: Home's "Weigh in" and "History" actions
  /// both land there and must not open the same half. Applied after the frame
  /// so the tab is mounted and its `GlobalKey` resolves.
  void _goToTab(String tabId, {ProgressSegment? segment}) {
    final index = _tabIds.indexOf(tabId);
    if (index < 0) return;
    _onTabTapped(index);
    if (tabId == 'progress' && segment != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _progressKey.currentState?.showSegment(segment),
      );
    }
  }

  /// Starts today's session from the Workout tab's featured-day card.
  ///
  /// The session engine lives in `TodayTab`, so this switches to Home and
  /// hands off rather than keeping a second copy of the start logic. The
  /// post-frame callback is what makes the hand-off safe: the tab must be
  /// mounted before its `GlobalKey` resolves.
  void _startTodaySession() {
    _goToTab('home');
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _todayKey.currentState?.startScheduledSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    if (!_settingsLoaded) {
      return Scaffold(
        backgroundColor: surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _screens;
    if (_currentIndex >= screens.length) _currentIndex = 0;

    // No global AppBar. Each tab owns its own large title, which is what lets
    // Home read as a dashboard rather than a page inside a chrome; settings
    // moved from the old gear icon here into the Profile tab.
    return Scaffold(
      backgroundColor: surface,
      // `IndexedStack` keeps every tab mounted — that is what lets an
      // in-progress live session survive a trip to another tab — but it
      // installs no `TickerMode`, so an off-screen tab's animations keep
      // running: measured, an unselected child's `NvWavyProgress` advanced
      // its wave phase 0.0067 -> 0.2567 over 600ms with a transient frame
      // callback still registered. A workout is the longest screen-on period
      // this app has, and that is where the cost lands. Muting here rather
      // than inside any one widget covers every animation a tab grows later.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < screens.length; i++)
            TickerMode(enabled: i == _currentIndex, child: screens[i]),
        ],
      ),
      // The nav is locked for the one operation that replaces the database
      // under every other tab. `SettingsBody`'s own `AbsorbPointer` cannot
      // reach this far: it wraps the body it owns, and this bar is that
      // body's sibling. See `SettingsBody.importInFlight`.
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: SettingsBody.importInFlight,
        builder: (_, importing, child) =>
            AbsorbPointer(absorbing: importing, child: child),
        child: BottomNav(
          currentIndex: _currentIndex,
          foodTabEnabled: _foodTabEnabled,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
