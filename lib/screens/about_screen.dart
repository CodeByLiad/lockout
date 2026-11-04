import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/lockout_shapes.dart';
import '../widgets/house/nv_expressive.dart';
import '../widgets/house/nv_grouped_list.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => NvPage(
    title: 'About Lockout',
    back: true,
    children: [
      const Center(
        child: NvIconBadge(
          icon: Icons.fitness_center_rounded,
          shape: LockoutShape.flower,
          size: 112,
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: Text(
          'Lockout',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      const SizedBox(height: 8),
      const Center(child: Text('Strength, on your terms.')),
      const NvHeading('On your device'),
      NvGroupedList(
        children: [
          const NvListItem(title: 'Version', supporting: '1.3.1'),
          const NvListItem(
            title: 'Works offline',
            supporting:
                'No account, ads or analytics. Your routines, workouts, food and body data stay in SQLite on this device.',
          ),
          const NvListItem(title: 'License', supporting: 'GPL-3.0-or-later'),
          const NvListItem(title: 'Published by Jinatra Ltd.'),
          NvListItem(
            title: 'Source code',
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              final opened = await launchUrl(
                Uri.parse('https://github.com/CodeByLiad/lockout'),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open the source code link.'),
                  ),
                );
              }
            },
          ),
          const NvListItem(
            title: 'Exercise videos',
            supporting:
                'YouTube opens only when you tap Watch. Videos need an internet connection; your training and logs work offline.',
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Text('Built for training. Kept on your device.'),
    ],
  );
}
