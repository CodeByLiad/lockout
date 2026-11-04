import '../../theme/lockout_theme.dart';
import 'package:flutter/material.dart';
import '../../theme/lockout_motion.dart';
import '../../services/display_units.dart';
import '../../theme/lockout_shapes.dart';
import 'nv_button.dart';

enum NvTone { primary, secondary, tertiary, surface }

/// Shares a surface's interaction with its shaped descendants.
class NvPressState extends InheritedWidget {
  final bool active;
  const NvPressState({super.key, required this.active, required super.child});
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NvPressState>()?.active ??
      false;
  @override
  bool updateShouldNotify(NvPressState oldWidget) => active != oldWidget.active;
}

(Color, Color) nvColors(BuildContext context, NvTone tone) {
  final c = Theme.of(context).colorScheme;
  return switch (tone) {
    NvTone.primary => (c.primaryContainer, c.onPrimaryContainer),
    NvTone.secondary => (c.secondaryContainer, c.onSecondaryContainer),
    NvTone.tertiary => (c.tertiaryContainer, c.onTertiaryContainer),
    NvTone.surface => (c.surfaceContainerLow, c.onSurface),
  };
}

/// A Material surface whose shape follows pointer, keyboard and focus state.
class NvSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final NvTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool selected;
  const NvSurface({
    super.key,
    required this.child,
    this.onPressed,
    this.tone = NvTone.surface,
    this.padding = const EdgeInsets.all(LockoutTheme.screenPadding),
    this.radius = 28,
    this.selected = false,
  });
  @override
  State<NvSurface> createState() => _NvSurfaceState();
}

class _NvSurfaceState extends State<NvSurface> {
  bool _pressed = false;
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final (fill, ink) = nvColors(context, widget.tone);
    final active = _pressed || widget.selected;
    final radius = BorderRadius.circular(active ? 16 : widget.radius);
    return AnimatedContainer(
      duration: LockoutMotion.springFast.durationFor(context),
      curve: LockoutMotion.springFast.curve,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: _focused
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: fill,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          borderRadius: radius,
          child: Padding(
            padding: widget.padding,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: ink),
              child: IconTheme.merge(
                data: IconThemeData(color: ink),
                child: NvPressState(
                  active: _pressed || _focused,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NvIconBadge extends StatelessWidget {
  final IconData icon;
  final LockoutShape shape;
  final NvTone tone;
  final double size;
  final bool pressed;
  const NvIconBadge({
    super.key,
    required this.icon,
    this.shape = LockoutShape.flower,
    this.tone = NvTone.primary,
    this.size = 48,
    this.pressed = false,
  });
  @override
  Widget build(BuildContext context) {
    final (fill, ink) = nvColors(context, tone);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: pressed || NvPressState.of(context) ? 1 : 0),
      duration: LockoutMotion.springFast.durationFor(context),
      curve: LockoutMotion.springFast.curve,
      builder: (_, value, child) => Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          color: fill,
          shape: LockoutShapeBorder(
            shape,
            morphTo: LockoutShape.circle,
            progress: value,
          ),
        ),
        child: child,
      ),
      child: Icon(icon, color: ink, size: size * .48),
    );
  }
}

class NvShapeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final LockoutShape shape;
  final NvTone tone;
  const NvShapeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.shape = LockoutShape.flower,
    this.tone = NvTone.primary,
  });
  @override
  State<NvShapeButton> createState() => _NvShapeButtonState();
}

class _NvShapeButtonState extends State<NvShapeButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.label,
    child: Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onPressed != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => pressed = v),
          child: NvIconBadge(
            icon: widget.icon,
            shape: widget.shape,
            tone: widget.tone,
            pressed: pressed,
          ),
        ),
      ),
    ),
  );
}

class NvActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LockoutShape shape;
  final NvTone tone;
  final VoidCallback onPressed;
  const NvActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.shape,
    required this.tone,
    required this.onPressed,
  });
  @override
  State<NvActionCard> createState() => _NvActionCardState();
}

class _NvActionCardState extends State<NvActionCard> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${widget.title}, ${widget.subtitle}',
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => setState(() => pressed = true),
        onPointerUp: (_) => setState(() => pressed = false),
        onPointerCancel: (_) => setState(() => pressed = false),
        child: NvSurface(
          tone: widget.tone,
          onPressed: widget.onPressed,
          padding: const EdgeInsets.all(LockoutTheme.cardPadding),
          radius: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NvIconBadge(
                icon: widget.icon,
                shape: widget.shape,
                tone: widget.tone == NvTone.secondary
                    ? NvTone.primary
                    : NvTone.secondary,
                size: 52,
                pressed: pressed,
              ),
              const SizedBox(height: 20),
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class NvHeading extends StatelessWidget {
  final String text;
  final Widget? action;
  const NvHeading(this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
        ),
        ?action,
      ],
    ),
  );
}

class NvPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? footer;
  final bool back;
  const NvPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.actions = const [],
    this.footer,
    this.back = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (back) ...[
                  NvShapeButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: back
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.displayMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 24),
            ...children,
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ],
        ),
      ),
      bottomNavigationBar: footer == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: footer!,
            ),
    );
  }
}

class NvMetric extends StatelessWidget {
  final String label;
  final String value;
  final NvTone tone;
  const NvMetric({
    super.key,
    required this.label,
    required this.value,
    this.tone = NvTone.surface,
  });
  @override
  Widget build(BuildContext context) => NvSurface(
    tone: tone,
    padding: const EdgeInsets.all(LockoutTheme.cardPadding),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

Future<T?> showNvEditor<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) => Navigator.of(context).push<T>(
  MaterialPageRoute(
    builder: (routeContext) =>
        NvPage(title: title, back: true, children: [builder(routeContext)]),
  ),
);

class NvField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? suffix;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final TextStyle? textStyle;
  final bool compact;
  const NvField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.suffix,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.errorText,
    this.textStyle,
    this.compact = false,
  });
  @override
  State<NvField> createState() => _NvFieldState();
}

class _NvFieldState extends State<NvField> {
  final FocusNode _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_focus.hasFocus ? 24 : 16),
      borderSide: BorderSide.none,
    );
    return TextFormField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      style: widget.textStyle ?? Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 6,
        suffixText: widget.suffix,
        filled: true,
        fillColor: c.surfaceContainerHigh,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: border.copyWith(borderSide: BorderSide(color: c.error)),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: c.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 20,
          vertical: widget.compact ? 12 : 20,
        ),
      ),
    );
  }
}

/// A data-driven trend with explicit endpoints; never paints invented data.
class NvTrend extends StatelessWidget {
  final List<double> values;
  const NvTrend({super.key, required this.values});
  @override
  Widget build(BuildContext context) {
    final points = values.where((v) => v.isFinite).toList();
    if (points.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Log a second measurement to see your trend.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              points,
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DisplayUnits.format(context, points.first)),
            Text(DisplayUnits.format(context, points.last)),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _TrendPainter(this.values, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max == min ? 1.0 : max - min;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = 8 + (size.width - 16) * i / (values.length - 1);
      final y =
          size.height - 12 - (values[i] - min) / range * (size.height - 24);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.color != color;
}

class NvEmpty extends StatelessWidget {
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;
  final IconData icon;
  const NvEmpty({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
    this.icon = Icons.fitness_center_rounded,
  });
  @override
  Widget build(BuildContext context) => NvSurface(
    tone: NvTone.primary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NvIconBadge(
          icon: icon,
          shape: LockoutShape.softBurst,
          size: 72,
          tone: NvTone.secondary,
        ),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(message, style: Theme.of(context).textTheme.bodyLarge),
        if (action != null) ...[
          const SizedBox(height: 24),
          NvButton(
            variant: NvButtonVariant.filled,
            label: action!,
            onPressed: onPressed,
          ),
        ],
      ],
    ),
  );
}

class NvWeekStrip extends StatelessWidget {
  final Set<String> dates;
  final Set<int> plannedWeekdays;
  const NvWeekStrip({
    super.key,
    required this.dates,
    this.plannedWeekdays = const {},
  });
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final c = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (_) {
                final day = start.add(Duration(days: i));
                final completed = dates.contains(
                  day.toIso8601String().split('T').first,
                );
                final planned = plannedWeekdays.contains(i + 1);
                return Semantics(
                  label:
                      '${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][i]}, ${day.day}${completed
                          ? ', workout completed'
                          : planned
                          ? ', planned training'
                          : ''}',
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        if (completed || planned)
                          NvIconBadge(
                            icon: completed
                                ? Icons.check_rounded
                                : Icons.fitness_center_rounded,
                            shape: LockoutShape.flower,
                            size: 32,
                            tone: NvTone.surface,
                          )
                        else
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == now.weekday - 1
                                  ? c.secondaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${day.day}'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class NvSaveButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onSave;
  final NvButtonVariant variant;
  const NvSaveButton({
    super.key,
    required this.label,
    required this.onSave,
    this.variant = NvButtonVariant.filled,
  });
  @override
  State<NvSaveButton> createState() => _NvSaveButtonState();
}

class _NvSaveButtonState extends State<NvSaveButton> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) => NvButton(
    variant: widget.variant,
    label: _saving ? 'Saving…' : widget.label,
    onPressed: _saving
        ? null
        : () async {
            setState(() => _saving = true);
            try {
              await widget.onSave();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Changes not saved. Your input is still here. Try again.',
                    ),
                  ),
                );
              }
            } finally {
              if (context.mounted &&
                  (ModalRoute.of(context)?.isCurrent ?? true)) {
                setState(() => _saving = false);
              }
            }
          },
  );
}
