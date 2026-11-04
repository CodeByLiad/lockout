import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'test_helpers.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'filled numeric labels remain inside their surface at scale $scale',
      (t) async {
        await t.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final controls = [
          TextEditingController(text: '4'),
          TextEditingController(text: '6'),
          TextEditingController(text: '10'),
        ];
        addTearDown(() {
          for (final c in controls) {
            c.dispose();
          }
        });
        const labels = ['Sets', 'Min reps', 'Max reps'];
        await t.pumpWidget(
          MaterialApp(
            theme: lockoutTestTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: NvField(
                          key: ValueKey(labels[i]),
                          controller: controls[i],
                          label: labels[i],
                          compact: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        for (final focused in [false, true]) {
          if (focused) {
            await t.tap(find.byKey(const ValueKey('Min reps')));
            await t.pumpAndSettle();
          }
          for (final label in labels) {
            final field = find.byKey(ValueKey(label));
            final editable = find.descendant(
              of: field,
              matching: find.byType(EditableText),
            );
            final container = InputDecorator.containerOf(t.element(editable))!;
            final surface = MatrixUtils.transformRect(
              container.getTransformTo(null),
              Offset.zero & container.size,
            );
            final text = t.renderObject<RenderBox>(find.text(label));
            final bounds = MatrixUtils.transformRect(
              text.getTransformTo(null),
              Offset.zero & text.size,
            );
            expect(
              bounds.top,
              greaterThanOrEqualTo(surface.top + 4),
              reason: '$label straddles the surface edge',
            );
            expect(bounds.right, lessThanOrEqualTo(surface.right - 4));
            expect(
              bounds.bottom,
              lessThanOrEqualTo(t.getTopLeft(editable).dy + 1),
              reason: '$label overlaps its value',
            );
          }
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}
