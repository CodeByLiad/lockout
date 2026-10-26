import 'package:flutter/material.dart';

import '../../theme/lockout_semantics.dart';
import '../../theme/lockout_theme.dart';
import '../morphing_surface.dart';

/// The house button variants, section 8 of the design system.
///
/// One filled or accent button per screen; the rest carry secondary and
/// low-emphasis actions. Variants arrive as a screen consumes them — a
/// variant nothing presses is not built.
enum NvButtonVariant { accent, tonal, filled, outlined, text, danger }

/// A button whose corner radius is a function of its press state.
///
/// Bespoke rather than a themed `FilledButton` because the press morph has
/// to honour "remove animations", and that setting lives on `MediaQuery` —
/// unreachable from the context-free `ThemeData` the previous approach built
/// its style in. That limitation was deviation D10; this retires it.
class NvButton extends StatefulWidget {
  final NvButtonVariant variant;
  final String label;
  final IconData? icon;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// The hero size: 60dp tall, morphing to 16dp rather than 12dp.
  final bool large;

  const NvButton({
    super.key,
    required this.variant,
    required this.label,
    this.icon,
    required this.onPressed,
    this.large = false,
  });

  @override
  State<NvButton> createState() => _NvButtonState();
}

class _NvButtonState extends State<NvButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  double get _activeRadius => widget.large
      ? LockoutTheme.radiusButtonLargeActive
      : LockoutTheme.radiusButtonActive;

  ({Color? background, Color foreground, BorderSide side}) _paletteFor(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;
    final semantics = LockoutSemantics.of(context);

    // Null, not `Colors.transparent`: `MorphingSurface` reads a non-null
    // colour as "this surface paints" and switches on `Clip.antiAlias`, so a
    // transparent fill buys a clip layer per outlined, text and danger
    // button for nothing. Null is the absence of a fill, which is also the
    // one thing no theme role can name.
    const Color? noFill = null;

    return switch (widget.variant) {
      // `onPrimaryContainer` on `primaryContainer`, inverted: the accent
      // button is the hero action, and the hero card it sits on is itself
      // filled with `primaryContainer`. Sharing that fill made the primary
      // action invisible on a device while every unit assertion passed
      // (device QA B1).
      NvButtonVariant.accent => (
          background: colors.onPrimaryContainer,
          foreground: colors.primaryContainer,
          side: BorderSide.none,
        ),
      NvButtonVariant.filled => (
          background: colors.primary,
          foreground: colors.onPrimary,
          side: BorderSide.none,
        ),
      NvButtonVariant.tonal => (
          background: colors.secondaryContainer,
          foreground: colors.onSecondaryContainer,
          side: BorderSide.none,
        ),
      // No fill, not `surface`: section 8 gives these a border or nothing at
      // all, and a `surface` fill reads as a solid pill on any tinted
      // background — three of them sat on the rest bar looking filled
      // (device QA B3).
      NvButtonVariant.outlined => (
          background: noFill,
          foreground: colors.onSurface,
          side: BorderSide(color: colors.outline),
        ),
      NvButtonVariant.text => (
          background: noFill,
          foreground: colors.primary,
          side: BorderSide.none,
        ),
      NvButtonVariant.danger => (
          background: noFill,
          foreground: semantics.danger,
          side: BorderSide(color: colors.outlineVariant),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _paletteFor(context);
    final foreground =
        _enabled ? palette.foreground : theme.colorScheme.onSurfaceVariant;

    // `onTap` on the same node as the label: `excludeSemantics` drops the
    // `GestureDetector`'s own semantics, including its tap action, so
    // without this the button reaches a screen reader announced and
    // unpressable.
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: MorphingSurface(
          restRadius: LockoutTheme.radiusButtonRest,
          activeRadius: _activeRadius,
          active: _pressed,
          activeScale: LockoutTheme.pressScale,
          color: _enabled
              ? palette.background
              : theme.colorScheme.surfaceContainerHighest,
          child: Container(
            height: widget.large ? 60 : LockoutTheme.minTouchTarget,
            padding:
                const EdgeInsets.symmetric(horizontal: LockoutTheme.spaceLg),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                _enabled ? palette.side : BorderSide.none,
              ),
              borderRadius: BorderRadius.circular(
                _pressed ? _activeRadius : LockoutTheme.radiusButtonRest,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: foreground),
                  const SizedBox(width: LockoutTheme.spaceSm),
                ],
                // Flexible, not bare: a button in a `Wrap` or a grid cell can
                // be handed less width than its label wants, and an
                // unshrinkable label overflows the row rather than eliding.
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What an icon button's fill is saying.
///
/// Most icon buttons are neutral chrome. A toggle that reports a completed
/// thing — a logged set — is the exception, and it reads through the
/// semantics layer's success pair rather than a colour typed at the call
/// site.
enum NvIconButtonTone { neutral, success }

/// Section 8's icon button: a 48dp pill that rounds to 14dp while pressed.
///
/// [tooltip] is required, not optional — section 9 says an icon-only button
/// always carries a content description, and a required parameter is the
/// only version of that rule a call site cannot forget.
class NvIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final NvIconButtonTone tone;

  const NvIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = NvIconButtonTone.neutral,
  });

  @override
  State<NvIconButton> createState() => _NvIconButtonState();
}

class _NvIconButtonState extends State<NvIconButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantics = LockoutSemantics.of(context);

    final (Color background, Color foreground) =
        switch (widget.tone) {
      NvIconButtonTone.neutral => (
          colors.surfaceContainerHigh,
          colors.onSurface,
        ),
      NvIconButtonTone.success => (semantics.success, semantics.onSuccess),
    };

    // Semantics outside Tooltip, not inside: a Tooltip introduces its own
    // semantics node, and with the label nested under it the button's own
    // node reaches a screen reader unlabelled.
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.tooltip,
      // Same reason as NvButton: excluded descendants take their tap action
      // with them, so the action has to live on the labelled node.
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: MorphingSurface(
            restRadius: LockoutTheme.radiusButtonRest,
            activeRadius: 14,
            active: _pressed,
            color: background,
            child: SizedBox(
              width: LockoutTheme.minTouchTarget,
              height: LockoutTheme.minTouchTarget,
              child: Icon(
                widget.icon,
                size: 24,
                color: _enabled ? foreground : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
