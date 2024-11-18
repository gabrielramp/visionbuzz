import 'package:flutter/material.dart';

class Themes {

  static Color _mainColor =new Color(0xff4f009e);
  static ThemeData main = ThemeData(
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize:30,
        color: _mainColor,
      )
    ),
    colorScheme: ColorScheme.fromSeed(
        primary: _mainColor,
        secondary: const Color(0xffffffff),
        // surface: const Color(0xff00000),
        seedColor: Colors.red),
  );

  static List<ThemeData> _appThemes = [main];
}
