import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/lockout_motion.dart';

/// Counts real completed workouts; zero periods never receive sample bars.
class NvActivityChart extends StatelessWidget {
  final Map<String, int> buckets;
  final String caption;
  const NvActivityChart({
    super.key,
    required this.buckets,
    required this.caption,
  });
  @override
  Widget build(BuildContext context) {
    final maximum = buckets.values.fold<int>(0, math.max);
    if (maximum == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No workouts in this period'),
      );
    }
    final color = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(
                constraints.maxWidth,
                buckets.length * MediaQuery.textScalerOf(context).scale(12) * 3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in buckets.entries)
                    Expanded(
                      child: Semantics(
                        label:
                            '${bucket.key}, ${bucket.value} ${bucket.value == 1 ? 'workout' : 'workouts'}',
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Text(
                                  '${bucket.value}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 76,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration: LockoutMotion.effects
                                          .durationFor(context),
                                      curve: LockoutMotion.effects.curve,
                                      height: bucket.value == 0
                                          ? 2
                                          : 72 * bucket.value / maximum,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        color: bucket.value == 0
                                            ? color.outlineVariant
                                            : color.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  bucket.key,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
