import 'package:flutter/material.dart';
import 'database_service.dart';
import 'units.dart';

/// Presentation preferences only. Every stored weight remains in kilograms.
class DisplayUnits {
  static final weightUnit = ValueNotifier<String>('kg');
  static String get unit => weightUnit.value;
  static Future<void> load() async {
    final value = await DatabaseService.instance.getSetting(
      'unit_weight',
      defaultValue: 'kg',
    );
    weightUnit.value = value == 'lb' ? 'lb' : 'kg';
  }

  static Future<void> select(String value) async {
    await DatabaseService.instance.saveSetting('unit_weight', value);
    weightUnit.value = value == 'lb' ? 'lb' : 'kg';
  }

  static double value(double kg) => unit == 'lb' ? Units.kgToLb(kg) : kg;
  static double toKg(double number) =>
      unit == 'lb' ? Units.lbToKg(number) : number;
  static String format(BuildContext context, double kg, {int decimals = 1}) {
    context.dependOnInheritedWidgetOfExactType<DisplayUnitsScope>();
    return kg.isFinite
        ? '${value(kg).toStringAsFixed(decimals)} $unit'
        : 'Not available';
  }
}

class DisplayUnitsScope extends InheritedNotifier<ValueNotifier<String>> {
  DisplayUnitsScope({super.key, required super.child})
    : super(notifier: DisplayUnits.weightUnit);
}
