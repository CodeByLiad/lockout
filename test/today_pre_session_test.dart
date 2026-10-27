import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'package:lockout/theme/cookie_border.dart';
import 'package:lockout/theme/lockout_semantics.dart';
import 'package:lockout/widgets/house/nv_cards.dart';
import 'package:lockout/widgets/house/nv_empty_state.dart';
import 'package:lockout/widgets/house/nv_grouped_list.dart';
import 'package:lockout/widgets/house/nv_hero_card.dart';
import 'package:lockout/widgets/house/nv_icon_tile.dart';

import 'test_helpers.dart';

// Today's pre-session surface, rebuilt from the house catalog.
//
// This suite carries forward the intent of `home_tab_test.dart` and
// `home_composition_test.dart`: those assert what the HOME surface says and
// how it paints, against `HomeHub`. Today no longer builds `HomeHub`, so the
// same questions are asked of the screen that replaced it.

Widget _hostedTodayTab({bool foodTabEnabled = true}) => MaterialApp(
      theme: lockoutTestTheme(),
      home: TodayTab(foodTabEnabled: foodTabEnabled),
    );

Future<void> _seedTrainingDayToday({int exercises = 2}) async {
  final db = DatabaseService.instance;
  await db.insertRoutine(Routine(
    id: 'r1',
    name: 'Split',
    schedulingMode: SchedulingMode.weekday,
    createdAt: '2026-01-01T00:00:00.000',
  ).toMap());
  await db.insertDay(TrainingDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Legs',
    tag: ScheduleService.weekdayCode(DateTime.now()),
    orderIndex: 0,
  ).toMap());
  for (var i = 0; i < exercises; i++) {
    await db.insertExercise(ExerciseDef(
      id: 'e$i',
      dayId: 'd1',
      name: 'Exercise $i',
      targetSets: 3,
      targetRepsMin: 8,
      targetRepsMax: 8,
    ).toMap());
  }
  await db.setActiveRoutine('r1');
}

