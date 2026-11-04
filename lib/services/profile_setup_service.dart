import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'nutrition_planner.dart';
import 'numeric_guard.dart';
import 'schedule_service.dart';
import 'units.dart';

/// Raw local draft inputs stay separate from the active profile until Finish.
class ProfileSetupDraft {
  final Map<String, String> values;
  final int step;
  ProfileSetupDraft({Map<String, String> values = const {}, this.step = 0})
    : values = Map.unmodifiable(values);
  String operator [](String key) => values[key] ?? '';
  String get weightUnit => this['weight_unit'] == 'lb' ? 'lb' : 'kg';
  String get heightUnit => this['height_unit'] == 'ft' ? 'ft' : 'cm';
  ProfileSetupDraft copyWith({Map<String, String>? values, int? step}) =>
      ProfileSetupDraft(
        values: {...this.values, ...?values},
        step: step ?? this.step,
      );
  double? _positive(String key) {
    return NumericGuard.parse(this[key], min: 0, minExclusive: true);
  }

  double? get weightKg {
    final value = _positive('weight');
    return value == null
        ? null
        : weightUnit == 'lb'
        ? Units.lbToKg(value)
        : value;
  }

  double? get targetKg {
    final value = _positive('target_weight');
    return value == null
        ? null
        : weightUnit == 'lb'
        ? Units.lbToKg(value)
        : value;
  }

  double? get heightCm {
    if (heightUnit == 'cm') return _positive('height_cm');
    final feet = int.tryParse(this['height_ft']);
    final inches = NumericGuard.parse(
      this['height_in'].isEmpty ? '0' : this['height_in'],
    );
    if (feet == null ||
        feet < 0 ||
        inches == null ||
        !inches.isFinite ||
        inches < 0 ||
        inches >= 12) {
      return null;
    }
    final value = Units.feetInchesToCm(feet, inches);
    return value > 0 && value.isFinite ? value : null;
  }

  Map<String, String> get errors {
    final age = int.tryParse(this['age']);
    final weeks = int.tryParse(this['weeks']);
    final days = int.tryParse(this['days']);
    return {
      if (age == null || age < 1 || age > 120)
        'age': 'Enter your age in whole years, from 1 to 120.',
      if (!{'male', 'female'}.contains(this['sex']))
        'sex': 'Choose the sex used for your calorie estimate.',
      if (weightKg == null ||
          !weightKg!.isFinite ||
          weightKg! < 1 ||
          weightKg! > 1000)
        'weight':
            'Enter a current weight between 1 and 1000 kg, or its equivalent in pounds.',
      if (heightCm == null || heightCm! < 30 || heightCm! > 300)
        'height':
            'Enter a height between 30 and 300 cm. Inches must be from 0 to less than 12.',
      if (targetKg == null ||
          !targetKg!.isFinite ||
          targetKg! < 1 ||
          targetKg! > 1000)
        'target_weight':
            'Enter a target weight between 1 and 1000 kg, or its equivalent in pounds.',
      if (weeks == null || weeks < 1)
        'weeks': 'Enter a positive number of weeks.',
      if (!ActivityLevel.values.any((v) => v.name == this['activity']))
        'activity': 'Choose your usual activity level.',
      if (days == null || days < 1 || days > 7)
        'days': 'Choose from 1 to 7 training days per week.',
    };
  }

  Map<String, String> errorsAt(int page) {
    const keys = [
      ['age', 'sex'],
      ['weight', 'height'],
      ['target_weight', 'weeks'],
      ['activity', 'days'],
    ];
    final all = errors;
    return page >= 4
        ? all
        : {
            for (final key in keys[page])
              if (all.containsKey(key)) key: all[key]!,
          };
  }
}

class ProfileSetupState {
  final bool needsSetup;
  final ProfileSetupDraft draft;
  final String baseline;
  const ProfileSetupState({
    required this.needsSetup,
    required this.draft,
    required this.baseline,
  });
}

