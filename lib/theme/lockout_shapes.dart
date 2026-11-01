import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
// `show`, not a bare import: the package exports its own `Cubic`, which would
// shadow the framework curve `LockoutMotion.spring` is built from.
import 'package:material_new_shapes/material_new_shapes.dart'
    show
        MaterialShapes,
        Morph,
        MorphToPathExtension,
        RoundedPolygon,
        RoundedPolygonToPathExtension;

/// The closed set of Material shapes Lockout uses (deviation D13).
///
/// This file is the only importer of `material_new_shapes` (D14); a screen
/// names a shape here and never reaches for the package.
enum LockoutShape {
  circle,
  square,
  slanted,
  arch,
  pill,
  diamond,
  clamShell,
  pentagon,
  gem,
  sunny,
  verySunny,
  clover4Leaf,
  clover8Leaf,
  flower,
  puffy,
  bun,
  heart,
  softBurst,
  ghostish,
  cookie4,
  cookie6,
  cookie9,
  cookie12;

  /// D5's registers. Cookies are reserved for subject-scale elements.
  static const LockoutShape rest = cookie4;
  static const LockoutShape training = cookie6;
  static const LockoutShape streak = cookie9;
  static const LockoutShape achievement = cookie12;

  bool get isCookie =>
      this == cookie4 || this == cookie6 || this == cookie9 || this == cookie12;

  RoundedPolygon get _polygon => switch (this) {
        circle => MaterialShapes.circle.normalized(),
        square => MaterialShapes.square,
        slanted => MaterialShapes.slanted,
        arch => MaterialShapes.arch,
        pill => MaterialShapes.pill,
        diamond => MaterialShapes.diamond,
        clamShell => MaterialShapes.clamShell,
        pentagon => MaterialShapes.pentagon,
        gem => MaterialShapes.gem,
        sunny => MaterialShapes.sunny,
        verySunny => MaterialShapes.verySunny,
        clover4Leaf => MaterialShapes.clover4Leaf,
        clover8Leaf => MaterialShapes.clover8Leaf,
        flower => MaterialShapes.flower,
        puffy => MaterialShapes.puffy,
        bun => MaterialShapes.bun,
        heart => MaterialShapes.heart,
        softBurst => MaterialShapes.softBurst,
        ghostish => MaterialShapes.ghostish,
        cookie4 => MaterialShapes.cookie4Sided,
        cookie6 => MaterialShapes.cookie6Sided,
        cookie9 => MaterialShapes.cookie9Sided,
        cookie12 => MaterialShapes.cookie12Sided,
      };
}

/// A [LockoutShape] as a `ShapeBorder`, optionally part-way through a morph
/// into a second shape.
///
/// The package's shapes live in a unit square; this scales the path to the
/// rect it is given. [progress] is clamped to [0, 1] when drawn, so a spring
/// curve that overshoots its target cannot extrapolate the path past the end
/// shape.
@immutable
class LockoutShapeBorder extends OutlinedBorder {
  final LockoutShape shape;
  final LockoutShape? morphTo;
  final double progress;

  const LockoutShapeBorder(
    this.shape, {
    this.morphTo,
    this.progress = 0,
    super.side,
  });

  /// A [Morph] matches curves between two shapes, which is the expensive
  /// part. Cached per pair so a press does not re-match on every frame
  /// (spec §7, "shape morph cost").
  static final Map<(LockoutShape, LockoutShape), Morph> _morphs = {};

  Path _unitPath() {
    final to = morphTo;
    if (to == null) return shape._polygon.toPath();
    final morph = _morphs.putIfAbsent(
        (shape, to), () => Morph(shape._polygon, to._polygon));
    return morph.toPath(progress: progress.clamp(0.0, 1.0));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final matrix = Matrix4.identity()
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(rect.width, rect.height, 1, 1);
    return _unitPath().transform(matrix.storage);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.strokeInset),
          textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  LockoutShapeBorder copyWith({BorderSide? side}) => LockoutShapeBorder(
        shape,
        morphTo: morphTo,
        progress: progress,
        side: side ?? this.side,
      );

  @override
  ShapeBorder scale(double t) => copyWith(side: side.scale(t));

  /// Interpolates [progress] (and the side) between two borders of the same
  /// morph; anything else falls back to the framework's cross-fade.
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is LockoutShapeBorder && a.shape == shape && a.morphTo == morphTo) {
      return LockoutShapeBorder(
        shape,
        morphTo: morphTo,
        progress: lerpDouble(a.progress, progress, t)!,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is LockoutShapeBorder && b.shape == shape && b.morphTo == morphTo) {
      return LockoutShapeBorder(
        shape,
        morphTo: morphTo,
        progress: lerpDouble(progress, b.progress, t)!,
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is LockoutShapeBorder &&
      other.shape == shape &&
      other.morphTo == morphTo &&
      other.progress == progress &&
      other.side == side;

  @override
  int get hashCode => Object.hash(shape, morphTo, progress, side);

  @override
  String toString() => 'LockoutShapeBorder($shape'
      '${morphTo == null ? '' : ' -> $morphTo @ $progress'})';
}
