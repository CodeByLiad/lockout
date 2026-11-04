import 'package:flutter/material.dart';
import 'nv_expressive.dart';

/// Filled expressive field shared by settings and focused data editors.
class NvTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  const NvTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.errorText,
    this.hintText,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) => NvField(
    label: label,
    controller: controller,
    keyboardType: keyboardType,
    errorText: errorText,
    hint: hintText,
    onChanged: onChanged,
  );
}
