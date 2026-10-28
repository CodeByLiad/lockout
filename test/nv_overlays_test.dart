import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/widgets/house/nv_button.dart';
import 'package:lockout/widgets/house/nv_dialog.dart';
import 'package:lockout/widgets/house/nv_sheet.dart';

import 'test_helpers.dart';

Widget _host(Widget Function(BuildContext) child) => MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(body: Builder(builder: child)),
    );

void main() {
  group('bottom sheet', () {
    testWidgets('it has 32dp top corners and a drag handle', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () => showNvSheet<void>(
              context: context,
              child: const Text('Session saved'),
            ),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Session saved'), findsOneWidget);

      final sheet = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Session saved'),
              matching: find.byType(Material),
            )
            .last,
      );
      final shape = sheet.shape! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 32);
    });

    testWidgets('it returns what the sheet popped', (tester) async {
      String? result;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async {
              result = await showNvSheet<String>(
                context: context,
                child: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => Navigator.of(ctx).pop('save'),
                    child: const Text('Save'),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 'save');
    });
  });

  group('snackbar', () {
    testWidgets('it names the action and clears after three seconds',
        (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () =>
                showNvSnackbar(context: context, message: 'Session saved'),
            child: const Text('log'),
          ),
        ),
      );

      await tester.tap(find.text('log'));
      await tester.pump();
      expect(find.text('Session saved'), findsOneWidget);

      // Three seconds of life, then the exit animation. Pumped in small
      // steps rather than one long jump: the dismissal needs real frames to
      // run its reverse animation through, and a single pump(4s) advances
      // the clock without giving it any.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Session saved'), findsNothing,
          reason: 'section 8 auto-dismisses a snackbar after three seconds');
    });

    testWidgets('it paints onSurface with surface text', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () =>
                showNvSnackbar(context: context, message: 'Session saved'),
            child: const Text('log'),
          ),
        ),
      );

      await tester.tap(find.text('log'));
      await tester.pump();

      final colors =
          Theme.of(tester.element(find.text('Session saved'))).colorScheme;
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.backgroundColor, colors.onSurface);
      expect(
        tester.widget<Text>(find.text('Session saved')).style?.color,
        colors.surface,
      );
    });
  });

  group('destructive dialog', () {
    Future<bool?> open(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async {
              result = await showNvDestructiveDialog(
                context: context,
                title: 'Discard session?',
                body: 'Two logged sets will be lost.',
                confirmLabel: 'Discard',
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('the cancel label can name what declining does',
        (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () => showNvDestructiveDialog(
              context: context,
              title: 'Discard session?',
              body: 'Two logged sets will be lost.',
              confirmLabel: 'Discard',
              cancelLabel: 'Keep going',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Section 8: a button label is a verb that says exactly what happens.
      // "Keep going" says it; "Cancel" only says what does not.
      expect(find.widgetWithText(NvButton, 'Keep going'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('it has 32dp corners', (tester) async {
      await open(tester);

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, 32);
    });

    testWidgets('the confirm label is the verb, inked as danger',
        (tester) async {
      await open(tester);

      expect(find.widgetWithText(NvButton, 'Discard'), findsOneWidget);
      final semantics = LockoutSemantics.of(
        tester.element(find.widgetWithText(NvButton, 'Discard')),
      );
      final label = tester.widget<Text>(find.text('Discard'));
      expect(label.style?.color, semantics.danger,
          reason: 'danger is the destructive role; error is for an invalid '
              'form field');
    });

    testWidgets('confirming resolves true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async {
              result = await showNvDestructiveDialog(
                context: context,
                title: 'Discard session?',
                body: 'Two logged sets will be lost.',
                confirmLabel: 'Discard',
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancelling resolves false, and so does a dismissal',
        (tester) async {
      bool? result;
      await tester.pumpWidget(
        _host(
          (context) => TextButton(
            onPressed: () async {
              result = await showNvDestructiveDialog(
                context: context,
                title: 'Discard session?',
                body: 'Two logged sets will be lost.',
                confirmLabel: 'Discard',
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse,
          reason: 'never null: a caller must not be able to treat a '
              'dismissal as a confirmation by forgetting a null check');
    });
  });
}
