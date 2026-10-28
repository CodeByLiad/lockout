import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import 'nv_wavy_progress.dart';

/// The one accent card a screen is allowed, section 8.
///
/// Accent fill, the signature asymmetric outline (36dp on three corners,
/// 12dp bottom-left), 22dp padding, one big number in the `countdown` style
/// with a unit label. It does not morph: a card has no pressed state.
class NvHeroCard extends StatelessWidget {
  final String title;

  /// The one big number. One per screen; the house document is explicit.
  ///
  /// Null when the surface has no count worth that much of the screen — a
  /// rest day spent it on `0`, which says nothing (device QA M1).
  final String? value;

  final String? unit;

  /// The subject-scale element — usually a lobed day marker. The only place
  /// a lobed shape belongs on this card.
  final Widget? marker;

  /// 0..1, or null for a card with nothing in progress.
  final double? progress;

  final List<Widget> actions;

  const NvHeroCard({
    super.key,
    required this.title,
    this.value,
    this.unit,
    this.marker,
    this.progress,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      shape: LockoutTheme.heroCardShape,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(LockoutTheme.heroCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(height: LockoutTheme.spaceSm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                value!,
                                maxLines: 1,
                                style: LockoutTheme.countdown(
                                  colors,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            if (unit != null) ...[
                              const SizedBox(width: LockoutTheme.spaceSm),
                              Text(
                                unit!,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ?marker,
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: LockoutTheme.spaceMd),
              NvWavyProgress(value: progress!),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: LockoutTheme.spaceMd),
              Wrap(
                spacing: LockoutTheme.spaceSm,
                runSpacing: LockoutTheme.spaceSm,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
