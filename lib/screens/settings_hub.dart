import 'package:flutter/material.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';
import '../theme/lockout_shapes.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class SettingsHub extends StatelessWidget {
  final VoidCallback onSettingsUpdated;
  final bool workoutActive;
  const SettingsHub({
    super.key,
    required this.onSettingsUpdated,
    this.workoutActive = false,
  });
  void _open(BuildContext context, String section) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsBody(
            onSettingsUpdated: onSettingsUpdated,
            section: section,
            restoreAllowed: !workoutActive,
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    Widget row(
      String title,
      String detail,
      IconData icon,
      LockoutShape shape,
      NvTone tone,
      String section,
    ) => NvListItem(
      leading: NvIconBadge(icon: icon, shape: shape, tone: tone),
      title: title,
      supporting: detail,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _open(context, section),
    );
    return NvPage(
      title: 'Settings',
      back: true,
      children: [
        Row(
          children: [
            const NvIconBadge(
              icon: Icons.fitness_center_rounded,
              shape: LockoutShape.softBurst,
              size: 64,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lockout',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text('Your training, on your device'),
                ],
              ),
            ),
          ],
        ),
        const NvHeading('Make it yours'),
        NvGroupedList(
          children: [
            row(
              'Appearance',
              'Brightness, accent and color style',
              Icons.palette_outlined,
              LockoutShape.flower,
              NvTone.secondary,
              'appearance',
            ),
            row(
              'Units',
              'Weight and height',
              Icons.straighten_rounded,
              LockoutShape.pentagon,
              NvTone.tertiary,
              'units',
            ),
          ],
        ),
        const NvHeading('Your plan'),
        NvGroupedList(
          children: [
            row(
              'Profile & goals',
              'Your profile and daily nutrition targets',
              Icons.person_outline_rounded,
              LockoutShape.clover4Leaf,
              NvTone.primary,
              'goals',
            ),
            row(
              'Training preferences',
              'Days per week and activity level',
              Icons.fitness_center_rounded,
              LockoutShape.gem,
              NvTone.secondary,
              'training',
            ),
            row(
              'Reminders',
              'Training and streak notifications',
              Icons.notifications_outlined,
              LockoutShape.arch,
              NvTone.tertiary,
              'reminders',
            ),
          ],
        ),
        const NvHeading('Your data'),
        NvGroupedList(
          children: [
            row(
              'Backup & restore',
              'Export or restore a local backup',
              Icons.save_alt_rounded,
              LockoutShape.diamond,
              NvTone.secondary,
              'data',
            ),
            NvListItem(
              leading: const NvIconBadge(
                icon: Icons.info_outline_rounded,
                shape: LockoutShape.bun,
              ),
              title: 'About Lockout',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Offline. No account needed.'),
      ],
    );
  }
}
