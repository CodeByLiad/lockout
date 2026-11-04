import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/screens/today_tab.dart';
import 'package:lockout/widgets/house/nv_expressive.dart';
import 'overhaul_test_support.dart';

void main() {
  useTestDatabase();
  testWidgets(
    'daily actions use distinct expressive shapes and the chosen containers',
    (t) async {
      await pumpPage(t, TodayTab());
      final actions = t
          .widgetList<NvActionCard>(find.byType(NvActionCard))
          .toList();
      expect(
        actions.map((a) => a.title),
        containsAll(['Log food', 'Weigh in']),
      );
      expect(actions.map((a) => a.shape).toSet().length, actions.length);
      expect(actions.map((a) => a.tone).toSet().length, greaterThan(1));
    },
  );
  testWidgets('daily actions route to the intended tasks', (t) async {
    String? destination;
    await pumpPage(
      t,
      TodayTab(onNavigate: (id, {segment}) => destination = id),
    );
    await press(t, 'Log food');
    expect(destination, 'food');
    await press(t, 'Weigh in');
    expect(destination, 'progress');
    await press(t, 'Training plans');
    expect(destination, 'workout');
  });
}
