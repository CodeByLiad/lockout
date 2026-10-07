import 'package:flutter/material.dart';

import '../../theme/lockout_theme.dart';

/// Section 8's bottom sheet: `surfaceContainer`, 32dp top corners, a drag
/// handle, 24dp side padding.
///
/// Preferred over a dialog for choices, confirmations and short forms — a
/// dialog is reserved for destructive confirmations alone.
Future<T?> showNvSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
}) {
  final theme = Theme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: theme.colorScheme.surfaceContainer,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(LockoutTheme.radiusSheet),
      ),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        LockoutTheme.spaceLg,
        0,
        LockoutTheme.spaceLg,
        LockoutTheme.spaceLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: LockoutTheme.spaceMd),
          ],
          child,
        ],
      ),
    ),
  );
}

/// Section 8's snackbar: `onSurface` background, `surface` text, 16dp
/// corners, above the nav bar, gone after three seconds.
///
/// The message repeats the action's name — "Session saved" after Save — so
/// the confirmation says what happened rather than that something did.
void showNvSnackbar({
  required BuildContext context,
  required String message,
}) {
  final theme = Theme.of(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.surface,
        ),
      ),
      backgroundColor: theme.colorScheme.onSurface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LockoutTheme.radiusField),
      ),
    ),
  );
}
