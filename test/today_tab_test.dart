import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/schedule_service.dart';
import 'package:lockout/theme/cookie_border.dart';
import 'package:lockout/theme/lockout_motion.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/house/nv_hero_card.dart';
import 'package:lockout/widgets/house/nv_icon_tile.dart';

import 'test_helpers.dart';

/// Hosts `TodayTab` under the app's real theme — every test below opens a
/// live session, which reads `LockoutSemantics`/`LockoutTheme`, so a bare
/// `MaterialApp` is not enough.
Widget hostedTodayTab() =>
    MaterialApp(theme: lockoutTestTheme(), home: TodayTab());

/// Seeds one active weekday routine with a training day scheduled for today
/// and a single exercise, so `_startScheduledSession` has something to start.
/// Shared by every live-session test below rather than repeated per test.
Future<void> seedActiveWeekdayRoutineForToday({double targetWeightKg = 0}) async {
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
  await db.insertExercise(ExerciseDef(
    id: 'e1',
    dayId: 'd1',
    name: 'Back Squat',
    targetSets: 2,
    targetRepsMin: 8,
    targetRepsMax: 8,
    targetWeightKg: targetWeightKg,
  ).toMap());
  await db.setActiveRoutine('r1');
}

/// Direct coverage for the `TodayTab` wiring the two fix waves touched:
/// Ruling B's empty-day guard, the `foodTabEnabled` null-callback path, the
/// `_finishSession` summary refresh (including the ESTIMATE UNAVAILABLE /
/// NO SESSION YET split), and the `_isLoading` sequencing. All of these
/// depend on `ScheduleService` and `GoalService`, which read the real
/// database — there is no way to build a meaningful `TodayTab` in these
/// scenarios without one, unlike `HomeHub` itself (which is why `HomeHub`
/// stays presentation-only and gets tested with no database at all in
/// `home_tab_test.dart`). `settle` (the bounded-pump helper, since
/// `pumpAndSettle` never terminates while a `CircularProgressIndicator`'s
/// indeterminate animation is on screen) lives in `test_helpers.dart`,
/// shared with `routines_tab_test.dart`.
void main() {
  setUpAll(() {
    // `testWidgets`' fake-async zone never lets a *file-backed* sqflite
    // database finish opening in this environment — confirmed by isolating
    // the call: the identical `openDatabase` resolves instantly under a
    // plain `test()` (every other DB-backed suite in this repo uses one),
    // and resolves instantly here too once given an in-memory path instead.
    // `databaseFactoryFfiNoIsolate` avoids a second, unrelated hang from the
    // default factory's background-isolate round trip inside that same zone.
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseService.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    await wipeDatabaseAndReseed(DatabaseService.instance);
  });

  final today = ScheduleService.dateKey(DateTime.now());
  final todayCode = ScheduleService.weekdayCode(DateTime.now());

  group('Ruling B - empty scheduled day', () {
    testWidgets(
        'a training day scheduled today with zero exercises offers no live '
        'START SESSION, shows Routines-tab guidance, and still allows '
        'CUSTOM SESSION', (tester) async {
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
        tag: todayCode,
        orderIndex: 0,
      ).toMap());
      // Deliberately no exercises inserted for 'd1'.
      await db.setActiveRoutine('r1');

      await tester.pumpWidget(MaterialApp(theme: lockoutTestTheme(), home: TodayTab()));
      await settle(tester);

      expect(find.text('Start session'), findsNothing);
      expect(find.text('Custom session'), findsOneWidget);
      expect(
        find.textContaining('Add them on the Routines tab'),
        findsOneWidget,
      );
    });
  });

  group('foodTabEnabled', () {
    testWidgets(
        'false hides the CALORIES row and the LOG FOOD quick action, and '
        'the null onNavigate does not crash when a tile is tapped',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: lockoutTestTheme(),
        home: TodayTab(foodTabEnabled: false),
      ));
      await settle(tester);

      expect(find.text('Calories'), findsNothing);
      expect(find.text('Log food'), findsNothing);

      // onNavigate is null (the default for a tab pumped on its own). The
      // Weigh in tile's onTap is `() => go?.call('progress', ...)`, which must
      // no-op rather than throw when `go` is null.
      await tester.tap(find.text('Weigh in'));
      await settle(tester, maxPumps: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('_finishSession summary refresh', () {
    testWidgets(
        'a session saved with no bodyweight on record reads ESTIMATE '
        'UNAVAILABLE afterwards, not NO SESSION YET (the session was not '
        'lost, only its estimate)', (tester) async {
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
        tag: todayCode,
        orderIndex: 0,
      ).toMap());
      await db.insertExercise(ExerciseDef(
        id: 'e1',
        dayId: 'd1',
        name: 'Back Squat',
        targetSets: 1,
        targetRepsMin: 5,
        targetRepsMax: 5,
      ).toMap());
      await db.setActiveRoutine('r1');
      // No bodyweight logged and no target weight configured, so
      // EnergyEstimator.estimate() cannot produce a figure.

      await tester.pumpWidget(MaterialApp(theme: lockoutTestTheme(), home: TodayTab()));
      await settle(tester);

      // Burn is a row of its own again now that Today composes from grouped
      // lists, so "no session today" is that row saying so — not the absence
      // of the word kcal, which the calories row also carries.
      expect(find.text('No session logged yet'), findsOneWidget);
      expect(find.textContaining('Estimate unavailable'), findsNothing);

      await tester.tap(find.text('Start session'));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await settle(tester, maxPumps: 4);

      await tester.tap(find.text('Finish'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      // Back on the hub: the session was saved (proved by the assertion
      // below), but with no bodyweight on record no estimate could be made.
      expect(find.textContaining('Estimate unavailable'), findsOneWidget);

      final saved = await db.getSessionLogsForDate(today);
      expect(saved.length, 1);
      expect(saved.first['kcal_burned'], 0.0);
    });
  });

  // Finishing a session is the only place set data is ever produced, and it
  // wrote two tables back to back with nothing joining them: a kill between
  // the header insert and the sets — a low-memory process death right after
  // a workout, when the app is most likely to be backgrounded — left a
  // header claiming `totalSets: N` with nothing behind it. That is the same
  // state `deleteSessionLog` and `restoreSessionLog` were given
  // transactions to prevent, on the argument that a detail-free header is
  // indistinguishable from a legitimately detail-free entry.
  //
  // The rollback itself is proved against a forced mid-transaction failure
  // in `database_service_test.dart`; driving the same failure through this
  // screen cannot be done, because the rejection surfaces as an unhandled
  // async error out of the button callback and `flutter_test` fails a test
  // the moment one is raised, before any assertion can run. This reads the
  // call site instead — the same structural idiom `settings_restyle_test`
  // uses for the v2 style sweep — so re-splitting the write into two
  // unguarded calls fails here even though every behavioural test passes.
  group('_finishSession writes atomically', () {
    test('the finish path goes through the transactional write', () {
      final source = File('lib/screens/today_tab.dart').readAsStringSync();

      expect(source, contains('insertSessionWithSets('),
          reason: 'the session and its sets must be written in one '
              'transaction');
      expect(source, isNot(contains('insertSetLogs(')),
          reason: 'a second, separate set write reopens the gap');
      expect(source, isNot(contains('insertSessionLog(')),
          reason: 'a bare header write reopens the gap');
    });
  });

  group('_isLoading sequencing', () {
    testWidgets(
        'renders real values, not the not-on-record prompts, once both the '
        'schedule and the summary have loaded', (tester) async {
      final db = DatabaseService.instance;
      await db.insertBodyLog(BodyEntry(
        id: 'b1',
        dateStr: today,
        weightKg: 80.0,
      ).toMap());
      await db.insertFoodLog(FoodEntry(
        id: 'f1',
        dateStr: today,
        mealSlot: 'Breakfast',
        name: 'Oats',
        kcal: 400,
      ).toMap());
      await db.insertSessionLog(SessionLog(
        id: 's1',
        dayName: 'Legs',
        dateStr: today,
        durationSeconds: 1800,
        totalVolumeKg: 1000,
        status: 'completed',
        kcalBurned: 300.0,
      ).toMap());

      await tester.pumpWidget(MaterialApp(theme: lockoutTestTheme(), home: TodayTab()));
      await settle(tester);

      // A single weigh-in: a value, but no delta yet.
      expect(find.textContaining('No weight'), findsNothing);
      // The weight row states the figure and its unit in one supporting
      // line now; the display-scale number on this screen is the hero's set
      // count, and section 8 allows only one of those.
      expect(find.textContaining('80.0 kg'), findsOneWidget);
      expect(find.textContaining('Estimate unavailable'), findsNothing);
      expect(find.textContaining('300 kcal'), findsOneWidget);

      // Verifying the two loads race-free in the single frame right after
      // `_isLoading` clears would need a controlled clock around the two
      // chained `await`s inside `reload()`; pumping a specific frame count
      // to land exactly there is inherently timing-dependent and would be
      // flaky rather than a real guarantee. The outcome above — real values
      // rendered, never a prompt for data that exists — is what that
      // sequencing exists to guarantee, and is what is verified here.
    });
  });

  // TODAY does not hydrate these two rows through a model factory — it folds
  // the raw maps itself — so the tolerant reads added to `SessionLog.fromMap`
  // and `FoodEntry.fromMap` do not cover it. Same restore vector, same
  // `_loadSummary()` shape: the cast threw before `setState`, and the hub sat
  // on its spinner with no route off it.
  group('a poisoned row does not strand the hub', () {
    testWidgets('text in kcal and kcal_burned counts as zero, not a throw',
        (tester) async {
      final db = DatabaseService.instance;
      final database = await db.database;
      // Raw inserts: every typed path coerces on the way in.
      await database.insert('food_logs', {
        'id': 'f1',
        'date_str': today,
        'meal_slot': 'Breakfast',
        'name': 'Oats',
        'kcal': 'loads',
        'protein_g': 0.0,
        'carb_g': 0.0,
        'fat_g': 0.0,
      });
      await database.insert('session_logs', {
        'id': 's1',
        'day_name': 'Legs',
        'date_str': today,
        'duration_seconds': 1800,
        'total_volume_kg': 1000.0,
        'status': 'completed',
        'routine_id': '',
        'day_id': '',
        'total_sets': 4,
        'kcal_burned': 'loads',
      });

      await tester.pumpWidget(MaterialApp(theme: lockoutTestTheme(), home: TodayTab()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      // The session still happened, so the row must not claim otherwise —
      // only its unreadable estimate is lost.
      expect(find.text('No session yet'), findsNothing);
    });
  });

  group('the live session screen', () {
    testWidgets('session header shows elapsed time and exercise progress',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);

      await tester.tap(find.text('Start session'));
      await settle(tester);

      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('weight and rep steppers meet the 48dp touch target',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      for (final icon in [Icons.remove, Icons.add]) {
        for (final element in find.byIcon(icon).evaluate()) {
          final size = tester.getSize(find.byWidget(
            element.findAncestorWidgetOfExactType<IconButton>()!,
          ));
          expect(size.width, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
          expect(size.height, greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
        }
      }
    });

    testWidgets('the leg-safety notice renders in the warning role',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      expect(find.textContaining('Pain-free movement only'), findsOneWidget);
    });

    testWidgets('numeric columns use the mono family so digits align',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      final setNumber = tester.widget<Text>(find.text('1').first);
      expect(setNumber.style?.fontFamily, 'JetBrainsMono');
    });

    testWidgets('the header states duration and volume, and carries sets as '
        'the big number', (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      expect(find.text('Duration'), findsOneWidget);
      // The unit lives in the label, not the value, so a four-digit volume
      // has room to stay on-scale next to `Finish` at 360dp — see
      // `_buildSessionHeader`.
      expect(find.text('Volume (kg)'), findsOneWidget);
      // The sets figure moved out of the stat row and into the header's one
      // big number — the house document allows one big number per screen,
      // not the same figure stated twice.
      expect(find.text('Sets'), findsNothing);
      expect(find.textContaining('sets left'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('completing a set tints the whole row, not just the tick',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      Color? rowColour() {
        final box = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('set-row-0-0')),
        );
        return (box.decoration as BoxDecoration).color;
      }

      final before = rowColour();
      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await tester.pumpAndSettle();

      expect(rowColour(), isNot(before));
    });

    // The default test viewport is 800x600 — wide enough that a set row's
    // fixed-width children never come close to overflowing, which is why the
    // suite stayed green while the row genuinely overflowed on a real phone.
    // 360dp is the narrowest common Android width. Seeded with a multi-digit
    // weight (102.5kg, not the default 0) — a single-character value never
    // exercises `FittedBox`'s scale-down path, which is exactly how this test
    // missed the previous round's column-shimmer regression.
    testWidgets(
        'the set row does not overflow at a 360dp phone width, and a '
        'multi-digit weight renders at the same scale as the reps column',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await seedActiveWeekdayRoutineForToday(targetWeightKg: 102.5);
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      expect(tester.takeException(), isNull);

      // `tester.getSize` on the `Text` itself is not a usable regression
      // check here: `FittedBox` applies its scale as a paint transform, so
      // `RenderFittedBox.performLayout` lays the child out unbounded and
      // `getSize` returns that unscaled layout size — identical for '102.5'
      // and '8' by construction, whatever `FittedBox` actually does.
      // Assert on the layout budget the value is given instead: it is
      // font-independent, and it is exactly what regresses if the complete
      // tick ever moves back onto the steppers' line (see
      // `_buildSetRow`'s comment) — the value's slot narrows from its
      // capped 40dp down to whatever the tick's neighbour leaves it.
      final slot = tester.getSize(find.ancestor(
        of: find.text('102.5'),
        matching: find.byType(FittedBox),
      ).first);
      expect(slot.width, greaterThanOrEqualTo(40));
    });

    // The tint is a colour fade, which is the `effects` tier — 200ms and no
    // overshoot, because a colour that passes its target lands on a hue
    // nobody authored. Framework `Durations`/`Easing` tokens are not a
    // motion system; three shared tiers are.
    testWidgets('the completion tint fades on the effects tier',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      final fade = tester.widget<TweenAnimationBuilder<Color?>>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('set-row-0-0')),
              matching: find.byType(TweenAnimationBuilder<Color?>),
            )
            .first,
      );

      expect(fade.duration, LockoutMotion.effects.duration);
      expect(fade.curve, LockoutMotion.effects.curve);
    });

    // Reading the tier's `duration` directly would pass the test above and
    // still animate for someone who has asked the OS to stop animating —
    // an accessibility regression, not a flourish. Only
    // `durationFor(context)` collapses it.
    testWidgets(
        'the completion tint does not animate when the OS asks for no '
        'animation', (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(MaterialApp(
        theme: lockoutTestTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: TodayTab(),
          ),
        ),
      ));
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      final fade = tester.widget<TweenAnimationBuilder<Color?>>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('set-row-0-0')),
              matching: find.byType(TweenAnimationBuilder<Color?>),
            )
            .first,
      );

      expect(fade.duration, Duration.zero);
    });

    // The house document forbids all-caps labels outright (section 4.2,
    // deviation register D8), and a snackbar is display copy like any other.
    testWidgets('the save confirmation is sentence case', (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await settle(tester, maxPumps: 4);
      await tester.tap(find.text('Finish'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      final message = tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Text),
                )
                .first,
          )
          .data!;

      expect(message, startsWith('Session saved'));
      expect(message, isNot(message.toUpperCase()),
          reason: 'the house document forbids all-caps labels (section 4.2)');
    });

    testWidgets('the rest bar adjusts in both directions', (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await tester.pump();

      expect(find.text('-15s'), findsOneWidget);
      expect(find.text('+15s'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    // Restores the v1 per-set delete affordance: `Add set` gained a way
    // back once a user could add sets they did not mean to.
    testWidgets('a set can be removed, but never down to zero',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      expect(find.byKey(const ValueKey('set-row-0-1')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await settle(tester);

      expect(find.byKey(const ValueKey('set-row-0-1')), findsNothing);
      expect(find.byKey(const ValueKey('set-row-0-0')), findsOneWidget);

      // One set left: the guard disables the control rather than removing
      // the last row a session needs to log anything at all.
      final lastDelete = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byIcon(Icons.close),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(lastDelete.onPressed, isNull);
    });

    // Round-4 finding A: keying the completion tint's `TweenAnimationBuilder`
    // by loop position (`set-tween-$exerciseIndex-$setIndex`) is a no-op —
    // deleting a set renumbers the survivors, so `Element.updateChildren`
    // hands the surviving row the *old* completed row's animated element and
    // it flashes the success tint down to transparent over
    // `Durations.medium1` before settling on the colour it already held.
    // `ObjectKey(set)` fixes it by keying on the set's own identity instead
    // of its position.
    testWidgets('deleting a completed set does not tint the surviving row',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      // Let the completion tint finish animating in (Durations.medium1 is
      // 250ms) before deleting it. `settle`'s bounded pumps are safe here
      // even though marking a set complete also starts the rest countdown.
      await settle(tester, maxPumps: 6);

      // Deletes the now-completed set 0, leaving the never-logged set 1 as
      // the sole, surviving row (renumbered to position 0).
      await tester.tap(find.byIcon(Icons.close).first);
      // A single, zero-duration frame — not `settle`/`pumpAndSettle` — so a
      // 250ms false-"completed" flash on the surviving row is caught rather
      // than left to finish and hide.
      await tester.pump();

      final decoration = tester
          .widget<DecoratedBox>(find.byKey(const ValueKey('set-row-0-0')))
          .decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });

    // The finish sheet's Discard used to end a session with logged sets on
    // a single tap. It must now route through the same "Discard session?"
    // gate a zero-set session already gets from `_finishSession`.
    testWidgets(
        'Discard asks for confirmation once a set has been logged',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('set-complete-0-0')));
      await settle(tester, maxPumps: 4);

      await tester.tap(find.text('Finish'));
      await settle(tester);
      await tester.tap(find.text('Discard'));
      await settle(tester);

      expect(find.text('Discard session?'), findsOneWidget);
      // The copy must name what is actually lost — a session with a logged
      // set is real data, not the empty-draft case the dialog also serves.
      expect(
        find.text('1 logged set will be lost. Discard it?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep going'));
      await settle(tester);

      // Declining the confirmation must leave the session running, not end
      // it anyway.
      expect(find.text('Finish'), findsOneWidget);
    });
  });
  // Task 9's proof surface: the Today tab is where the expressive system has
  // to hold up end to end — the hero's signature outline, the one big
  // number, and the lobed register marker on a live session.
  group('the expressive system on the Today tab', () {
    testWidgets('the hero card wears the signature asymmetric outline',
        (tester) async {
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(NvHeroCard),
              matching: find.byType(Material),
            )
            .first,
      );
      final radius = ((material.shape! as RoundedRectangleBorder).borderRadius)
          as BorderRadius;

      expect(radius.topLeft.x, 36);
      expect(radius.topRight.x, 36);
      expect(radius.bottomRight.x, 36);
      expect(radius.bottomLeft.x, 12,
          reason: 'the bottom-left corner is the family signature');
    });

    testWidgets('the hero card does not morph on press', (tester) async {
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);

      Object? shapeNow() => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(NvHeroCard),
                  matching: find.byType(Material),
                )
                .first,
          )
          .shape;

      final before = shapeNow();
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(NvHeroCard)));
      await tester.pump(const Duration(milliseconds: 120));
      expect(shapeNow(), before, reason: 'a card has no pressed state');
      await gesture.up();
      await settle(tester);
    });

    testWidgets('the day line is sentence case', (tester) async {
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);

      // The hub's eyebrow became the screen's own supporting line when
      // Today was rebuilt from the catalog; the rule it was asserting —
      // section 4.2 forbids all-caps labels — did not change. The weekday
      // code inside it is stored data, not display copy, so the check is
      // that the line as a whole is not shouting.
      final line = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('Today · '),
        ),
      );
      final text = line.data!;
      expect(text, isNot(text.toUpperCase()),
          reason: 'the house document forbids all-caps labels (section 4.2)');
    });

    testWidgets('the session header leads with one big countdown number',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      final big = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.fontSize == 88)
          .toList();
      expect(big.length, 1,
          reason: 'at most one big number per screen, and exactly one here');
      expect(big.single.style!.fontFamily, LockoutTheme.fontDisplay);
      expect(big.single.style!.fontWeight, FontWeight.w800);
      expect(find.textContaining('sets left'), findsOneWidget);
    });

    testWidgets(
        'the session marker is a lobed shape whose lobes read as register',
        (tester) async {
      await seedActiveWeekdayRoutineForToday();
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);
      await tester.tap(find.text('Start session'));
      await settle(tester);

      final lobed = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<ShapeDecoration>()
          .map((d) => d.shape)
          .whereType<CookieBorder>()
          .toList();

      expect(lobed, isNotEmpty,
          reason: 'the session marker must carry a CookieBorder');
      expect(lobed.map((b) => b.lobes), everyElement(anyOf(4, 6)),
          reason: '4 lobes is rest, 6 is training; the marker is one of them');
    });

    testWidgets('the action-grid icon containers do not rotate lobe count',
        (tester) async {
      await tester.pumpWidget(hostedTodayTab());
      await settle(tester);

      final tileShapes = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(NvIconTile),
            matching: find.byType(Container),
          ))
          .map((c) => c.decoration)
          .whereType<ShapeDecoration>()
          .map((d) => d.shape)
          .whereType<CookieBorder>();

      expect(tileShapes, isEmpty,
          reason: 'repeated small icon containers take one consistent '
              'squircle; colour already carries category');

      // And it really is one squircle, not eight that happen to agree: every
      // tile resolves the same corner radius.
      final radii = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(NvIconTile),
            matching: find.byType(Container),
          ))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => (d.borderRadius! as BorderRadius).topLeft.x)
          .toSet();
      expect(radii, hasLength(1));
    });
  });
}
