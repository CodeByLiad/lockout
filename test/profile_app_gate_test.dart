import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/main.dart';
import 'package:lockout/screens/main_screen.dart';
import 'package:lockout/screens/profile_setup_screen.dart';
import 'package:lockout/screens/settings_hub.dart';
import 'package:lockout/screens/settings_screen.dart';
import 'package:lockout/services/profile_setup_service.dart';
import 'overhaul_test_support.dart';
import 'profile_setup_service_test.dart' show validProfile;
import 'test_helpers.dart' show settle;

class FailsOnceProfileService extends ProfileSetupService {
  var calls = 0;
  @override
  Future<ProfileSetupState> load({bool editing = false}) {
    if (calls++ == 0) return Future.error(StateError('test read failure'));
    return super.load(editing: editing);
  }
}

void main() {
  useTestDatabase();
  testWidgets(
    'the real app gates a fresh installation before mounting main tabs',
    (t) async {
      await t.pumpWidget(const LockoutApp());
      await settle(t);
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
    },
  );
  testWidgets(
    'profile load failure offers Retry without treating saved data as blank',
    (t) async {
      await pumpPage(
        t,
        ProfileGate(
          service: FailsOnceProfileService(),
          child: const Text('App ready'),
        ),
      );
      expect(find.text('Could not load your profile'), findsOneWidget);
      expect(find.text('App ready'), findsNothing);
    await press(t, 'Retry');
    await settle(t,maxPumps:100);
      expect(find.text('Make it yours'), findsOneWidget);
    },
  );
  testWidgets('settings opens the unified editable profile review', (t) async {
    await ProfileSetupService().complete(validProfile());
    await pumpPage(t, SettingsHub(onSettingsUpdated: () {}));
    await press(t, 'Profile & goals');
    expect(find.text('Review your details'), findsOneWidget);
    await press(t, 'Current measurements');
    expect(field('Weight (kg)'), findsOneWidget);
    expect(field('Height (cm)'), findsOneWidget);
  });
  testWidgets('Units offers preferences and a clear profile entry point', (
    t,
  ) async {
    await ProfileSetupService().complete(validProfile());
    await pumpPage(t, SettingsBody(section: 'units', onSettingsUpdated: () {}));
    expect(find.text('Save height'), findsNothing);
    expect(find.text('Edit profile'), findsOneWidget);
    await press(t, 'Edit profile');
    expect(find.text('Review your details'), findsOneWidget);
  });
}
