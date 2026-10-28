import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import 'nv_button.dart';

/// Section 8's empty state: a `surfaceContainer` block with 32dp corners, a
/// short headline, one sentence saying what to do, and one button that does
/// it.
///
/// Empty is an invitation to act, not a sad face.
class NvEmptyState extends StatelessWidget {
  final String headline;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  const NvEmptyState({
    super.key,
    required this.headline,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LockoutTheme.spaceLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(headline, style: theme.textTheme.headlineMedium),
          const SizedBox(height: LockoutTheme.spaceSm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LockoutTheme.spaceMd),
          NvButton(
            variant: NvButtonVariant.tonal,
            label: actionLabel,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
