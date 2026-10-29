import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/services/nutrition_planner.dart';

void main() {
  test('activity level names are sentence case', () {
    for (final a in ActivityLevel.values) {
      final rest = a.label.substring(1);
      expect(rest, rest.toLowerCase(), reason: a.label);
    }
  });
}
