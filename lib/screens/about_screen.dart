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
      body: Padding(
        padding: const EdgeInsets.all(LockoutTheme.screenPadding),
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
