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
    final hasError = errorText != null;
    // The error is not routed through `InputDecoration.errorText`: the
    // decorator renders its own error row inside the field's box, and this
    // field's box is a fixed 56dp, so the input would be squeezed and the
    // message would print twice. The two things the decorator would have
    // done — colour the border, tell a screen reader — are done here
    // instead.
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
      borderSide: BorderSide(color: hasError ? colors.error : colors.outline),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Excluded, not hidden: this Text is the field's name, and once the
        // field carries that name itself a second node reading it aloud is
        // one announcement too many.
        ExcludeSemantics(
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        const SizedBox(height: LockoutTheme.spaceXs),
        // A label sitting above a field names nothing: the editable node is
        // what a screen reader focuses, and it announced as an unnamed edit
        // box on every Settings form. `MergeSemantics` folds the annotation
        // into that node rather than parking it on a parent, which is the
        // shape Material produces for `InputDecoration.labelText`.
        MergeSemantics(
          child: Semantics(
            label: label,
            hint: errorText,
            child: SizedBox(
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
                    borderSide: BorderSide(
                      color: hasError ? colors.error : colors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
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