/// One transaction activates the profile, initial measurement and completion.
/// Existing tables/settings are reused; no destructive migration is needed.
class ProfileSetupService {
  static const _profileKeys = [
    'age',
    'sex',
    'height_cm',
    'target_weight_kg',
    'goal_weeks',
    'activity_level',
    'training_days_per_week',
    'unit_weight',
    'height_unit',
    'profile_setup_revision',
  ];
  static const draftKey = 'profile_setup_draft';
  static const editDraftKey = 'profile_edit_draft';
  static const _fields = {
    'goal_intent',
    'age',
    'sex',
    'weight',
    'height_cm',
    'height_ft',
    'height_in',
    'target_weight',
    'weeks',
    'activity',
    'days',
    'weight_unit',
    'height_unit',
  };
  final DateTime Function() clock;
  ProfileSetupService({DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  String _number(double? value) => value == null || !value.isFinite
      ? ''
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  Future<Map<String, String>> _settings(DatabaseExecutor db) async => {
    for (final row in await db.query('user_settings'))
      row['key'] as String: row['value'] as String,
  };
  Future<List<Map<String, Object?>>> _body(DatabaseExecutor db) =>
      db.query('body_logs', orderBy: 'date_str DESC, id DESC');
  String _baseline(
    Map<String, String> settings,
    List<Map<String, Object?>> body,
  ) => jsonEncode([
    for (final key in _profileKeys) settings[key],
    if (body.isNotEmpty)
      [body.first['id'], body.first['date_str'], body.first['weight_kg']],
  ]);
  ProfileSetupDraft _prefill(
    Map<String, String> settings,
    List<Map<String, Object?>> body,
  ) {
    final evidence =
        body.isNotEmpty ||
        (settings['age'] ?? '').isNotEmpty ||
        ((settings['height_cm'] ?? '').isNotEmpty &&
            settings['height_cm'] != '175.0') ||
        (settings['target_weight_kg'] ?? '').isNotEmpty;
    final unit = settings['unit_weight'] == 'lb' ? 'lb' : 'kg';
    final heightUnit = settings['height_unit'] == 'ft' ? 'ft' : 'cm';
    final weight = body.isEmpty
        ? null
        : NumericGuard.read(body.first['weight_kg']);
    final target = NumericGuard.parse(
      settings['target_weight_kg'] ?? '',
      min: 0,
      minExclusive: true,
    );
    final height = evidence
        ? NumericGuard.parse(
            settings['height_cm'] ?? '',
            min: 0,
            minExclusive: true,
          )
        : null;
    final split = height == null ? null : Units.cmToFeetInches(height);
    return ProfileSetupDraft(
      values: {
        'age': settings['age'] ?? '',
        'sex': settings['sex'] ?? '',
        'weight': _number(
          weight == null
              ? null
              : unit == 'lb'
              ? Units.kgToLb(weight)
              : weight,
        ),
        'target_weight': _number(
          target == null
              ? null
              : unit == 'lb'
              ? Units.kgToLb(target)
              : target,
        ),
        'height_cm': _number(height),
        'height_ft': split?.feet.toString() ?? '',
        'height_in': _number(split?.inches),
        'weeks': settings['goal_weeks'] ?? '',
        'activity': settings['activity_level'] ?? '',
        'days': settings['training_days_per_week'] ?? '',
        'weight_unit': unit,
        'height_unit': heightUnit,
      },
    );
  }

  Future<ProfileSetupState> load({bool editing = false}) async {
    final db = await DatabaseService.instance.database;
    final settings = await _settings(db);
    final body = await _body(db);
    final baseline = _baseline(settings, body);
    final saved = _prefill(settings, body);
    final complete = saved.errors.isEmpty;
    var draft = saved.copyWith(step: editing ? 4 : 0);
    if (editing || !complete) {
      try {
        final raw = jsonDecode(
          settings[editing ? editDraftKey : draftKey] ?? '',
        );
        if (raw is Map &&
            raw['baseline'] == baseline &&
            raw['version'] == 1 &&
            raw['values'] is Map) {
          draft = ProfileSetupDraft(
            values: {
              for (final entry in (raw['values'] as Map).entries)
                if (_fields.contains(entry.key) && entry.value is String)
                  entry.key as String: entry.value as String,
            },
            step: raw['step'] is int ? (raw['step'] as int).clamp(0, 4) : 0,
          );
        }
      } catch (_) {
        /* Unreadable draft never replaces valid active data. */
      }
    }
    return ProfileSetupState(
      needsSetup: !complete,
      draft: draft,
      baseline: baseline,
    );
  }

  Future<void> saveDraft(
    ProfileSetupDraft draft, {
    required String baseline,
    bool editing = false,
  }) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      if (_baseline(await _settings(txn), await _body(txn)) != baseline) {
        throw StateError('Profile data changed. Reload your details.');
      }
      await txn.insert('user_settings', {
        'key': editing ? editDraftKey : draftKey,
        'value': jsonEncode({
          'version': 1,
          'baseline': baseline,
          'step': draft.step,
          'values': draft.values,
        }),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> complete(
    ProfileSetupDraft draft, {
    String? expectedBaseline,
    bool editing = false,
  }) async {
    final errors = draft.errors;
    if (errors.isNotEmpty) throw FormatException(errors.values.first);
    final db = await DatabaseService.instance.database;
    final now = clock();
    await db.transaction((txn) async {
      final settings = await _settings(txn);
      final body = await _body(txn);
      if (expectedBaseline != null &&
          _baseline(settings, body) != expectedBaseline) {
        throw StateError('Profile data changed. Reload your details.');
      }
      final weight = draft.weightKg!;
      final latest = body.isEmpty
          ? null
          : NumericGuard.read(body.first['weight_kg']);
      if (latest == null || (latest - weight).abs() > .01) {
        final date = ScheduleService.dateKey(now);
        var id = now.millisecondsSinceEpoch;
        for (final row in body.where((r) => r['date_str'] == date)) {
          final old = int.tryParse(row['id'].toString());
          if (old != null && old >= id) id = old + 1;
        }
        await txn.insert('body_logs', {
          'id': '$id',
          'date_str': date,
          'weight_kg': weight,
          'waist_cm': 0.0,
        });
      }
      final values = {
        'age': draft['age'],
        'sex': draft['sex'],
        'height_cm': '${draft.heightCm}',
        'target_weight_kg': '${draft.targetKg}',
        'goal_weeks': draft['weeks'],
        'activity_level': draft['activity'],
        'training_days_per_week': draft['days'],
        'unit_weight': draft.weightUnit,
        'height_unit': draft.heightUnit,
        'profile_setup_revision':
            '${(int.tryParse(settings['profile_setup_revision'] ?? '') ?? 0) + 1}',
        'profile_setup_completed': '1',
      };
      for (final entry in values.entries) {
        await txn.insert('user_settings', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.delete(
        'user_settings',
        where: 'key IN (?, ?)',
        whereArgs: [draftKey, editDraftKey],
      );
    });
  }
}
