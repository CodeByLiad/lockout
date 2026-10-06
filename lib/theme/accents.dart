import 'package:flutter/material.dart';

/// One selectable accent: a colour and the ink that is legible on it.
///
/// A pair rather than a single hex, because the house system uses the accent
/// as a *container* tone — a filled surface with dark text on it — not as a
/// text colour. `docs/design/nuvetrix-app-design-system.md` section 3.3.
@immutable
class LockoutAccent {
  /// The value persisted in the `theme_key` setting.
  final String key;

  /// What the picker calls it. Sentence case; the house document forbids
  /// all-caps labels.
  final String name;

  /// The fill. In light it is `primaryContainer`; in dark it is both
  /// `primary` and `primaryContainer`.
  final Color accent;

  /// The foreground painted on [accent]. A very dark shade of the accent's
  /// own hue rather than pure black, per the house rules.
  final Color ink;

  const LockoutAccent({
    required this.key,
    required this.name,
    required this.accent,
    required this.ink,
  });

  /// Lockout's identity accent, registered in the house accents table.
  ///
  /// Hue 81 degrees — the widest gap open in the family — at a lightness
  /// inside the house's 75-85% band, and far from both Google Play green and
  /// the reserved Nuvetrix ultramarine.
  static const LockoutAccent lime = LockoutAccent(
    key: 'lime',
    name: 'Rep lime',
    accent: Color(0xFFC2EE7B),
    ink: Color(0xFF1F2E00),
  );

  static const LockoutAccent violet = LockoutAccent(
    key: 'violet',
    name: 'Violet',
    accent: Color(0xFFB9A8FF),
    ink: Color(0xFF21105E),
  );

  static const LockoutAccent teal = LockoutAccent(
    key: 'teal',
    name: 'Teal',
    accent: Color(0xFF6ED6C4),
    ink: Color(0xFF00382F),
  );

  static const LockoutAccent coral = LockoutAccent(
    key: 'coral',
    name: 'Coral',
    accent: Color(0xFFFF9E8A),
    ink: Color(0xFF4A0E00),
  );

  /// The neutral. Not in the house's optional set — deviation register D6.
  /// Without it, every `graphite` and `paper` user would migrate onto a hue
  /// they never chose.
  static const LockoutAccent steel = LockoutAccent(
    key: 'steel',
    name: 'Steel',
    accent: Color(0xFFA9B4C6),
    ink: Color(0xFF1B2430),
  );

  static const List<LockoutAccent> all = [lime, violet, teal, coral, steel];

  /// The accent on a fresh install, and the destination for anything
  /// unrecognised.
  static const LockoutAccent fallback = lime;

  /// The six retired scheme keys, each mapped to the accent closest to the
  /// hue the user actually chose.
  ///
  /// `linen` lands on coral because coral is the only warm accent available;
  /// mapping it to steel instead would collapse two distinct old choices
  /// onto one new one. `dynamic` lands on the default, because Material You
  /// is gone and there is no hue to preserve.
  static const Map<String, String> _legacyKeys = {
    'graphite': 'steel',
    'paper': 'steel',
    'ember': 'coral',
    'linen': 'coral',
    'indigo': 'violet',
    'frost': 'teal',
    'dynamic': 'lime',
  };

  /// Resolves a stored or legacy key. Never throws; junk becomes [fallback].
  static LockoutAccent byKey(String key) {
    final resolved = _legacyKeys[key] ?? key;
    for (final accent in all) {
      if (accent.key == resolved) return accent;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      other is LockoutAccent && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'LockoutAccent($key)';
}
