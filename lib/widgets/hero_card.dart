import 'package:flutter/material.dart';

import '../theme/lockout_theme.dart';
import 'lockout_card.dart';

/// The one card a screen leads with.
///
/// v1 gave several blocks per screen a saturated fill, which is why the app
/// read as noisy: nothing was clearly the most important thing. Exactly one
/// HeroCard per screen is still the rule, but it now leads through elevation,
/// type scale and a single accent rail rather than by flooding a rectangle
/// with colour — a filled block that size fights the calm the design calls for
/// and forces every label inside it onto a contrast knife-edge.
class HeroCard extends StatelessWidget {
  /// Small label above the title — context, not content. Sentence case, like
  /// everything else: the house document forbids all-caps labels (section
  /// 4.2), so what used to be an all-caps eyebrow is now distinguished by
  /// size and colour alone.
  final String eyebrow;

  /// The one thing this screen is about.
  final String title;

  /// Optional detail line under the title.
  final String? subtitle;

  /// Actions laid out in a wrap under the text.
  final List<Widget> actions;

  /// The house document's hero-card padding (section 8), which is wider than
  /// the 16dp every other card takes.
  static const double heroPadding = 22;

  const HeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final ink = colors.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: LockoutTheme.spaceMd),
      child: LockoutCard(
        shape: LockoutTheme.heroCardShape,
        // Accent fill, per the house document's section 8. The previous
        // treatment — a neutral surface with a 4dp accent rail — came from
        // the design this branch replaces, which argued against flooding a
        // card with colour. The house system makes the opposite choice: the
        // hero card is one of the two or three places a screen is allowed to
        // spend the accent, and leaving it neutral is why the chosen accent
        // was invisible on the Today tab in light mode.
        color: colors.primaryContainer,
        padding: const EdgeInsets.all(heroPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(eyebrow, style: text.labelMedium?.copyWith(color: ink)),
            const SizedBox(height: LockoutTheme.spaceXs),
            Text(title, style: text.headlineMedium?.copyWith(color: ink)),
            if (subtitle != null) ...[
              const SizedBox(height: LockoutTheme.spaceXs),
              Text(subtitle!, style: text.bodyMedium?.copyWith(color: ink)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: LockoutTheme.spaceMd),
              // The actions sit on the accent, so their own colours come from
              // the ink pair rather than from the ambient scheme: a tonal
              // button's `secondaryContainer` is authored against a neutral
              // surface and goes muddy on a bright fill.
              Theme(
                data: theme.copyWith(
                  filledButtonTheme: FilledButtonThemeData(
                    style: theme.filledButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStatePropertyAll(ink),
                      foregroundColor:
                          WidgetStatePropertyAll(colors.primaryContainer),
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: theme.outlinedButtonTheme.style?.copyWith(
                      foregroundColor: WidgetStatePropertyAll(ink),
                      side: WidgetStatePropertyAll(BorderSide(color: ink)),
                    ),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: theme.textButtonTheme.style?.copyWith(
                      foregroundColor: WidgetStatePropertyAll(ink),
                    ),
                  ),
                ),
                child: Wrap(
                  spacing: LockoutTheme.spaceSm,
                  runSpacing: LockoutTheme.spaceSm,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
