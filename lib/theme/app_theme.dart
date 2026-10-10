import 'package:flutter/material.dart';
import 'package:shop/theme/button_theme.dart';
import 'package:shop/theme/input_decoration_theme.dart';

import '../constants.dart';
import 'checkbox_themedata.dart';
import 'theme_data.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: "Plus Jakarta",
      primarySwatch: primaryMaterialColor,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF9F9FB),
      iconTheme: const IconThemeData(color: blackColor),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: "Plus Jakarta",
          fontWeight: FontWeight.w700,
          color: Color(0xFF2C2D35),
          letterSpacing: -0.6,
        ),
        headlineMedium: TextStyle(
          fontFamily: "Plus Jakarta",
          fontWeight: FontWeight.w700,
          color: Color(0xFF2C2D35),
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: "Plus Jakarta",
          fontWeight: FontWeight.w700,
          color: Color(0xFF2C2D35),
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontFamily: "Plus Jakarta",
          fontWeight: FontWeight.w700,
          color: Color(0xFF2C2D35),
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontFamily: "Plus Jakarta",
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2D35),
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          fontFamily: "Plus Jakarta",
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2D35),
        ),
        bodyLarge: TextStyle(
          fontFamily: "Plus Jakarta",
          color: Color(0xFF383842),
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: "Plus Jakarta",
          color: Color(0xFF6E6E7A),
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      textButtonTheme: textButtonThemeData,
      outlinedButtonTheme: outlinedButtonTheme(),
      inputDecorationTheme: lightInputDecorationTheme,
      checkboxTheme: checkboxThemeData.copyWith(
        side: const BorderSide(color: blackColor40),
      ),
      appBarTheme: appBarLightTheme,
      scrollbarTheme: scrollbarThemeData,
      dataTableTheme: dataTableLightThemeData,
    );
  }
}
