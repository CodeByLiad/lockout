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

  testWidgets('the field announces its label as its own accessible name',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Target weight', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A visual label sitting beside the field names nothing: the editable
    // node is what a screen reader focuses, and it must carry the name
    // itself or it announces as an unnamed edit box.
    final data =
        tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.label, 'Target weight');
  });

  testWidgets('the label is announced once, not twice', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(label: 'Target weight', controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The visible Text exists to name the field; once the name is on the
    // field it must not also stand alone in the traversal, or a reader
    // announces "Target weight" and then an edit box called the same thing.
    expect(find.bySemanticsLabel('Target weight'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Target weight')).getSemanticsData().label,
      isNot('Target weight'),
      reason: 'the visible label still carries a node of its own',
    );
  });

  testWidgets('an error reaches the field semantics, not just the pixels',
      (tester) async {
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

    // Material puts `InputDecoration.errorText` on the field node's hint;
    // this field keeps its own error Text for layout reasons, so it has to
    // put the error there itself.
    final data =
        tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.hint, contains('Enter a number'));
  });

  testWidgets('an error turns the border error-coloured', (tester) async {
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

    final colors = Theme.of(tester.element(find.byType(TextField))).colorScheme;
    final decoration =
        tester.widget<TextField>(find.byType(TextField)).decoration!;
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      colors.error,
      reason: 'an error the field itself does not wear reads as no error',
    );
  });

  testWidgets('no error leaves the border neutral', (tester) async {
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

    final colors = Theme.of(tester.element(find.byType(TextField))).colorScheme;
    final decoration =
        tester.widget<TextField>(find.byType(TextField)).decoration!;
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      colors.outline,
    );
  });
}
