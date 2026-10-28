import 'package:flutter/material.dart';

import '../../theme/lockout_semantics.dart';
import '../../theme/lockout_theme.dart';

/// The four status badges section 8 puts on the right of a list row.
enum NvBadgeKind {
  /// Imminent, live, or in progress.
  accent,

  /// Finished.
  done,

  /// Not known yet.
  unknown,

  /// Everything else.
  neutral,
}

/// A small status marker for the trailing slot of a grouped-list row.
class NvStatusBadge extends StatelessWidget {
  final String label;
  final NvBadgeKind kind;

  const NvStatusBadge({super.key, required this.label, required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantics = LockoutSemantics.of(context);

    final (Color fill, Color ink, BoxBorder? border) = switch (kind) {
      NvBadgeKind.accent => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
          null,
        ),
      // Section 8 names `successContainer` here. Lockout's semantics
      // extension carries `success`/`onSuccess` and no container pair, and
      // the token layer is not this branch's to extend, so the pair it has
      // stands in — the same role, one shade stronger.
      NvBadgeKind.done => (semantics.success, semantics.onSuccess, null),
      NvBadgeKind.unknown => (
          colors.outline.withValues(alpha: 0),
          colors.onSurfaceVariant,
          Border.all(color: colors.outline, width: 1.5),
        ),
      NvBadgeKind.neutral => (
          colors.surfaceContainerHigh,
          colors.onSurfaceVariant,
          null,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LockoutTheme.spaceSm,
        vertical: LockoutTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: BorderRadius.circular(LockoutTheme.radiusChipRest),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: ink),
      ),
    );
  }
}
