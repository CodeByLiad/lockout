import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'accents.dart';
import 'lockout_theme.dart';
import 'palette.dart';

/// The brightness axis: what the user asked for, not what is on screen.
///
/// `system` is a real choice rather than the absence of one, which is why it
/// is a value here instead of a null brightness.
enum LockoutBrightnessChoice {
  system('system'),
  light('light'),
  dark('dark');

  const LockoutBrightnessChoice(this.key);

  final String key;

  static LockoutBrightnessChoice byKey(String key) {
    for (final choice in values) {
      if (choice.key == key) return choice;
    }
    return system;
  }
}

/// Owns which appearance is active and turns it into `ThemeData`.
///
/// A `ChangeNotifier` rather than an `InheritedWidget` of its own: the app
/// root listens once and rebuilds `MaterialApp`, which is all the framework
/// needs to repaint every `Theme.of(context)` reader beneath it.
///
/// Two axes, not three. Material You was removed with the `dynamic_color`
/// dependency because the house system forbids wallpaper-derived colour
/// (section 2): an app whose surfaces come from the phone stops looking like
/// the family it belongs to.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _settingKey = 'theme_key';

  /// The two axes are stored in one setting as `brightness|accent`, so the
  /// schema does not change. A single separator rather than JSON: there are
  /// exactly two fields and there always will be.
  static const String _separator = '|';

  LockoutBrightnessChoice _brightness = LockoutBrightnessChoice.system;
  LockoutAccent _accent = LockoutAccent.fallback;

  LockoutBrightnessChoice get brightnessChoice => _brightness;
  LockoutAccent get accent => _accent;

  ThemeData get lightTheme => LockoutTheme.build(
        colors: LockoutPalette.schemeFor(Brightness.light, _accent),
        semantics: LockoutPalette.semanticsFor(Brightness.light, _accent),
      );

  /// Always non-null now.
  ///
  /// The old controller returned null unless a dynamic scheme was in force,
  /// because an authored scheme carried its own brightness and offering a
  /// second one would let the system override an explicit choice. With
  /// brightness as its own axis that problem is gone: `themeMode` says which
  /// of the two to use, so both can always be supplied.
  ThemeData get darkTheme => LockoutTheme.build(
        colors: LockoutPalette.schemeFor(Brightness.dark, _accent),
        semantics: LockoutPalette.semanticsFor(Brightness.dark, _accent),
      );

  ThemeMode get themeMode => switch (_brightness) {
        LockoutBrightnessChoice.system => ThemeMode.system,
        LockoutBrightnessChoice.light => ThemeMode.light,
        LockoutBrightnessChoice.dark => ThemeMode.dark,
      };

  /// Reads the saved choice. Call before the first frame so the app never
  /// flashes the default theme on top of the chosen one.
  ///
  /// Writes back whenever the stored value was in the old format, so the
  /// migration happens once rather than on every launch.
  Future<void> load() async {
    final saved =
        await DatabaseService.instance.getSetting(_settingKey, defaultValue: '');
    final (brightness, accent) = _resolve(saved);
    _brightness = brightness;
    _accent = accent;

    final canonical = _encode(brightness, accent);
    if (saved != canonical) {
      try {
        await DatabaseService.instance.saveSetting(_settingKey, canonical);
      } catch (_) {
        // The write is an optimisation, not the migration: the resolved
        // choice is already in the fields above. `main` awaits this before
        // `runApp`, so letting the failure out would replace the app with a
        // blank screen on every launch, with no widget alive to offer a way
        // back. Dropping it costs one re-migration next launch instead, and
        // the stored value is left intact for it — never cleared.
      }
    }
    notifyListeners();
  }

  /// Persist first, then commit.
  ///
  /// The write is the part that can fail, so the field is only moved once
  /// the database has taken the value. The alternative — assign, then write —
  /// leaves the controller claiming a choice the database refused, with no
  /// `notifyListeners` to repaint the app to match, and the equality guard
  /// below then turns the user's retry into a no-op. The throw is deliberate:
  /// the caller shows the failure.
  /// What the most recent call is trying to store, which is not what the
  /// fields say while a write is in flight.
  ///
  /// The equality guard has to compare against this rather than against the
  /// field, or the "I tapped the wrong one, tap back" gesture loses: tap
  /// teal, then lime before the first write lands, and a guard reading
  /// `_accent` still sees lime, returns early, writes nothing — and teal
  /// then commits underneath. The user's last choice is the one that must
  /// win.
  LockoutBrightnessChoice? _pendingBrightness;
  LockoutAccent? _pendingAccent;

  Future<void> selectBrightness(LockoutBrightnessChoice choice) async {
    if (choice == (_pendingBrightness ?? _brightness)) return;
    _pendingBrightness = choice;
    try {
      await _persist(choice, _pendingAccent ?? _accent);
      // Commit only while this call is still the latest selection — the same
      // question the `finally` below asks, now actually acted on. A newer tap
      // owns the choice, and its own write is either already stored or about
      // to be; committing here would repaint the whole app in a choice the
      // user has already moved away from. sqflite's FIFO write ordering hides
      // the end state, so the flash was the only symptom.
      if (_pendingBrightness != choice) return;
      _brightness = choice;
      notifyListeners();
    } finally {
      // Cleared only if this call is still the latest; a newer selection owns
      // the slot and will clear it when its own write returns.
      if (_pendingBrightness == choice) _pendingBrightness = null;
    }
  }

  Future<void> selectAccent(LockoutAccent accent) async {
    if (accent == (_pendingAccent ?? _accent)) return;
    _pendingAccent = accent;
    try {
      await _persist(_pendingBrightness ?? _brightness, accent);
      if (_pendingAccent != accent) return;
      _accent = accent;
      notifyListeners();
    } finally {
      if (_pendingAccent == accent) _pendingAccent = null;
    }
  }

  /// Takes the pair explicitly rather than reading the fields, so it cannot
  /// be called in an order that writes a half-applied state.
  Future<void> _persist(
    LockoutBrightnessChoice brightness,
    LockoutAccent accent,
  ) =>
      DatabaseService.instance
          .saveSetting(_settingKey, _encode(brightness, accent));

  static String _encode(
    LockoutBrightnessChoice brightness,
    LockoutAccent accent,
  ) =>
      '${brightness.key}$_separator${accent.key}';

  /// The keys of the palette system that preceded the six named schemes.
  ///
  /// They used to migrate in two hops — `schemes.dart` mapped them onto one
  /// of the six, and the six map to an axis pair below. That file is gone,
  /// so the first hop is folded in here. Dropping it would silently reset
  /// the appearance of every install that has not launched since the
  /// Jinatra layer was deleted.
  static const Map<String, String> _preSchemeKeys = {
    'carbon_lime': 'graphite',
    'midnight_cyan': 'indigo',
    'ash_amber': 'ember',
    'void_magenta': 'graphite',
    'jinatra_cream': 'paper',
    'paper_press': 'paper',
    'mint_lab': 'frost',
    'sunblock': 'linen',
  };

  /// The brightness each retired scheme was authored at.
  ///
  /// Waking up to a white app because a palette was retired is the one
  /// outcome worse than losing the exact hue, so brightness is preserved
  /// exactly; the accent comes from [LockoutAccent.byKey], which maps each
  /// retired key onto the closest hue it offers.
  static const Map<String, LockoutBrightnessChoice> _legacyBrightness = {
    'graphite': LockoutBrightnessChoice.dark,
    'ember': LockoutBrightnessChoice.dark,
    'indigo': LockoutBrightnessChoice.dark,
    'paper': LockoutBrightnessChoice.light,
    'linen': LockoutBrightnessChoice.light,
    'frost': LockoutBrightnessChoice.light,
    'dynamic': LockoutBrightnessChoice.system,
  };

  /// Reads either format.
  ///
  /// A stored value with no separator is one of the retired scheme keys (or
  /// junk). Each maps to the brightness it was authored at and the accent
  /// closest to its hue; `dynamic` maps to the fresh-install default,
  /// because Material You no longer exists and there is no hue to preserve.
  /// Junk falls back rather than throwing, and the caller rewrites the
  /// setting — it is never cleared.
  static (LockoutBrightnessChoice, LockoutAccent) _resolve(String saved) {
    if (saved.contains(_separator)) {
      final parts = saved.split(_separator);
      return (
        LockoutBrightnessChoice.byKey(parts.first),
        LockoutAccent.byKey(parts.length > 1 ? parts[1] : ''),
      );
    }

    final key = _preSchemeKeys[saved] ?? saved;
    return (
      _legacyBrightness[key] ?? LockoutBrightnessChoice.system,
      LockoutAccent.byKey(key),
    );
  }

  /// Returns the controller to its fresh-install state.
  ///
  /// The singleton outlives an individual test, so without this a suite that
  /// selected `coral` would leak that choice into the next one.
  @visibleForTesting
  void resetForTest() {
    _brightness = LockoutBrightnessChoice.system;
    _accent = LockoutAccent.fallback;
    _pendingBrightness = null;
    _pendingAccent = null;
  }
}
