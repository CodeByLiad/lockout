import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_segmented_button.dart';

import 'test_helpers.dart';

Widget _host({required String selected, required ValueChanged<String> onChanged}) {
  return MaterialApp(
    theme: lockoutTestTheme(),
    home: Scaffold(
      body: NvSegmentedButton<String>(
        segments: const [
          NvSegment(value: 'light', label: 'Light'),
          NvSegment(value: 'dark', label: 'Dark'),
          NvSegment(value: 'system', label: 'System'),
        ],
        selected: selected,
        onChanged: onChanged,
      ),
    ),
  );
}

double _radiusOf(WidgetTester tester, String label, {required bool leading}) {
  final container = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    ).first,
  );
  final radius =
      ((container.decoration! as BoxDecoration).borderRadius!) as BorderRadius;
  return leading ? radius.topLeft.x : radius.topRight.x;
}

void main() {
  testWidgets('the outer ends are 22dp', (tester) async {
    await tester.pumpWidget(_host(selected: 'dark', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester, 'Light', leading: true), 22);
    expect(_radiusOf(tester, 'System', leading: false), 22);
  });

  testWidgets('an unselected inner segment is 8dp', (tester) async {
    await tester.pumpWidget(_host(selected: 'light', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester, 'Dark', leading: true), 8);
  });

  testWidgets('the selected segment becomes a full pill', (tester) async {
    await tester.pumpWidget(_host(selected: 'dark', onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(_radiusOf(tester, 'Dark', leading: true), 999);
  });

  testWidgets('tapping a segment reports its value', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      _host(selected: 'dark', onChanged: (value) => chosen = value),
    );
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(chosen, 'system');
  });

  testWidgets('each segment is a selectable semantics node', (tester) async {
    await tester.pumpWidget(_host(selected: 'dark', onChanged: (_) {}));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.text('Dark'));
    expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
  });
}
