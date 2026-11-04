import 'package:flutter/material.dart';

import '../../theme/lockout_motion.dart';
import 'nv_keyboard_action.dart';

/// One destination of an [NvNavigationBar].
class NvNavigationDestination {
  const NvNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The Material 3 Expressive short navigation bar.
///
/// Bespoke because the framework `NavigationBar` is the stock M3 bar the user
/// rejected (spec section 1, item 3). Four behaviours from spec section 5.4:
/// a 64dp bar on `surfaceContainer` with every label always visible; a 56x32
/// pill indicator that springs between destinations; a press that squashes
/// the pill and recovers on release; and a filled icon with a heavier label
/// for the selected destination. Reduced motion makes the slide and the
/// squash instant.
class NvNavigationBar extends StatefulWidget {
  const NvNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  static const double height = 64;
  static const Size indicatorSize = Size(56, 32);

  // 12dp of the M3 spec does not fit 64dp with a 18dp labelMedium line
  // (12 + 32 + 4 + 18 + 4 = 70), so the top inset is 6.
  static const double _top = 6;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NvNavigationDestination> destinations;

  @override
  State<NvNavigationBar> createState() => _NvNavigationBarState();
}

class _NvNavigationBarState extends State<NvNavigationBar> {
  int? _pressed;
  int? _focused;

  void _setPressed(int? value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final slide = LockoutMotion.springDefault;
    final squash = LockoutMotion.springFast;
    final count = widget.destinations.length;
    final pressedSelected = _pressed == widget.selectedIndex;
    final full = NvNavigationBar.indicatorSize.width;

    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NvNavigationBar.height),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / count;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: slide.durationFor(context),
                    curve: slide.curve,
                    top: NvNavigationBar._top,
                    start: widget.selectedIndex * slot + (slot - full) / 2,
                    width: full,
                    height: NvNavigationBar.indicatorSize.height,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: pressedSelected ? full * 0.85 : full),
                        duration: squash.durationFor(context),
                        curve: squash.curve,
                        builder: (context, width, _) => SizedBox(
                          key: const ValueKey('nv-nav-indicator'),
                          width: width,
                          height: NvNavigationBar.indicatorSize.height,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: colors.secondaryContainer,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(child: _destination(context, i)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int i) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final d = widget.destinations[i];
    final selected = i == widget.selectedIndex;
    return Tooltip(
      message: d.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: d.label,
        onTap: () => widget.onDestinationSelected(i),
        excludeSemantics: true,
        child: NvKeyboardAction(
          onPressed: () => widget.onDestinationSelected(i),
          onFocusChanged: (value) =>
              setState(() => _focused = value ? i : null),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _setPressed(i),
            onPointerUp: (_) => _setPressed(null),
            onPointerCancel: (_) => _setPressed(null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onDestinationSelected(i),
              child: Container(
                padding: const EdgeInsets.only(
                  top: NvNavigationBar._top,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: _focused == i
                      ? Border.all(color: colors.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 32,
                      child: Icon(
                        selected ? d.selectedIcon : d.icon,
                        size: 24,
                        color: selected
                            ? colors.onSecondaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
