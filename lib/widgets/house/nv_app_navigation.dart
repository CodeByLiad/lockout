import 'package:flutter/material.dart';

import 'nv_navigation_bar.dart';

/// One nav destination, enum-keyed.
///
/// `MainScreen._screenFor` switches on this with a Dart switch *expression*,
/// which the compiler rejects if a case is missing — so a tab added here
/// without a matching branch there is a compile error, not the runtime
/// `StateError` a `String`-keyed switch could only catch with a remembered
/// `default`.
enum NavTab { home, workout, progress, food, profile }

class NavTabDef {
  final NavTab tab;

  /// The id `TodayTab.onNavigate(String tabId)` and `MainScreen._goToTab` use
  /// — a public string contract, kept alongside [tab] rather than derived
  /// from its `.name`, so renaming an enum member can never silently change
  /// that contract.
  final String id;
  final String label;

  /// Outlined when inactive, filled when active: the M3 convention that
  /// carries selection without relying on colour alone.
  final IconData icon;
  final IconData selectedIcon;

  const NavTabDef({
    required this.tab,
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class NvAppNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool foodTabEnabled;

  // Non-const constructor: see "Why some constructors in this app are
  // not const" at the top of lib/widgets/day_block.dart.
  // ignore: prefer_const_constructors_in_immutables
  NvAppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.foodTabEnabled = true,
  });

  static const List<NavTabDef> _allTabs = [
    NavTabDef(
      tab: NavTab.home,
      id: 'home',
      label: 'Today',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    NavTabDef(
      tab: NavTab.workout,
      id: 'workout',
      label: 'Training',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    NavTabDef(
      tab: NavTab.progress,
      id: 'progress',
      label: 'Progress',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    NavTabDef(
      tab: NavTab.food,
      id: 'food',
      label: 'Food',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
    ),
  ];

  /// The ordered, currently-visible tabs. `MainScreen` derives both its screen
  /// list and its id list from this so they cannot drift out of sync with what
  /// the bar actually renders.
  static List<NavTabDef> visibleTabs({bool foodTabEnabled = true}) =>
      _allTabs.where((t) => t.id != 'food' || foodTabEnabled).toList();

  /// The most recently *measured* rendered height of a live `NvAppNavigation`,
  /// including its own bottom safe-area inset — `0.0` until one has laid out
  /// at least once (there is no bar to clear yet, e.g. in a widget test that
  /// pumps a tab on its own). `showUndoBanner` (`lib/widgets/undo_banner.dart`)
  /// reads this so its `Positioned(bottom: ...)` clears the bar instead of
  /// sitting on top of it for the whole 5s undo window. A measured value
  /// rather than a guessed constant so it cannot fall short on an unusual
  /// font-scale or device inset, and cannot overshoot where no bar exists.
  static final ValueNotifier<double> lastRenderedHeight = ValueNotifier<double>(
    0.0,
  );

  @override
  State<NvAppNavigation> createState() => _NvAppNavigationState();
}

class _NvAppNavigationState extends State<NvAppNavigation> {
  final _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_reportHeight);
  }

  @override
  void didUpdateWidget(covariant NvAppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_reportHeight);
  }

  void _reportHeight(Duration _) {
    final height = _barKey.currentContext?.size?.height;
    if (height != null && height != NvAppNavigation.lastRenderedHeight.value) {
      NvAppNavigation.lastRenderedHeight.value = height;
    }
  }

  // Resets so a tab pumped standalone *after* a bar has come and gone in the
  // same test process sees the documented 0.0 rather than a stale inset.
  // MainScreen is `home:` in this app and never unmounts, so this does not
  // fire in production.
  @override
  void dispose() {
    NvAppNavigation.lastRenderedHeight.value = 0.0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = NvAppNavigation.visibleTabs(
      foodTabEnabled: widget.foodTabEnabled,
    );

    // Clamped rather than asserted: hiding the Food tab shortens this list
    // while `MainScreen` still holds the old index for one frame, and a
    // RangeError there would take down the whole app over a transient.
    final index = widget.currentIndex.clamp(0, tabs.length - 1);

    return NvNavigationBar(
      key: _barKey,
      selectedIndex: index,
      onDestinationSelected: widget.onTap,
      destinations: [
        for (final tab in tabs)
          NvNavigationDestination(
            icon: tab.icon,
            selectedIcon: tab.selectedIcon,
            label: tab.label,
          ),
      ],
    );
  }
}
