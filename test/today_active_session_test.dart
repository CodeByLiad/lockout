import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/widgets/house/nv_set_row.dart';
import 'overhaul_test_support.dart';

void main() {
  testWidgets(
    'set editing reports valid weight and reps without accepting invalid values',
    (t) async {
      double weight = 0;
      int reps = 0;
      await pumpPage(
        t,
        Scaffold(
          body: NvSetRow(
            index: 1,
            weight: 60,
            reps: 8,
            completed: false,
            onWeight: (v) => weight = v,
            onReps: (v) => reps = v,
            onToggle: () {},
            onDelete: null,
          ),
        ),
      );
      await t.enterText(find.byType(TextField).first, '72.5');
      expect(weight, 72.5);
      await t.enterText(find.byType(TextField).last, '12');
      expect(reps, 12);
      await t.enterText(find.byType(TextField).last, '-4');
      expect(reps, 12);
      await t.enterText(find.byType(TextField).first, 'NaN');
      expect(weight, 72.5);
    },
  );
}
