import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// Section 8's info card: `surfaceContainer`, 28dp corners, 20dp padding.
class NvInfoCard extends StatelessWidget {
  final Widget child;

  const NvInfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LockoutTheme.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(LockoutTheme.radiusCard),
      ),
      child: child,
    );
  }
}

/// Section 8's TBA card: transparent with a 2dp dashed `outlineVariant`
/// border, for whenever the data is not there yet.
///
/// The dashes are painted rather than borrowed from a package — this branch
/// adds no dependency.
class NvTbaCard extends StatelessWidget {
  final String message;

  const NvTbaCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPaint(
      painter: DashedBorderPainter(
        color: theme.colorScheme.outlineVariant,
        radius: LockoutTheme.radiusCard,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(LockoutTheme.screenPadding),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Paints the TBA card's dashed outline.
///
/// Public so `nv_cards_test.dart` can read back the colour and width it was
/// given, rather than asserting that *some* painter exists — which is how a
/// guard ends up certifying nothing.
@visibleForTesting
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
