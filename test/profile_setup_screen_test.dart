import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/profile_setup_screen.dart';
import 'package:lockout/services/backup_service.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/profile_setup_service.dart';
import 'overhaul_test_support.dart';
import 'test_helpers.dart';
import 'profile_setup_service_test.dart' show validProfile;

void main() {
  useTestDatabase();
  final db = DatabaseService.instance;
  for (var step = 0; step < 5; step++) {
    testWidgets('step $step fits narrow enlarged text and keyboard', (t) async {
      final service = ProfileSetupService();
      final state = await service.load();
      await service.saveDraft(
        validProfile().copyWith(step: step),
        baseline: state.baseline,
      );
      await t.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      Future<void> show(double keyboard) async {
        await t.pumpWidget(
          MaterialApp(
            theme: lockoutTestTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: child!,
            ),
            home: ProfileSetupScreen(onCompleted: () {}),
          ),
        );
        await t.pumpAndSettle();
      }

      await show(0);
      expect(t.takeException(), isNull);
      final footer = find.text(step == 4 ? 'Finish setup' : 'Continue');
      expect(footer, findsOneWidget);
      await show(300);
      expect(t.takeException(), isNull);
      expect(t.getBottomRight(footer).dy, lessThanOrEqualTo(500));
    });
  }
  Future<void> until(WidgetTester t, bool Function() done) async {
    for (var i = 0; i < 120 && !done(); i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(
      done(),
      isTrue,
      reason:
          'The setup transition did not complete: ${t.widgetList<Text>(find.byType(Text)).map((w) => w.data).join(" | ")}',
    );
  }

  Future<void> basics(WidgetTester t) async {
    await t.enterText(field('Age (years)'), '30');
    await press(t, 'Male');
    await press(t, 'Continue');
    await t.enterText(field('Weight (kg)'), '80');
    await t.enterText(field('Height (cm)'), '175');
    await press(t, 'Continue');
    await t.enterText(field('Target weight (kg)'), '75');
    await t.enterText(field('Timeframe (weeks)'), '12');
    await press(t, 'Continue');
    await press(t, 'Moderately active');
    await t.enterText(field('Days'), '4');
    await press(t, 'Continue');
  }

  testWidgets('first launch stays gated until all five steps finish', (
    t,
  ) async {
    await pumpPage(
      t,
      const ProfileGate(child: Scaffold(body: Text('App ready'))),
    );
    expect(find.text('Make it yours'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);
    await press(t, 'Continue');
    expect(find.textContaining('Enter your age'), findsOneWidget);
    await basics(t);
    expect(find.text('Review your details'), findsOneWidget);
    expect(await db.getBodyLogs(), isEmpty);
    await press(t, 'Finish setup');
    await until(t, () => find.text('App ready').evaluate().isNotEmpty);
    expect(find.text('App ready'), findsOneWidget);
    expect(await db.getBodyLogs(), hasLength(1));
  });
  testWidgets('Back preserves values and an interrupted draft resumes', (
    t,
  ) async {
    await pumpPage(t, ProfileSetupScreen(onCompleted: () {}));
    await t.enterText(field('Age (years)'), '33');
    await press(t, 'Female');
    await press(t, 'Continue');
    await t.enterText(field('Weight (kg)'), '64.2');
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
    await pumpPage(t, ProfileSetupScreen(onCompleted: () {}));
    expect(find.text('Your starting point'), findsOneWidget);
    expect(
      t.widget<TextFormField>(field('Weight (kg)')).controller!.text,
      '64.2',
    );
    await press(t, 'Back');
    expect(
      t.widget<TextFormField>(field('Age (years)')).controller!.text,
      '33',
    );
  });
  testWidgets('unit changes preserve entered physical measurements', (t) async {
    await pumpPage(t, ProfileSetupScreen(onCompleted: () {}));
    await t.enterText(field('Age (years)'), '30');
    await press(t, 'Male');
    await press(t, 'Continue');
    await t.enterText(field('Weight (kg)'), '80');
    await t.enterText(field('Height (cm)'), '175');
    await press(t, 'lb');
    expect(
      double.parse(
        t.widget<TextFormField>(field('Weight (lb)')).controller!.text,
      ),
      closeTo(176.37, .01),
    );
    await press(t, 'ft / in');
    expect(t.widget<TextFormField>(field('Height (ft)')).controller!.text, '5');
    await press(t, 'kg');
    await press(t, 'cm');
    expect(
      double.parse(
        t.widget<TextFormField>(field('Weight (kg)')).controller!.text,
      ),
      closeTo(80, .01),
    );
    expect(
      double.parse(
        t.widget<TextFormField>(field('Height (cm)')).controller!.text,
      ),
      closeTo(175, .1),
    );
  });
  testWidgets('save failure keeps the review and retry commits once', (
    t,
  ) async {
    var finished = false;
    await pumpPage(t, ProfileSetupScreen(onCompleted: () => finished = true));
    await basics(t);
    final sql = await db.database;
    await sql.execute(
      "CREATE TRIGGER reject_setup BEFORE INSERT ON user_settings WHEN NEW.key = 'profile_setup_completed' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await press(t, 'Finish setup');
    expect(finished, isFalse);
    expect(find.textContaining('Your details are still here'), findsOneWidget);
    expect(await db.getBodyLogs(), isEmpty);
    await sql.execute('DROP TRIGGER reject_setup');
    await press(t, 'Finish setup');
    expect(finished, isTrue);
    expect(await db.getBodyLogs(), hasLength(1));
  });
  testWidgets(
    'a restored complete profile opens the app without duplicate measurement',
    (t) async {
      var finished = false;
      await pumpPage(
        t,
        ProfileSetupScreen(
          onCompleted: () => finished = true,
          restoreBackup: () async {
            await ProfileSetupService().complete(validProfile());
            return ImportResult.success(1);
          },
          refreshReminders: () async {},
        ),
      );
      await press(t, 'Restore backup');
      await press(t, 'Choose backup');
      await until(t, () => finished);
      expect(finished, isTrue);
      expect(await db.getBodyLogs(), hasLength(1));
    },
  );
  testWidgets('existing complete profiles enter the app directly', (t) async {
    await ProfileSetupService().complete(validProfile());
    await pumpPage(
      t,
      const ProfileGate(child: Scaffold(body: Text('App ready'))),
    );
    expect(find.text('App ready'), findsOneWidget);
    expect(find.text('Make it yours'), findsNothing);
  });
  testWidgets('profile editor starts on review with all details available', (
    t,
  ) async {
    await ProfileSetupService().complete(validProfile());
    await pumpPage(t, ProfileSetupScreen(editing: true, onCompleted: () {}));
    expect(find.text('Review your details'), findsOneWidget);
    expect(find.text('80 kg · 175 cm'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
  });
}
