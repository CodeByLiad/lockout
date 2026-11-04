import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lockout/data/food_library.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/exercise_picker.dart';
import 'package:lockout/widgets/food_picker.dart';

import 'test_helpers.dart';

/// The only thing that used to exercise either picker was
/// `food_tab_test.dart`'s `openLogForm` helper, and its own docstring says
/// it deliberately avoids the catalog path — the servings stepper, the
/// category chips and the touch-target rule on the chip strip had no
/// dedicated coverage at all. This suite drives both pickers directly from a
/// stub button, the way the real screens do.
void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  /// Pumps a single button whose `onPressed` awaits [showFoodPicker] and
  /// stashes the result, so a test can assert on the value that actually
  /// comes back through the future — the save path — not just what the
  /// stepper painted along the way.
  Future<_Holder<PickedFood>> pumpFoodPicker(WidgetTester tester) async {
    final holder = _Holder<PickedFood>();
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                holder.value = await showFoodPicker(context);
                holder.completed = true;
              },
              child: const Text('open food picker'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open food picker'));
    await tester.pumpAndSettle();
    return holder;
  }

  Future<_Holder<PickedExercise>> pumpExercisePicker(
    WidgetTester tester,
  ) async {
    final holder = _Holder<PickedExercise>();
    await tester.pumpWidget(
      MaterialApp(
        theme: lockoutTestTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                holder.value = await showExercisePicker(context);
                holder.completed = true;
              },
              child: const Text('open exercise picker'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open exercise picker'));
    await tester.pumpAndSettle();
    return holder;
  }

  group('showFoodPicker', () {
    testWidgets(
      'catalog selection returns one serving for the single portion editor',
      (tester) async {
        final holder = await pumpFoodPicker(tester);
        await tester.tap(find.text('Full English Breakfast'));
        await tester.pumpAndSettle();
        expect(holder.completed, isTrue);
        expect(holder.value!.name, 'Full English Breakfast');
        expect(
          holder.value!.kcal,
          FoodLibrary.byCategory(
            'Breakfast',
          ).firstWhere((f) => f.name == 'Full English Breakfast').kcal,
        );
      },
    );
    testWidgets('category selection narrows real catalog results', (
      tester,
    ) async {
      await pumpFoodPicker(tester);
      expect(find.text('${FoodLibrary.all.length} foods'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Breakfast'));
      await tester.pumpAndSettle();
      expect(
        find.text('${FoodLibrary.byCategory('Breakfast').length} foods'),
        findsOneWidget,
      );
      expect(find.text('Full English Breakfast'), findsOneWidget);
    });
    testWidgets('the category chip and a catalog row both meet the 48dp touch '
        'target', (tester) async {
      await pumpFoodPicker(tester);

      final chipSize = tester.getSize(find.byType(ChoiceChip).first);
      expect(
        chipSize.height,
        greaterThanOrEqualTo(LockoutTheme.minTouchTarget),
        reason:
            'the chip strip is a bare SizedBox(height: 40) pre-fix, '
            'clamping the ChoiceChip below LockoutTheme.minTouchTarget (48)',
      );

      final rowSize = tester.getSize(
        find.ancestor(
          of: find.text('Full English Breakfast'),
          matching: find.byType(InkWell),
        ),
      );
      expect(rowSize.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
    });
  });

  group('showExercisePicker', () {
    testWidgets('the muscle group chip also meets the 48dp touch target', (
      tester,
    ) async {
      await pumpExercisePicker(tester);

      final chipSize = tester.getSize(find.byType(ChoiceChip).first);
      expect(
        chipSize.height,
        greaterThanOrEqualTo(LockoutTheme.minTouchTarget),
        reason: 'exercise_picker.dart shares the same 40dp SizedBox bug',
      );
    });
  });
}

class _Holder<T> {
  T? value;
  bool completed = false;
}
