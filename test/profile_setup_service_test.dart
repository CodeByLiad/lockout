import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/services/database_service.dart';
import 'package:lockout/services/goal_service.dart';
import 'package:lockout/services/profile_setup_service.dart';
import 'overhaul_test_support.dart';

ProfileSetupDraft validProfile({Map<String, String> changes = const {}}) =>
    ProfileSetupDraft(
      values: {
        'age': '30',
        'sex': 'male',
        'weight': '80',
        'height_cm': '175',
        'target_weight': '75',
        'weeks': '12',
        'activity': 'moderate',
        'days': '4',
        'weight_unit': 'kg',
        'height_unit': 'cm',
        ...changes,
      },
    );

void main() {
  useTestDatabase();
  final db = DatabaseService.instance;
  final service = ProfileSetupService();
  test('fresh setup is required with no invented personal values', () async {
    final state = await service.load();
    expect(state.needsSetup, isTrue);
    for (final key in [
      'age',
      'sex',
      'weight',
      'height_cm',
      'target_weight',
      'weeks',
      'activity',
      'days',
    ]) {
      expect(state.draft[key], isEmpty, reason: key);
    }
  });
  test('saved height without other profile details is prefilled', () async {
    await db.saveSetting('height_cm', '165.10');
    await db.saveSetting('height_unit', 'ft');
    final state = await service.load();
    expect(state.needsSetup, isTrue);
    expect(state.draft['height_ft'], '5');
    expect(double.parse(state.draft['height_in']), closeTo(5, 0.01));
    expect(state.draft['age'], isEmpty);
    expect(state.draft['weight'], isEmpty);
  });
  test(
    'draft resumes without changing active settings or weight history',
    () async {
      final state = await service.load();
      final draft = validProfile().copyWith(
        values: {'target_weight': '', 'goal_intent': 'gain'},
        step: 2,
      );
      await service.saveDraft(draft, baseline: state.baseline);
      final resumed = await service.load();
      expect(resumed.draft.step, 2);
      expect(resumed.draft['weight'], '80');
      expect(resumed.draft['goal_intent'], 'gain');
      expect(resumed.draft['target_weight'], isEmpty);
      expect(await db.getSetting('age'), isEmpty);
      expect(await db.getBodyLogs(), isEmpty);
    },
  );
  test(
    'completion commits profile and first real measurement consistently',
    () async {
      final state = await service.load();
      await service.complete(validProfile(), expectedBaseline: state.baseline);
      expect((await service.load()).needsSetup, isFalse);
      expect(await db.getSetting('profile_setup_completed'), '1');
      final snapshot = await GoalService.instance.snapshot();
      expect(snapshot.isReady, isTrue);
      expect(snapshot.currentWeightKg, 80);
      expect(snapshot.profile.heightCm, 175);
      expect(snapshot.profile.targetWeightKg, 75);
      expect(await db.getSetting('profile_setup_draft'), isEmpty);
    },
  );
  test(
    'imperial inputs persist kg and cm, never display-unit numbers',
    () async {
      await service.complete(
        validProfile(
          changes: {
            'weight_unit': 'lb',
            'weight': '176.3696',
            'target_weight': '165.3465',
            'height_unit': 'ft',
            'height_ft': '5',
            'height_in': '9',
          },
        ),
      );
      final snapshot = await GoalService.instance.snapshot();
      expect(snapshot.currentWeightKg, closeTo(80, .001));
      expect(snapshot.profile.targetWeightKg, closeTo(75, .001));
      expect(snapshot.profile.heightCm, closeTo(175.26, .001));
      expect(await db.getSetting('unit_weight'), 'lb');
      expect(await db.getSetting('height_unit'), 'ft');
    },
  );
  test(
    'repeat completion and unchanged profile edits do not duplicate weigh-ins',
    () async {
      await service.complete(validProfile());
      await service.complete(validProfile());
      final edit = await service.load(editing: true);
      await service.complete(
        edit.draft,
        editing: true,
        expectedBaseline: edit.baseline,
      );
      expect(await db.getBodyLogs(), hasLength(1));
    },
  );
  test(
    'complete legacy profile bypasses setup and preserves history',
    () async {
      await service.complete(validProfile());
      final sql = await db.database;
      await sql.delete(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['profile_setup_completed'],
      );
      final before = jsonEncode(await db.getBodyLogs());
      expect((await service.load()).needsSetup, isFalse);
      expect(jsonEncode(await db.getBodyLogs()), before);
    },
  );
  test(
    'changed or restored data discards stale draft and rejects stale saves',
    () async {
      final state = await service.load();
      await service.saveDraft(validProfile(), baseline: state.baseline);
      await db.saveSetting('age', '45');
      final restored = await service.load();
      expect(restored.draft['age'], '45');
      expect(restored.draft['weight'], isEmpty);
      await expectLater(
        service.complete(validProfile(), expectedBaseline: state.baseline),
        throwsStateError,
      );
      expect(await db.getBodyLogs(), isEmpty);
    },
  );
  test(
    'failed final save rolls back everything and retry creates one measurement',
    () async {
      final sql = await db.database;
      await sql.execute(
        "CREATE TRIGGER reject_setup BEFORE INSERT ON user_settings WHEN NEW.key = 'profile_setup_completed' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(service.complete(validProfile()), throwsA(anything));
      expect(await db.getBodyLogs(), isEmpty);
      expect(await db.getSetting('age'), isEmpty);
      await sql.execute('DROP TRIGGER reject_setup');
      await service.complete(validProfile());
      expect(await db.getBodyLogs(), hasLength(1));
    },
  );
  test('invalid and non-finite profile values never reach storage', () async {
    for (final changes in [
      {'weight': 'NaN'},
      {'height_cm': 'Infinity'},
      {'weight': '1e308'},
      {'height_cm': '0.00001'},
      {'target_weight': '1e308'},
      {'age': '0'},
      {'sex': ''},
      {'days': '8'},
      {'weeks': '0'},
      {'target_weight': '-1'},
      {'height_unit': 'ft', 'height_ft': '5', 'height_in': '12'},
    ]) {
      await expectLater(
        service.complete(validProfile(changes: changes)),
        throwsFormatException,
      );
    }
    expect(await db.getBodyLogs(), isEmpty);
  });
  test(
    'editing current weight adds a new record without rewriting the old one',
    () async {
      await service.complete(validProfile());
      final old = (await db.getBodyLogs()).single;
      await service.complete(
        validProfile(changes: {'weight': '81'}),
        editing: true,
      );
      final rows = await db.getBodyLogs();
      expect(rows, hasLength(2));
      expect(rows.last, old);
      expect((await GoalService.instance.snapshot()).currentWeightKg, 81);
    },
  );
}
