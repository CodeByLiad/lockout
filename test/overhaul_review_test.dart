import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/models/models.dart';
import 'package:lockout/screens/settings_screen.dart';
import 'package:lockout/screens/routines_tab.dart';
import 'package:lockout/screens/progress_tab.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/theme/lockout_shapes.dart';
import 'package:lockout/widgets/house/nv_button.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'package:lockout/widgets/house/nv_grouped_list.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';

void main() {
  useTestDatabase();
  testWidgets(
    'large text button exposes the whole action instead of ellipsis',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        MaterialApp(
          theme: lockoutTestTheme(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(40),
              child: NvButton(
                variant: NvButtonVariant.text,
                label: 'Start a custom workout',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final para = t.renderObject<RenderParagraph>(
        find.text('Start a custom workout'),
      );
      expect(para.didExceedMaxLines, isFalse);
      expect(t.getSize(find.byType(NvButton)).height, greaterThan(48));
    },
  );
  testWidgets(
    'appearance explains styles and previews the current components',
    (t) async {
      await pumpPage(
        t,
        SettingsBody(onSettingsUpdated: () {}, section: 'appearance'),
      );
      expect(find.text('Live preview'), findsOneWidget);
      expect(find.text('Rep lime'), findsOneWidget);
      expect(find.text('Violet'), findsOneWidget);
      expect(find.text('Soft, balanced color'), findsOneWidget);
      expect(find.text('Playful contrasting color roles'), findsOneWidget);
    },
  );
  testWidgets('grouped row forwards press into its icon shape', (t) async {
    await pumpPage(
      t,
      Scaffold(
        body: NvListItem(
          title: 'Open plan',
          onTap: () {},
          leading: const NvIconBadge(
            icon: Icons.fitness_center,
            shape: LockoutShape.gem,
          ),
        ),
      ),
    );
    final gesture = await t.startGesture(t.getCenter(find.text('Open plan')));
    await t.pump(const Duration(milliseconds: 150));
    await t.pump(const Duration(milliseconds: 300));
    final surface = t
        .widgetList<Container>(
          find.descendant(
            of: find.byType(NvIconBadge),
            matching: find.byType(Container),
          ),
        )
        .first;
    expect(
      ((surface.decoration! as ShapeDecoration).shape as LockoutShapeBorder)
          .progress,
      1,
    );
    await gesture.up();
    await t.pumpAndSettle();
  });
  testWidgets(
    'training shows planned days without claiming completed workouts',
    (t) async {
      final db = DatabaseService.instance;
      await db.insertRoutine(
        Routine(
          id: 'r',
          name: 'Plan',
          schedulingMode: SchedulingMode.weekday,
          createdAt: '2026-01-01',
        ).toMap(),
      );
      await db.insertDay(
        TrainingDay(
          id: 'd',
          routineId: 'r',
          name: 'Push',
          tag: 'MON',
          orderIndex: 0,
        ).toMap(),
      );
      await db.setActiveRoutine('r');
      await pumpPage(t, RoutinesTab());
      expect(find.byType(NvWeekStrip), findsOneWidget);
      expect(find.text('1 day in your plan'), findsOneWidget);
    },
  );
  testWidgets('progress chart changes its aggregation with the period', (
    t,
  ) async {
    final db = DatabaseService.instance;
    await db.insertSessionLog(
      SessionLog(
        id: 's',
        dayName: 'Old workout',
        dateStr: '2020-01-01',
        durationSeconds: 60,
        totalVolumeKg: 40,
        totalSets: 1,
        status: 'completed',
      ).toMap(),
    );
    await pumpPage(t, const ProgressTab());
    expect(find.text('No workouts in this period'), findsOneWidget);
    await press(t, 'All time');
    expect(find.text('2020'), findsOneWidget);
    expect(find.text('Workouts by year'), findsOneWidget);
  });
}
