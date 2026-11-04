import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';

import 'package:lockout/screens/food_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/widgets/meal_section.dart';
import 'package:lockout/widgets/progress_hero.dart';

import 'test_helpers.dart';

FoodEntry _entry(String name, int kcal, String slot) => FoodEntry(
  id: name,
  dateStr: '2026-09-09',
  mealSlot: slot,
  name: name,
  kcal: kcal,
  proteinG: 10.0,
  carbG: 20.0,
  fatG: 5.0,
);

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  group('mealSubtotalKcal', () {
    test('sums the entries', () {
      expect(
        mealSubtotalKcal([
          _entry('Paratha', 354, 'Breakfast'),
          _entry('Cheese Omelette', 225, 'Breakfast'),
        ]),
        579,
      );
    });

    test('an empty meal is zero', () {
      expect(mealSubtotalKcal(const []), 0);
    });
  });

  group('ProgressHero', () {
    testWidgets('renders its text and clamps an over-target progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: ProgressHero(
              eyebrow: 'TODAY',
              title: '1240 / 1850 kcal',
              subtitle: '610 left',
              progress: 1.8,
              accent: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('1240 / 1850 kcal'), findsOneWidget);
      expect(find.text('610 left'), findsOneWidget);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0);
    });

    testWidgets('a negative progress clamps to zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: ProgressHero(
              eyebrow: 'TODAY',
              title: '0 / 1850 kcal',
              subtitle: '1850 left',
              progress: -3.0,
              accent: Colors.orange,
            ),
          ),
        ),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.0);
    });
  });

  group('MealSection', () {
    testWidgets('shows the title, subtotal and every entry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSection(
              title: 'Breakfast',
              entries: [
                _entry('Paratha', 354, 'Breakfast'),
                _entry('Cheese Omelette', 225, 'Breakfast'),
              ],
              onDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('579 kcal'), findsOneWidget);
      expect(find.text('Paratha'), findsOneWidget);
      expect(find.text('Cheese Omelette'), findsOneWidget);
      // Q4: an entry row carries its own unit, same as v1's
      // "'${food.kcal} kcal'" — a bare integer next to "P 10 C 20 F 5" is
      // ambiguous about what it is measuring.
      expect(find.text('354 kcal'), findsOneWidget);
      expect(find.text('225 kcal'), findsOneWidget);
    });

    testWidgets('an empty meal renders nothing at all', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSection(
              title: 'Snacks',
              entries: const [],
              onDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('SNACKS'), findsNothing);
    });

    testWidgets('deleting an entry reports it', (tester) async {
      FoodEntry? deleted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSection(
              title: 'Lunch',
              entries: [_entry('Dal Bhat', 374, 'Lunch')],
              onDelete: (e) => deleted = e,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(deleted?.name, 'Dal Bhat');
    });

    // C1: the old row used a ~40x40 `IconButton`; the rewrite shrank the
    // affordance to a bare 16x16 `Icon` and only made it register taps
    // everywhere within that 16x16 box (`HitTestBehavior.opaque` does not
    // enlarge the box it is applied to). `tester.tap` hits the widget's
    // centre regardless of its size, so the test above cannot catch a
    // shrunk hit target — this test measures the actual tappable area
    // instead, against a 40dp floor (16dp icon + 12dp padding each side,
    // third-round review Finding 8 — matches BODY's delete affordance
    // exactly instead of falling short at ~36dp).
    testWidgets('the delete affordance has at least a 40dp tappable area', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSection(
              title: 'Lunch',
              entries: [_entry('Dal Bhat', 374, 'Lunch')],
              onDelete: (_) {},
            ),
          ),
        ),
      );

      final detector = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(GestureDetector),
      );
      expect(detector, findsOneWidget);
      final size = tester.getSize(detector);
      expect(size.width, greaterThanOrEqualTo(40));
      expect(size.height, greaterThanOrEqualTo(40));
    });

    // Q1: macro rounding must not manufacture precision in either
    // direction — 0.4g logged protein must not render as a measured zero,
    // and an exact whole number must not sprout a fake ".0".
    testWidgets('macros keep one decimal place instead of rounding to a '
        'false zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSection(
              title: 'Snacks',
              entries: [
                FoodEntry(
                  id: 'partial',
                  dateStr: '2026-09-09',
                  mealSlot: 'Snacks',
                  name: 'Half a Banana',
                  kcal: 45,
                  proteinG: 0.4,
                  carbG: 12.6,
                  fatG: 0.0,
                ),
              ],
              onDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('P 0.4  C 12.6  F 0'), findsOneWidget);
    });
  });

  for (final calories in [0, 800, 2500]) {
    testWidgets(
      'daily journal reflects $calories kcal against the stored target',
      (t) async {
        final today = DateTime.now().toIso8601String().split('T').first;
        if (calories > 0) {
          await DatabaseService.instance.insertFoodLog(
            FoodEntry(
              id: 'f',
              dateStr: today,
              mealSlot: 'Breakfast',
              name: 'Oats',
              kcal: calories,
              proteinG: 0.4,
            ).toMap(),
          );
        }
        await t.binding.setSurfaceSize(const Size(600, 2400));
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(
          MaterialApp(theme: lockoutTestTheme(), home: FoodTab()),
        );
        await settle(t);
        expect(find.text('$calories'), findsOneWidget);
        expect(
          find.textContaining(calories > 2200 ? 'over' : 'left'),
          findsWidgets,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unknown meal slots remain visible and can be undone after deletion',
    (t) async {
      final db = DatabaseService.instance;
      final today = DateTime.now().toIso8601String().split('T').first;
      await db.insertFoodLog(
        FoodEntry(
          id: 'odd',
          dateStr: today,
          mealSlot: 'Picnic',
          name: 'Apple',
          kcal: 90,
          proteinG: 0.4,
        ).toMap(),
      );
      final before = await db.getFoodLogsForDate(today);
      await t.binding.setSurfaceSize(const Size(600, 4000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(theme: lockoutTestTheme(), home: FoodTab()),
      );
      await settle(t);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      await t.tap(find.byTooltip('Delete Apple'));
      await settle(t);
      expect(await db.getFoodLogsForDate(today), isEmpty);
      await t.tap(find.text('Undo'));
      await settle(t);
      expect(await db.getFoodLogsForDate(today), before);
      await t.pump(const Duration(seconds: 6));
    },
  );
}
