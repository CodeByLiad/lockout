import 'dart:async';
import 'package:flutter/material.dart';
import 'nv_app_navigation.dart';
import 'nv_button.dart';
import 'nv_expressive.dart';

final Set<int> _slots = {};
void showNvUndo(
  BuildContext context, {
  required String message,
  required Future<void> Function() onUndo,
  Duration duration = const Duration(seconds: 5),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  var slot = 0;
  while (_slots.contains(slot)) {
    slot++;
  }
  _slots.add(slot);
  var visible = true;
  var restoring = false;
  Timer? timer;
  late final OverlayEntry entry;
  void remove() {
    if (!visible) return;
    visible = false;
    timer?.cancel();
    _slots.remove(slot);
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (overlayContext) => Positioned(
      left: 16,
      right: 16,
      bottom:
          MediaQuery.paddingOf(overlayContext).bottom +
          NvAppNavigation.lastRenderedHeight.value +
          12 +
          slot * 96,
      child: Material(
        color: Theme.of(overlayContext).colorScheme.surfaceContainerHigh,
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(overlayContext).textTheme.bodyMedium,
                ),
              ),
              NvButton(
                variant: NvButtonVariant.text,
                label: restoring ? 'Restoring…' : 'Undo',
                onPressed: restoring
                    ? null
                    : () async {
                        restoring = true;
                        timer?.cancel();
                        entry.markNeedsBuild();
                        try {
                          await onUndo();
                          remove();
                        } catch (_) {
                          restoring = false;
                          if (visible) {
                            entry.markNeedsBuild();
                            timer = Timer(duration, remove);
                          }
                        }
                      },
              ),
              NvShapeButton(
                icon: Icons.close_rounded,
                label: 'Dismiss',
                onPressed: remove,
                tone: NvTone.surface,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  timer = Timer(duration, remove);
}
