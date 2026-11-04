import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_text_field.dart';
import 'test_helpers.dart';

void main() {
  Future<TextEditingController> pumpField(
    WidgetTester t, {
    String? error,
  }) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: NvTextField(
            label: 'Reps',
            controller: c,
            hintText: '8',
            errorText: error,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return c;
  }

  testWidgets('filled field carries a label, hint and readable touch target', (
    t,
  ) async {
    await pumpField(t);
    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.labelText, 'Reps');
    expect(field.decoration!.hintText, '8');
    expect(field.decoration!.filled, isTrue);
    expect(t.getSize(find.byType(TextField)).height, greaterThanOrEqualTo(48));
  });
  testWidgets('focus changes shape and accepts typed input', (t) async {
    final c = await pumpField(t);
    final before =
        t.widget<TextField>(find.byType(TextField)).decoration!.enabledBorder!
            as UnderlineInputBorder;
    await t.enterText(find.byType(TextField), '12');
    await t.pumpAndSettle();
    final after =
        t.widget<TextField>(find.byType(TextField)).decoration!.focusedBorder!
            as UnderlineInputBorder;
    expect(after.borderRadius, isNot(before.borderRadius));
    expect(c.text, '12');
  });
  testWidgets('error is visible and available to assistive technology', (
    t,
  ) async {
    await pumpField(t, error: 'Enter a number');
    expect(find.text('Enter a number'), findsOneWidget);
    final data = t.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.hint, contains('Enter a number'));
  });
  testWidgets('a long error expands without clipping at large text', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpField(
      t,
      error: 'Enter a valid number of repetitions before saving this exercise.',
    );
    expect(t.takeException(), isNull);
  });
}
