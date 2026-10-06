import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A polar-rose outline — a circle whose radius rises and falls a fixed
/// number of times around its sweep.
///
/// A `ShapeBorder` rather than a `CustomPainter` so it composes with
/// everything that already takes a shape: `Material`, `ShapeDecoration`,
/// `Card`, `FilledButton`. Pure geometry, which is why
/// `cookie_border_test.dart` can assert it without pumping a widget.
///
/// Lobe count is a *register*, not decoration: 4 rest, 6 training, 9 streak,
/// 12 achievement. That mapping is Lockout's extension of the house system
/// (deviation register D5), and it is why [lerpFrom] refuses to interpolate
/// between two different counts — a shape halfway between "rest" and
/// "streak" means nothing.
@immutable
class CookieBorder extends ShapeBorder {
  /// How many times the radius peaks around the sweep.
  final int lobes;

  /// How far the radius departs from the base circle, as a fraction of it.
  /// 0.07 means the outline runs between 93% and 107% of the base radius.
  final double amplitude;

  final BorderSide side;

  const CookieBorder({
    required this.lobes,
    required this.amplitude,
    this.side = BorderSide.none,
  })  : assert(lobes >= 3, 'fewer than three lobes is not a rose'),
        assert(amplitude >= 0 && amplitude < 1,
            'amplitude is a fraction of the base radius');

  /// A rest day.
  static const CookieBorder rest = CookieBorder(lobes: 4, amplitude: 0.10);

  /// A training day.
  static const CookieBorder training =
      CookieBorder(lobes: 6, amplitude: 0.07);

  /// A streak.
  static const CookieBorder streak = CookieBorder(lobes: 9, amplitude: 0.06);

  /// A completed session.
  static const CookieBorder achievement =
      CookieBorder(lobes: 12, amplitude: 0.04);

  /// Enough samples that a 12-lobed outline still reads as smooth; below
  /// about 12 points per lobe the straight segments become visible at hero
  /// sizes.
  static const int _samplesPerLobe = 24;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final centre = rect.center;

    // The base radius is derived from half the SHORTEST side, so an oblong
    // rect yields a shape that still fits inside it rather than one that
    // spills along the long axis. Dividing by (1 + amplitude) puts the LOBE
    // PEAKS — not the base circle — on the rect's inscribed circle, so the
    // outer path never paints outside the rect it was given. Every shape in
    // the Material set behaves that way, and anything that clips to the
    // shape (Material, InkWell splashes, shadows) depends on it.
    final base = rect.shortestSide / 2 / (1 + amplitude);
    final steps = lobes * _samplesPerLobe;
    final path = Path();

    for (var i = 0; i < steps; i++) {
      final angle = 2 * math.pi * i / steps;
      final radius = base * (1 + amplitude * math.cos(lobes * angle));
      final point = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width),
        textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) => CookieBorder(
        lobes: lobes,
        amplitude: amplitude,
        side: side.scale(t),
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is! CookieBorder) return super.lerpFrom(a, t);
    assert(
      a.lobes == lobes,
      'CookieBorder cannot interpolate between ${a.lobes} and $lobes lobes: '
      'lobe count is a register, not a value. Cross-fade the two shapes '
      'instead of morphing one into the other.',
    );
    return CookieBorder(
      lobes: lobes,
      amplitude: lerpDouble(a.amplitude, amplitude, t)!,
      side: BorderSide.lerp(a.side, side, t),
    );
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is! CookieBorder) return super.lerpTo(b, t);
    assert(
      b.lobes == lobes,
      'CookieBorder cannot interpolate between $lobes and ${b.lobes} lobes: '
      'lobe count is a register, not a value. Cross-fade the two shapes '
      'instead of morphing one into the other.',
    );
    return CookieBorder(
      lobes: lobes,
      amplitude: lerpDouble(amplitude, b.amplitude, t)!,
      side: BorderSide.lerp(side, b.side, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CookieBorder &&
      other.lobes == lobes &&
      other.amplitude == amplitude &&
      other.side == side;

  @override
  int get hashCode => Object.hash(lobes, amplitude, side);

  @override
  String toString() => 'CookieBorder(lobes: $lobes, amplitude: $amplitude)';
}
