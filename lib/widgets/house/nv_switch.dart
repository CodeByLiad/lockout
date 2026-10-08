import 'package:flutter/material.dart';

import 'nv_grouped_list.dart';

/// A grouped-list row whose trailing control is a switch, section 8.
///
/// The switch is the standard Material one — section 8 asks for exactly
/// that, and its thumb already grows when on.
class NvSwitchRow extends StatelessWidget {
  final String title;
  final String? supporting;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NvSwitchRow({
    super.key,
    required this.title,
    this.supporting,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NvListItem(
      title: title,
      supporting: supporting,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
