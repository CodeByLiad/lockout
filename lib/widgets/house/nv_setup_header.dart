import 'package:flutter/material.dart';
import '../../theme/lockout_motion.dart';

/// The real five-step setup progress, with one concise spoken announcement.
class NvSetupHeader extends StatelessWidget {
  final int step;
  const NvSetupHeader({super.key, required this.step});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Image.asset(
              'assets/branding/exports/monochrome/192.png',
              width: 32,
              height: 32,
              color: theme.colorScheme.primary,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Lockout', style: theme.textTheme.headlineSmall),
            ),
            ExcludeSemantics(
              child: Text('$step of 5', style: theme.textTheme.labelLarge),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Step $step of 5',
          child: Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: LockoutMotion.effects.durationFor(context),
                    curve: LockoutMotion.effects.curve,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < step
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
