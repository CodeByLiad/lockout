import 'package:flutter/material.dart';
import '../../services/numeric_guard.dart';
import '../../services/display_units.dart';
import '../../theme/lockout_motion.dart';
import '../../theme/lockout_theme.dart';
import '../../theme/lockout_shapes.dart';
import 'nv_expressive.dart';

class NvSetRow extends StatefulWidget {
  final int index;
  final double weight;
  final int reps;
  final bool completed;
  final ValueChanged<double> onWeight;
  final ValueChanged<int> onReps;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final Key? completionKey;
  const NvSetRow({
    super.key,
    required this.index,
    required this.weight,
    required this.reps,
    required this.completed,
    required this.onWeight,
    required this.onReps,
    required this.onToggle,
    this.onDelete,
    this.completionKey,
  });
  @override
  State<NvSetRow> createState() => _NvSetRowState();
}

class _NvSetRowState extends State<NvSetRow> {
  late final _weight = TextEditingController(
    text: _format(DisplayUnits.value(widget.weight)),
  );
  late final _reps = TextEditingController(text: '${widget.reps}');
  String? _error;
  String _format(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  bool _validate() {
    final weight = NumericGuard.parse(_weight.text, min: 0);
    final reps = int.tryParse(_reps.text);
    if (weight == null || reps == null || reps < 1) {
      setState(() => _error = 'Enter a valid weight and at least one rep.');
      return false;
    }
    widget.onWeight(DisplayUnits.toKg(weight));
    widget.onReps(reps);
    setState(() => _error = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: LockoutMotion.effects.durationFor(context),
      curve: LockoutMotion.effects.curve,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: widget.completed ? c.primaryContainer : c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(widget.completed ? 24 : 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${widget.index}',
                  style: LockoutTheme.numeric(context, size: 15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NvField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textStyle: LockoutTheme.numeric(context, size: 15),
                  label: DisplayUnits.unit,
                  compact: true,
                  onChanged: (value) {
                    final number = NumericGuard.parse(value, min: 0);
                    if (number != null) {
                      widget.onWeight(DisplayUnits.toKg(number));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NvField(
                  controller: _reps,
                  keyboardType: TextInputType.number,
                  textStyle: LockoutTheme.numeric(context, size: 15),
                  label: 'Reps',
                  compact: true,
                  onChanged: (value) {
                    final number = int.tryParse(value);
                    if (number != null && number > 0) widget.onReps(number);
                  },
                ),
              ),
              const SizedBox(width: 8),
              NvShapeButton(
                key: widget.completionKey,
                icon: widget.completed
                    ? Icons.check_rounded
                    : Icons.radio_button_unchecked,
                shape: widget.completed
                    ? LockoutShape.flower
                    : LockoutShape.gem,
                label: widget.completed
                    ? 'Mark set incomplete'
                    : 'Mark set complete',
                tone: widget.completed ? NvTone.primary : NvTone.secondary,
                onPressed: () {
                  if (_validate()) {
                    FocusScope.of(context).unfocus();
                    widget.onToggle();
                  }
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Set options',
                onSelected: (_) => widget.onDelete?.call(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    enabled: widget.onDelete != null,
                    child: const Text('Remove set'),
                  ),
                ],
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: c.error)),
            ),
        ],
      ),
    );
  }
}
