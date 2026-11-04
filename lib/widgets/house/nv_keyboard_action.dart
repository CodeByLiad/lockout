import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives a custom Material surface the same activation keys as a button.
class NvKeyboardAction extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChanged;
  const NvKeyboardAction({
    super.key,
    required this.child,
    required this.onPressed,
    this.onFocusChanged,
  });
  @override
  Widget build(BuildContext context) => onPressed == null
      ? child
      : FocusableActionDetector(
          includeFocusSemantics: false,
          enabled: onPressed != null,
          onShowFocusHighlight: onFocusChanged,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                onPressed?.call();
                return null;
              },
            ),
          },
          child: child,
        );
}
