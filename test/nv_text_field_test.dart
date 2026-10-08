import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_text_field.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('the label sits above the field, not inside it',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Reps', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelY = tester.getTopLeft(find.text('Reps')).dy;
    final fieldY = tester.getTopLeft(find.byType(TextField)).dy;
    expect(labelY, lessThan(fieldY));
  });

  testWidgets('it is 56dp tall', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Reps', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextField)).height, 56);
  });

  testWidgets('an error renders below the field', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(
            label: 'Reps',
            controller: controller,
            errorText: 'Enter a number',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Enter a number')).dy,
      greaterThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('a hint renders inside the field', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(
            label: 'Reps',
            controller: controller,
            hintText: '5',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('no hint renders no hint', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Reps', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decoration =
        tester.widget<TextField>(find.byType(TextField)).decoration;
    expect(decoration?.hintText, isNull);
  });
}
