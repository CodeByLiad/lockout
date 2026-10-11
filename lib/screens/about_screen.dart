import 'package:flutter/material.dart';

import '../theme/lockout_theme.dart';
import '../widgets/house/nv_cards.dart';

/// Section 12.3's About screen.
///
/// Settings used to carry this body inline, inside its own card. Task 10
/// lifts it onto its own route so Settings only ever points at it through a
/// single row; the copy itself is unchanged from the card it replaces.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      // Scrollable, matching SettingsScreen, which is where this copy used
      // to live. `Text` clips by default, so an unscrollable body drops the
      // tail of a long paragraph without an exception or an indicator: at
      // 320dp wide and text scale 1.15 — inside the 1.0-1.15 range config.md
      // pins layouts to — the card needs 861dp against about 600 available.
      //
      // The bottom inset is the same arithmetic SettingsScreen documents:
      // this route has an AppBar but no bottomNavigationBar, so on an
      // edge-to-edge window it runs to the physical bottom of the screen and
      // a fixed padding alone cannot clear the navigation bar. `paddingOf`,
      // not `viewPaddingOf`, so it collapses to 0 when the keyboard is up.
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          LockoutTheme.screenPadding,
          LockoutTheme.screenPadding,
          LockoutTheme.screenPadding,
          LockoutTheme.screenPadding + MediaQuery.paddingOf(context).bottom,
        ),
        child: NvInfoCard(
          child: Text(
            'LOCKOUT v1.1.0\nPublished by Jinatra Ltd. under '
            'GPL-3.0-or-later.\nOffline-first: routines, workout logs, '
            'nutrition and body data are stored only on this device in '
            'SQLite. No analytics, no ads, no account.\nThe network is used '
            'for one thing — streaming exercise form videos from YouTube '
            'when you tap Watch.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
