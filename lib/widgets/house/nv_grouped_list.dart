import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import '../connected_group.dart';
import '../morphing_surface.dart';

/// A column of rows that reads as one object, section 5.2.
///
/// The corner arithmetic — 26dp outer, 8dp inner, 3dp gaps — already lives in
/// `ConnectedGroup`. This is the house-named entry point, so a rebuilt screen
/// never reaches past the catalog for it.
class NvGroupedList extends StatelessWidget {
  final List<Widget> children;

  const NvGroupedList({super.key, required this.children});

  @override
  Widget build(BuildContext context) => ConnectedGroup(children: children);
}

/// One row of a grouped list, section 8.
///
/// At least 72dp tall, `surfaceContainer` fill, 16dp padding, an optional
/// leading tile, a title, optional supporting text, an optional trailing
/// badge or control. Pressing it rounds the row from 8dp to 20dp.
class NvListItem extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? supporting;
  final Widget? trailing;

  /// Null makes the row inert — and, because shape is a state, a row with no
  /// press state does not morph.
  final VoidCallback? onTap;

  const NvListItem({
    super.key,
    this.leading,
    required this.title,
    this.supporting,
    this.trailing,
    this.onTap,
  });

  @override
  State<NvListItem> createState() => _NvListItemState();
}

class _NvListItemState extends State<NvListItem> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: _enabled,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: MorphingSurface(
          restRadius: LockoutTheme.radiusRowRest,
          activeRadius: LockoutTheme.radiusRowActive,
          active: _pressed,
          color: colors.surfaceContainer,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(LockoutTheme.cardPadding),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: LockoutTheme.spaceMd),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleMedium),
                      if (widget.supporting != null) ...[
                        const SizedBox(height: LockoutTheme.spaceXs),
                        Text(
                          widget.supporting!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: LockoutTheme.spaceMd),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
