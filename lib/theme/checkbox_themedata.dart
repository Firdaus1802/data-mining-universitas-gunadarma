import 'package:flutter/material.dart';

import '../constants.dart';

CheckboxThemeData checkboxThemeData = CheckboxThemeData(
  checkColor: WidgetStateProperty.all(Colors.white),
  fillColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return primaryColor;
    }
    return Colors.transparent;
  }),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(
      Radius.circular(4),
    ),
  ),
  side: const BorderSide(color: Color(0xFFB0B0B5), width: 1.5),
);