/// A training day scheduled for today with no exercises on it yet.
Future<void> _seedEmptyTrainingDayToday() async {
  final db = DatabaseService.instance;
  await db.insertRoutine(Routine(
    id: 'r1',
    name: 'Split',
    schedulingMode: SchedulingMode.weekday,
    createdAt: '2026-01-01T00:00:00.000',
  ).toMap());
  await db.insertDay(TrainingDay(
    id: 'd1',
    routineId: 'r1',
    name: 'Legs',
    tag: ScheduleService.weekdayCode(DateTime.now()),
    orderIndex: 0,
  ).toMap());
  await db.setActiveRoutine('r1');
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  group('a training day', () {
    testWidgets('leads with the hero card, not a stack of cards',
        (tester) async {
      await _seedTrainingDayToday();
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.byType(NvHeroCard), findsOneWidget,
          reason: 'section 8 allows at most one hero card per screen, and '
              'Today has one thing to lead with');
    });

    testWidgets('the day marker is a lobed shape reading as training',
        (tester) async {
      await _seedTrainingDayToday();
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NvHeroCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((decorated.decoration as ShapeDecoration).shape,
          CookieBorder.training);
    });

    testWidgets("the day's exercises are one grouped list", (tester) async {
      await _seedTrainingDayToday(exercises: 3);
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.text('Exercise 0'), findsOneWidget);
      expect(find.text('Exercise 2'), findsOneWidget);
      expect(find.byType(NvGroupedList), findsWidgets);
    });

    testWidgets('it offers one accent action and one tonal one',
        (tester) async {
      await _seedTrainingDayToday();
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.text('Start session'), findsOneWidget);
      expect(find.text('Custom session'), findsOneWidget);
    });
  });

  group('a rest day', () {
    testWidgets('it invites an action instead of apologising',
        (tester) async {
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.byType(NvEmptyState), findsOneWidget);
      expect(find.text('Start session'), findsNothing,
          reason: 'there is no scheduled session to start');
    });

    testWidgets('the marker reads as rest', (tester) async {
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NvHeroCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
          (decorated.decoration as ShapeDecoration).shape, CookieBorder.rest);
    });
  });

  group('a training day with no exercises', () {
    testWidgets('it says so in a TBA card and still offers a custom session',
        (tester) async {
      await _seedEmptyTrainingDayToday();
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.byType(NvTbaCard), findsOneWidget);
      expect(find.text('Start session'), findsNothing);
      expect(find.text('Custom session'), findsOneWidget);
    });
  });

  group('the screen says each thing once', () {
    testWidgets('a rest day does not repeat itself', (tester) async {
      // Device QA M1: the hero said "Nothing scheduled / 0 sets / Custom
      // session" and the empty state directly below said the same thing
      // again, with a second button doing the same job.
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.textContaining('Custom session'), findsOneWidget,
          reason: 'one way to start an off-plan session, not two');
      expect(find.text('0'), findsNothing,
          reason: "a rest day has no count worth the screen's one "
              'display-scale number');
    });

    testWidgets('a training day names the day once', (tester) async {
      // Device QA M2: the screen title and the hero title both read "Push".
      await _seedTrainingDayToday();
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.text('Legs'), findsOneWidget);
    });
  });

  group('the quick actions', () {
    testWidgets('each action is an icon tile', (tester) async {
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.byType(NvIconTile), findsWidgets);
      expect(find.text('Weigh in'), findsOneWidget);
    });

    testWidgets('the heading is sentence case', (tester) async {
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsNothing,
          reason: 'the device pass caught this exact string last time');
    });

    testWidgets('the food tile goes when the Food tab is off',
        (tester) async {
      await tester.pumpWidget(_hostedTodayTab(foodTabEnabled: false));
      await settle(tester);

      expect(find.text('Log food'), findsNothing,
          reason: 'a tile that taps to a hidden tab would do nothing');
    });

    // QA ruling 2. The tiles were painted `semantics.categoryAt(0)` through
    // `categoryAt(7)` - grid position fed straight into an index. The ramp
    // exists to keep *categories* apart, and there are no categories here:
    // index 0 is "Log food" only because it is first. Worse, the same eight
    // values mean "routine day category" on the Workout tab, so "Log food"
    // and some Tuesday shared a colour asserting a relationship neither
    // has. The icon and the label already identify the action.
    testWidgets('every tile takes one neutral fill, never a ramp colour',
        (tester) async {
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      final tiles =
          tester.widgetList<NvIconTile>(find.byType(NvIconTile)).toList();
      expect(tiles, hasLength(8));

      final context = tester.element(find.byType(NvIconTile).first);
      final colors = Theme.of(context).colorScheme;
      final ramp = LockoutSemantics.of(context).categoryRamp;

      expect(tiles.map((t) => t.color).toSet(), {colors.inverseSurface},
          reason: 'one fill for all eight, and the one neutral that stands '
              'clear of the surface behind it in both brightnesses');
      expect(tiles.where((t) => ramp.contains(t.color)), isEmpty,
          reason: 'a quick action is not a day category; re-keying the ramp '
              'on grid position is the defect this guards');
    });

    testWidgets('the tile fill is resolved from the scheme, not a literal',
        (tester) async {
      Color fill() => tester.widget<NvIconTile>(
            find.byType(NvIconTile).first,
          ).color;

      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);
      final dark = fill();

      await tester.pumpWidget(MaterialApp(
        theme: lockoutTestTheme(lightAppearance),
        home: TodayTab(),
      ));
      await settle(tester);

      expect(fill(), isNot(dark),
          reason: 'a hardcoded colour would survive the brightness switch');
      expect(
        fill(),
        Theme.of(tester.element(find.byType(NvIconTile).first))
            .colorScheme
            .inverseSurface,
      );
    });
  });

  group("today's numbers", () {
    // Carried over from home_composition_test.dart: the hub stated the
    // weight, the gap, the trend and the intake. None of that is styling, so
    // none of it may be lost when the composition changes.
    testWidgets('it states the weight and the calories', (tester) async {
      final db = DatabaseService.instance;
      await db.saveSetting('calorie_target', '2300');
      await db.insertBodyLog(BodyEntry(
        id: 'b1',
        dateStr: ScheduleService.dateKey(DateTime.now()),
        weightKg: 72.4,
      ).toMap());

      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.textContaining('72.4'), findsWidgets);
      expect(find.textContaining('kcal'), findsWidgets);
    });

    testWidgets('no weight on record prompts instead of showing a number',
        (tester) async {
      await tester.pumpWidget(_hostedTodayTab());
      await settle(tester);

      expect(find.textContaining('No weight'), findsOneWidget);
    });

    testWidgets('the nutrition rows go when the Food tab is off',
        (tester) async {
      await tester.pumpWidget(_hostedTodayTab(foodTabEnabled: false));
      await settle(tester);

      // By row, not by the string 'kcal': the burn row is not nutrition and
      // stays, so asserting on the unit would couple this to the wrong thing.
      expect(find.text('Calories'), findsNothing,
          reason: 'the whole nutrition block goes rather than showing values '
              'the user cannot act on');
      expect(find.text('Protein'), findsNothing);
    });
  });
}
