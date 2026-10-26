import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lockout_motion.dart';

/// Section 8's wavy linear progress — the only ambient motion in the app.
///
/// The wave drifts on its own. Section 6 stops it entirely when the user has
/// asked the OS to remove animations, which is why the ticker is stopped
/// rather than merely slowed: a wave that still travels under "remove
/// animations" is an accessibility regression, not a flourish.
class NvWavyProgress extends StatefulWidget {
  /// 0..1. A value outside the range is clamped rather than rejected — a
  /// progress bar is not the place to throw.
  final double value;

  const NvWavyProgress({super.key, required this.value});

  @override
  State<NvWavyProgress> createState() => _NvWavyProgressState();
}

class _NvWavyProgressState extends State<NvWavyProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    // The named ambient tier, not a literal: the wave's period is part of
    // the motion vocabulary, and `expressive_contract_test.dart`'s motion
    // rule covers this file.
    duration: LockoutMotion.ambientDrift.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _drift.stop();
      _drift.value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = widget.value.clamp(0.0, 1.0);

    return Semantics(
      value: '${(value * 100).round()}%',
      child: SizedBox(
        height: 12,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: WavePainter(
              progress: value,
              phase: _drift.value,
              track: colors.surfaceContainerHighest,
              wave: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the track and the travelling wave.
///
/// Public only so `nv_wavy_progress_test.dart` can read the phase across a
/// pump and prove the wave moved — or, under reduced motion, that it did not.
@visibleForTesting
class WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color track;
  final Color wave;

  const WavePainter({
    required this.progress,
    required this.phase,
    required this.track,
    required this.wave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;

    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), trackPaint);

    if (progress <= 0) return;

    final wavePaint = Paint()
      ..color = wave
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final filled = size.width * progress;
    final path = Path()..moveTo(0, mid);
    for (var x = 0.0; x <= filled; x += 1) {
      final y =
          mid + math.sin((x / 16) + (phase * 2 * math.pi)) * (size.height / 3);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.track != track ||
      old.wave != wave;
}
