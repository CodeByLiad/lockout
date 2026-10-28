import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_dialog.dart';

import 'test_helpers.dart';

Future<bool?> _open(
  WidgetTester tester, {
  Future<void> Function(WidgetTester tester)? dismiss,
}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: lockoutTestTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showNvDestructiveDialog(
                context: context,
                title: 'Clear all data?',
                body: 'Every logged session and weigh-in is removed. This '
                    'cannot be undone.',
                confirmLabel: 'Clear data',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (dismiss != null) {
    await dismiss(tester);
    await tester.pumpAndSettle();
  }
  return result;
}

void main() {
  testWidgets('it has 32dp corners', (tester) async {
    await _open(tester);
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final shape = dialog.shape! as RoundedRectangleBorder;
    expect((shape.borderRadius as BorderRadius).topLeft.x, 32);
  });

  testWidgets('cancelling resolves false', (tester) async {
    final result = await _open(
      tester,
      dismiss: (tester) => tester.tap(find.text('Cancel')),
    );
    expect(find.byType(Dialog), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('confirming names the action it performs', (tester) async {
    await _open(tester);
    expect(find.text('Clear data'), findsOneWidget,
        reason: 'the confirm label is a verb that says what happens');
  });

  testWidgets('confirming resolves true', (tester) async {
    final result = await _open(
      tester,
      dismiss: (tester) => tester.tap(find.text('Clear data')),
    );
    expect(find.byType(Dialog), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('dismissing via the barrier resolves false, not null',
      (tester) async {
    final result = await _open(
      tester,
      dismiss: (tester) => tester.tapAt(const Offset(10, 10)),
    );
    expect(find.byType(Dialog), findsNothing);
    expect(result, isFalse);
    expect(result, isNot(isNull));
  });
}
