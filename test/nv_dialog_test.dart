import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_dialog.dart';

import 'test_helpers.dart';

Future<bool?> _open(WidgetTester tester) async {
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
    await _open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('confirming names the action it performs', (tester) async {
    await _open(tester);
    expect(find.text('Clear data'), findsOneWidget,
        reason: 'the confirm label is a verb that says what happens');
  });
}
