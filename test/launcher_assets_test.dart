import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launcher supports round, adaptive and themed masks', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
    for (final version in [26, 33]) {
      for (final name in ['ic_launcher', 'ic_launcher_round']) {
        final xml = File(
          'android/app/src/main/res/mipmap-anydpi-v$version/$name.xml',
        ).readAsStringSync();
        expect(xml, contains('<adaptive-icon'));
        expect(xml, contains('@drawable/ic_launcher_foreground'));
        if (version == 33) expect(xml, contains('<monochrome'));
      }
    }
  });

  test(
    'legacy launcher densities have correct square and round pixel sizes',
    () {
      for (final density in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries) {
        for (final name in ['ic_launcher', 'ic_launcher_round']) {
          final bytes = File(
            'android/app/src/main/res/mipmap-${density.key}/$name.png',
          ).readAsBytesSync();
          final header = ByteData.sublistView(bytes);
          expect(header.getUint32(16), density.value);
          expect(header.getUint32(20), density.value);
        }
      }
    },
  );

  testWidgets(
    'adaptive foreground fits the always-visible circular safe zone',
    (tester) async {
      await tester.runAsync(() async {
        final bytes = File(
          'assets/branding/exports/foreground/432.png',
        ).readAsBytesSync();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final pixels = (await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        var visible = 0;
        for (var y = 0; y < 432; y++) {
          for (var x = 0; x < 432; x++) {
            if (pixels.getUint8((y * 432 + x) * 4 + 3) < 16) continue;
            visible++;
            final dx = x + .5 - 216;
            final dy = y + .5 - 216;
            expect(
              dx * dx + dy * dy,
              lessThanOrEqualTo(132 * 132),
              reason: 'Logo clipped by an Android launcher mask at ($x,$y)',
            );
          }
        }
        expect(visible, greaterThan(10000));
        frame.image.dispose();
        codec.dispose();
      });
    },
  );
}
