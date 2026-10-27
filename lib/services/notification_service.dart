import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'database_service.dart';
import 'schedule_service.dart';

/// Local-only reminders. Nothing leaves the device — these are scheduled by
/// the OS from data already stored in SQLite.
///
/// Reminders are scheduled *inexactly*. Exact alarms would need the
/// SCHEDULE_EXACT_ALARM grant, which Android treats as a restricted permission
/// and which a training nudge does not justify; a few minutes of drift is fine.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _workoutReminderId = 1001;
  static const int _streakReminderId = 1002;

  static const String _channelId = 'lockout_training';
  static const String _channelName = 'Training Reminders';
  static const String _channelDescription =
      'Daily workout nudges and streak warnings from LOCKOUT.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Brings the plugin up. Safe to call more than once: a no-op once it has
  /// succeeded, a fresh attempt after it has not.
  ///
  /// **Throws** when the plugin cannot be initialised — a platform channel
  /// that is not there is not something this class can paper over for the
  /// one caller that genuinely wants to know. That caller is `main.dart`'s
  /// boot path, which catches it, reports it and carries on booting.
  /// Nothing else calls this directly: every reminder path in this class
  /// goes through [_ensureReady] instead, so no UI call site has to repeat
  /// that guard.
  Future<void> init() async {
    if (_ready) return;

    try {
      tzdata.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Falls back to UTC. Reminders still fire, just anchored to UTC offset.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    _ready = true;
  }

  /// [init], with a start-up failure reported rather than thrown.
  ///
  /// The single guard every entry point below shares, and the reason none
  /// of them needs one of its own. Before it, `init()`'s throw ran straight
  /// out of `requestPermission()` and `rescheduleAll()` into five unguarded
  /// call sites in `settings_screen.dart` as an unhandled async error —
  /// the worst of them inside the import tail, where it took
  /// `onSettingsUpdated()` and the "Import complete" toast with it, so a
  /// restore applied while the OS kept the pre-restore schedule and the
  /// user was told nothing. A service that cannot start and a user who
  /// declines are the same outcome for every one of those callers: no
  /// reminders. This reports it as that.
  ///
  /// A retry each time rather than a latched failure: nothing here can tell
  /// a channel that is permanently absent from one that was not registered
  /// yet, and the cost of being wrong is one caught error.
  Future<bool> _ensureReady() async {
    try {
      await init();
    } catch (error, stack) {
      debugPrint('Notifications are unavailable: $error\n$stack');
    }
    return _ready;
  }

  /// Asks the OS for permission. Returns false when the user declines, so the
  /// settings toggle can refuse to switch on rather than lying to the user —
  /// and equally when the service never started, which costs the user the
  /// same thing.
  Future<bool> requestPermission() async {
    if (!await _ensureReady()) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      final granted = await darwin.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }

    return false;
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// Next occurrence of [hour]:[minute], today if still ahead, else tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Rebuilds every scheduled reminder from current settings. Call after any
  /// settings change so the OS never holds a stale schedule.
  Future<void> rescheduleAll() async {
    if (!await _ensureReady()) return;
    await cancelAll();

    final db = DatabaseService.instance;
    final enabled =
        await db.getSetting('reminders_enabled', defaultValue: 'false');
    if (enabled != 'true') return;

    final hour = int.tryParse(
          await db.getSetting('reminder_hour', defaultValue: '18'),
        ) ??
        18;
    final minute = int.tryParse(
          await db.getSetting('reminder_minute', defaultValue: '0'),
        ) ??
        0;

    await _scheduleDaily(
      id: _workoutReminderId,
      hour: hour,
      minute: minute,
      title: 'Training time',
      body: await _workoutReminderBody(),
    );

    final streakOn =
        await db.getSetting('streak_alerts_enabled', defaultValue: 'true');
    if (streakOn == 'true') {
      // Late-evening backstop: only useful if the day is about to lapse.
      await _scheduleDaily(
        id: _streakReminderId,
        hour: 21,
        minute: 0,
        title: 'Streak check',
        body: await _streakReminderBody(),
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Body text is baked in at schedule time, so it names the day that was
  /// scheduled rather than recomputing while the app is dead.
  Future<String> _workoutReminderBody() async {
    final sched = await ScheduleService.resolveToday();
    if (sched == null) return 'No session scheduled today. Rest or train off-plan.';
    return '${sched.day.name} - ${sched.exercises.length} exercises queued up.';
  }

  Future<String> _streakReminderBody() async {
    final dates = await DatabaseService.instance.getWorkoutDates();
    final streak = ScheduleService.currentStreakDays(dates);
    if (streak == 0) return 'No active streak. Today is a good day to start one.';
    return '$streak day streak on the line. Log a session before midnight.';
  }

  /// Immediate confirmation so the user can see the channel actually works.
  ///
  /// Guarded like everything else here even though its only call site sits
  /// behind a reminders toggle that cannot be on unless the service
  /// started: the guard belongs to the method, not to the one caller that
  /// happens to have checked already.
  Future<void> showTestNotification() async {
    if (!await _ensureReady()) return;
    await _plugin.show(
      9999,
      'LOCKOUT reminders are on',
      'This is what a training nudge looks like.',
      _details,
    );
  }

  /// Same guard, same reasoning as [showTestNotification]: today the only
  /// caller is [rescheduleAll], which has already checked.
  Future<void> cancelAll() async {
    if (!await _ensureReady()) return;
    await _plugin.cancel(_workoutReminderId);
    await _plugin.cancel(_streakReminderId);
  }
}
