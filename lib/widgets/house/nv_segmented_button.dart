import 'package:flutter/material.dart';
import '../../theme/lockout_motion.dart';
import '../../theme/lockout_theme.dart';
import 'nv_keyboard_action.dart';

@immutable
class NvSegment<T> {
  final T value;
  final String label;
  const NvSegment({required this.value, required this.label});
}

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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final vertical =
          MediaQuery.textScalerOf(context).scale(15) > 20 &&
          segments.length >= 3;
      Widget segment(int i) => _NvSegmentControl(
        label: segments[i].label,
        selected: segments[i].value == selected,
        first: i == 0,
        last: i == segments.length - 1,
        vertical: vertical,
        onPressed: () => onChanged(segments[i].value),
      );
      if (vertical) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              segment(i),
              if (i != segments.length - 1)
                const SizedBox(height: LockoutTheme.groupGap),
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            Expanded(child: segment(i)),
            if (i != segments.length - 1)
              const SizedBox(width: LockoutTheme.groupGap),
          ],
        ],
      );
    },
  );
}

class _NvSegmentControl extends StatefulWidget {
  final String label;
  final bool selected, first, last, vertical;
  final VoidCallback onPressed;
  const _NvSegmentControl({
    required this.label,
    required this.selected,
    required this.first,
    required this.last,
    required this.vertical,
    required this.onPressed,
  });
  @override
  State<_NvSegmentControl> createState() => _NvSegmentControlState();
}

class _NvSegmentControlState extends State<_NvSegmentControl> {
  bool pressed = false;
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final active = pressed || focused;
    final inner = Radius.circular(
      active ? 16 : LockoutTheme.radiusSegmentInner,
    );
    final end = Radius.circular(active ? 16 : LockoutTheme.radiusSegmentEnd);
    final radius = widget.selected && !active
        ? BorderRadius.circular(LockoutTheme.radiusChipActive)
        : widget.vertical
        ? BorderRadius.circular(active ? 24 : 12)
        : BorderRadius.only(
            topLeft: widget.first ? end : inner,
            bottomLeft: widget.first ? end : inner,
            topRight: widget.last ? end : inner,
            bottomRight: widget.last ? end : inner,
          );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: NvKeyboardAction(
        onPressed: widget.onPressed,
        onFocusChanged: (v) => setState(() => focused = v),
        child: GestureDetector(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => pressed = true),
          onTapUp: (_) => setState(() => pressed = false),
          onTapCancel: () => setState(() => pressed = false),
          child: AnimatedContainer(
            duration: LockoutMotion.springFast.durationFor(context),
            curve: LockoutMotion.springFast.curve,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.selected
                  ? c.secondaryContainer
                  : c.surfaceContainer,
              borderRadius: radius,
              border: focused ? Border.all(color: c.primary, width: 2) : null,
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.labelLarge?.copyWith(
                color: widget.selected
                    ? c.onSecondaryContainer
                    : c.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
