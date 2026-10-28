import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';
import 'nv_button.dart';

/// Section 8 allows a dialog for one thing: a destructive confirmation.
/// Everything else that needs a choice is a bottom sheet.
///
/// Resolves `true` only when the user confirms. A dismissal resolves
/// `false`, never null, so a caller cannot treat "dismissed" as "confirmed"
/// by forgetting a null check.
Future<bool> showNvDestructiveDialog({
  required BuildContext context,
  required String title,
  required String body,

  /// A verb that says exactly what happens — "Discard", "Clear data".
  required String confirmLabel,

  /// What declining does, when "Cancel" is not the clearest word for it.
  /// "Keep going" tells the user what they get back; "Cancel" only says
  /// what they do not.
  String cancelLabel = 'Cancel',
}) async {
  final theme = Theme.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LockoutTheme.radiusDialog),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LockoutTheme.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: LockoutTheme.spaceSm),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: LockoutTheme.spaceLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NvButton(
                  variant: NvButtonVariant.text,
                  label: cancelLabel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: LockoutTheme.spaceSm),
                NvButton(
                  variant: NvButtonVariant.danger,
                  label: confirmLabel,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return confirmed ?? false;
}
