import 'package:flutter/material.dart';

import '../../theme/lockout_motion.dart';
import '../../theme/lockout_theme.dart';

/// One option in an [NvSegmentedButton].
@immutable
class NvSegment<T> {
  final T value;
  final String label;

  const NvSegment({required this.value, required this.label});
}

/// Section 5.2's segmented control: inner segments 8dp, outer ends 22dp, the
/// selected segment a full pill.
///
/// Bespoke rather than a themed `SegmentedButton`, which hardcodes each
/// segment's shape in `segmentStyleFor` and resolves the group style with
/// `selected` permanently set — so none of the three shapes is reachable
/// from a theme. That was deviation D9; this retires it.
class NvSegmentedButton<T> extends StatelessWidget {
  final List<NvSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const NvSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tier = LockoutMotion.springFast;
    final duration = tier.durationFor(context);

    return Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: segments[i].value == selected,
              label: segments[i].label,
              child: GestureDetector(
                onTap: () => onChanged(segments[i].value),
                child: AnimatedContainer(
                  duration: duration,
                  curve: tier.curve,
                  height: LockoutTheme.minTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: segments[i].value == selected
                        ? colors.secondaryContainer
                        : colors.surfaceContainer,
                    borderRadius: _radiusFor(i),
                  ),
                  child: Text(
                    segments[i].label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: segments[i].value == selected
                          ? colors.onSecondaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i != segments.length - 1)
            const SizedBox(width: LockoutTheme.groupGap),
        ],
      ],
    );
  }

  /// A selected segment is a pill on every corner. Otherwise the group's two
  /// ends carry 22dp on their outer side and 8dp inside, and everything
  /// between them is 8dp all round.
  BorderRadius _radiusFor(int index) {
    if (segments[index].value == selected) {
      return BorderRadius.circular(LockoutTheme.radiusChipActive);
    }

    const end = Radius.circular(LockoutTheme.radiusSegmentEnd);
    const inner = Radius.circular(LockoutTheme.radiusSegmentInner);
    final first = index == 0;
    final last = index == segments.length - 1;

    return BorderRadius.only(
      topLeft: first ? end : inner,
      bottomLeft: first ? end : inner,
      topRight: last ? end : inner,
      bottomRight: last ? end : inner,
    );
  }
}
