import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/theme/lockout_theme.dart';

/// Lays out the real content of a stat tile at [scale] and returns the height
/// it needs.
///
/// Measured rather than asserted against a literal: the body face changed
/// from Inter to Figtree, and a constant derived from one face's metrics says
/// nothing about the other's.
Future<double> _statTileContentHeight(
  WidgetTester tester,
  double scale,
) async {
  final text = LockoutTheme.textThemeFor(const ColorScheme.light());

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: IntrinsicHeight(
              // A `Container` with both an explicit padding and a border
              // adds `decoration.padding` on top — 1dp a side — so a plain
              // `Padding` probe under-reports the real `StatTile` by 2dp.
              // The probe that exists to stop guessing must not itself guess.
              child: Container(
                key: const Key('probe'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF000000)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight', style: text.labelSmall),
                    const SizedBox(height: 4),
                    // The real `StatTile` value style, read through
                    // `LockoutTheme.numeric` rather than hand-built: the
                    // house `numericTable` line-height ratio applies at
                    // every call size, and building the style by hand here
                    // is what let a 3dp overflow through the first time.
                    Builder(
                      builder: (context) => Text(
                        '82.5',
                        style: LockoutTheme.numeric(context, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  return tester
      .renderObject<RenderBox>(find.byKey(const Key('probe')))
      .size
      .height;
}

void main() {
  for (final scale in const [1.0, 1.05, 1.10, 1.15]) {
    testWidgets('a stat tile fits its content at text scale $scale',
        (tester) async {
      final needed = await _statTileContentHeight(tester, scale);
      expect(
        LockoutTheme.statTileHeight,
        greaterThanOrEqualTo(needed),
        reason: 'a stat tile clips at text scale $scale: content needs '
            '$needed but statTileHeight is ${LockoutTheme.statTileHeight}',
      );
    });
  }

  testWidgets('a control fits a labelLarge line at text scale 1.15',
      (tester) async {
    final text = LockoutTheme.textThemeFor(const ColorScheme.light());

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.15)),
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                key: const Key('probe'),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('Save to routine', style: text.labelLarge),
              ),
            ),
          ),
        ),
      ),
    );

    final needed = tester
        .renderObject<RenderBox>(find.byKey(const Key('probe')))
        .size
        .height;

    expect(LockoutTheme.controlHeight, greaterThanOrEqualTo(needed),
        reason: 'a control clips at text scale 1.15: content needs $needed '
            'but controlHeight is ${LockoutTheme.controlHeight}');
    expect(LockoutTheme.controlHeight,
        greaterThanOrEqualTo(LockoutTheme.minTouchTarget));
  });
}
