import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/accents.dart';
import 'package:lockout/theme/cookie_border.dart';
import 'package:lockout/theme/lockout_theme.dart';
import 'package:lockout/widgets/house/nv_hero_card.dart';
import 'package:lockout/widgets/house/nv_wavy_progress.dart';

import 'test_helpers.dart';

Widget _host({
  double? progress,
  Widget? marker,
  List<Widget> actions = const [],
  TestAppearance appearance = darkAppearance,
}) {
  return MaterialApp(
    theme: appearance.theme,
    home: Scaffold(
      body: NvHeroCard(
        title: 'Push day',
        value: '18',
        unit: 'sets',
        marker: marker,
        progress: progress,
        actions: actions,
      ),
    ),
  );
}

Material _cardMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find
        .descendant(
          of: find.byType(NvHeroCard),
          matching: find.byType(Material),
        )
        .first,
  );
}

void main() {
  testWidgets('it wears the signature asymmetric outline', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(_cardMaterial(tester).shape, LockoutTheme.heroCardShape);
  });

  testWidgets('it fills with the accent, not a neutral', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final colors = Theme.of(tester.element(find.byType(NvHeroCard))).colorScheme;
    expect(
      _cardMaterial(tester).color,
      colors.primaryContainer,
      reason: 'house section 8 gives the hero card an accent fill; a neutral '
          'fill with an accent rail is the previous design, and only a device '
          'screenshot caught it last time',
    );
  });

  testWidgets('the fill follows the chosen accent', (tester) async {
    // Not the brightness: `primaryContainer` is the accent itself in both
    // light and dark, which is the whole point of the two-axis theme. What
    // must move the fill is a different accent.
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    final lime = _cardMaterial(tester).color;

    await tester.pumpWidget(
      _host(
        appearance:
            const TestAppearance(Brightness.dark, LockoutAccent.violet),
      ),
    );
    await tester.pumpAndSettle();
    expect(_cardMaterial(tester).color, isNot(lime));
  });

  testWidgets('it takes the accent fill in light as well as dark',
      (tester) async {
    for (final appearance in [darkAppearance, lightAppearance]) {
      await tester.pumpWidget(_host(appearance: appearance));
      await tester.pumpAndSettle();
      expect(_cardMaterial(tester).color, appearance.colors.primaryContainer,
          reason: '${appearance.key} lost the accent fill');
    }
  });

  testWidgets('the big number is the house countdown style', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final colors = Theme.of(tester.element(find.byType(NvHeroCard))).colorScheme;
    final value = tester.widget<Text>(find.text('18'));
    expect(value.style?.fontSize, LockoutTheme.countdown(colors).fontSize);
    expect(value.style?.fontWeight, LockoutTheme.countdown(colors).fontWeight);
    expect(value.style?.color, colors.onPrimaryContainer);
  });

  testWidgets('it states the unit beside the number', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('sets'), findsOneWidget);
  });

  testWidgets('no progress means no progress bar', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.byType(NvWavyProgress), findsNothing);
  });

  testWidgets('a progress value draws the wavy indicator', (tester) async {
    await tester.pumpWidget(_host(progress: 0.4));
    await tester.pump();
    expect(find.byType(NvWavyProgress), findsOneWidget);
  });

  testWidgets('the marker renders inside the card', (tester) async {
    await tester.pumpWidget(
      _host(
        marker: const DecoratedBox(
          decoration: ShapeDecoration(
            shape: CookieBorder.training,
            color: Color(0xFF123456),
          ),
          child: SizedBox(width: 56, height: 56),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(NvHeroCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((decorated.decoration as ShapeDecoration).shape,
        CookieBorder.training);
  });

  testWidgets('actions render below the number', (tester) async {
    await tester.pumpWidget(
      _host(actions: const [Text('Start session')]),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Start session')).dy,
      greaterThan(tester.getTopLeft(find.text('18')).dy),
    );
  });
}
