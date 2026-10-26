import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'theme/theme_controller.dart';
import 'widgets/house/nv_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appearanceRead = await loadSavedAppearance();

  await NotificationService.instance.init();

  runApp(LockoutApp(appearanceUnreadable: !appearanceRead));
}

/// Resolves the saved appearance before the first frame, and reports whether
/// it could be read.
///
/// Awaited ahead of `runApp` so the app never flashes the default theme on
/// top of the chosen one — and guarded, because that await is the whole
/// boot. `ThemeController.load()` opens sqflite and runs schema migration,
/// and it lets a failed read escape on purpose: a controller that swallowed
/// it would have to invent a choice with no way to say it had. Here is where
/// that decision gets made, and the answer is that a lost preference is not
/// worth a blank screen on every launch with no widget alive to offer a way
/// back. The controller holds usable defaults from construction, so the app
/// boots on them; [StartupNotice] is what keeps the loss from being silent.
@visibleForTesting
Future<bool> loadSavedAppearance() async {
  try {
    await ThemeController.instance.load();
    return true;
  } catch (error, stack) {
    debugPrint('Could not read the saved appearance: $error\n$stack');
    return false;
  }
}

class LockoutApp extends StatelessWidget {
  final bool appearanceUnreadable;

  const LockoutApp({super.key, this.appearanceUnreadable = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      // MainScreen is written without `const` only because its constructor
      // is not const. It is not a theme requirement: see the note at the top
      // of `widgets/day_block.dart`, which works through why a const child
      // cannot be stranded in the old theme (anything reading
      // `Theme.of(context)` is rebuilt through its `InheritedWidget`
      // dependency, not through its parent) and names this call site as one
      // that could be const today. No key either: a changing key would
      // remount the tabs and discard an in-progress live session.
      builder: (_, _) => MaterialApp(
        title: 'LOCKOUT',
        debugShowCheckedModeBanner: false,
        theme: ThemeController.instance.lightTheme,
        darkTheme: ThemeController.instance.darkTheme,
        themeMode: ThemeController.instance.themeMode,
        home: StartupNotice(
          appearanceUnreadable: appearanceUnreadable,
          child: MainScreen(),
        ),
      ),
    );
  }
}

/// Says, inside the app, what went wrong before the app existed.
///
/// Booting on defaults is the right answer to an unreadable settings row;
/// booting on them quietly is not. The user's chosen appearance would simply
/// be gone, with nothing accounting for it, so the next thing they do is set
/// it again — over a database that may still be unreadable.
///
/// A snackbar rather than a blocking dialog: nothing here needs a decision,
/// and the one thing the app must not do on a bad launch is stand in the
/// user's way. Posted after the first frame because [ScaffoldMessenger] is
/// an ancestor this widget only has once it is mounted.
@visibleForTesting
class StartupNotice extends StatefulWidget {
  final bool appearanceUnreadable;
  final Widget child;

  const StartupNotice({
    super.key,
    required this.appearanceUnreadable,
    required this.child,
  });

  static const String appearanceMessage =
      'Could not read your saved settings, so the app opened with its '
      'default appearance.';

  @override
  State<StartupNotice> createState() => _StartupNoticeState();
}

class _StartupNoticeState extends State<StartupNotice> {
  @override
  void initState() {
    super.initState();
    if (!widget.appearanceUnreadable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showNvSnackbar(
        context: context,
        message: StartupNotice.appearanceMessage,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
