import 'package:flutter/material.dart';

/// The third theme axis: which Material scheme variant the accent seed
/// generates the whole colour scheme with (deviation D12).
///
/// The house system has no such axis. The user chose to let people pick the
/// variant themselves.
enum LockoutSchemeStyle {
  tonal('tonal', 'Tonal', DynamicSchemeVariant.tonalSpot),
  vibrant('vibrant', 'Vibrant', DynamicSchemeVariant.vibrant),
  expressive('expressive', 'Expressive', DynamicSchemeVariant.expressive);

  const LockoutSchemeStyle(this.key, this.label, this.variant);

  /// The value persisted as the third field of `theme_key`.
  final String key;

  /// What the picker calls it. Sentence case.
  final String label;

  final DynamicSchemeVariant variant;

  /// The style on a fresh install, and for any value written before the
  /// axis existed.
  static const LockoutSchemeStyle fallback = tonal;

  /// Never throws; junk becomes [fallback].
  static LockoutSchemeStyle byKey(String key) {
    for (final style in values) {
      if (style.key == key) return style;
    }
    return fallback;
  }
}
