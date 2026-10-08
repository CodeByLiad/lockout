import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// Section 8's text field: outlined, 56dp tall, 16dp corners, the label
/// above the field rather than floating inside it, error text below.
class NvTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  const NvTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.errorText,
    this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
      borderSide: BorderSide(color: colors.outline),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: LockoutTheme.spaceXs),
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: LockoutTheme.spaceMd,
              ),
              enabledBorder: border,
              border: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: LockoutTheme.spaceXs),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
