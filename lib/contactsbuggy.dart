// import 'package:flutter/material.dart';
// import 'package:get/get_connect/http/src/utils/utils.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:provider/provider.dart';


// class ThemeHandler extends StatefulWidget {
//   final Widget child;

//   const ThemeHandler({Key? key, required this.child}) : super(key: key);

//   @override
//   Themes createState() => Themes();

//   static Themes of(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<_ThemePasser>()!.state;
//   }
// }

// class Themes {//extends State<ThemeHandler> {
//   ThemeData _themeData = ThemeData.light();

//   // void setColor(Color color) {
//   //   setState(() {
//   //   _mainColor = color;
//   //   });
//   }
//   setMainColor(Color color) {
//     _mainColor = color;
//   }
  
//   static Color _mainColor = new Color(0xff4f009e);
//   static ThemeData main = ThemeData(
//     useMaterial3: true,
//     appBarTheme: AppBarTheme(
//         titleTextStyle: TextStyle(
//       fontSize: 45,
//       color: _mainColor,
//     )),
//     textTheme: TextTheme(
//       titleMedium: TextStyle(fontSize: 40, fontStyle: FontStyle.italic),
//       headlineMedium: TextStyle(
//           fontSize: 35, fontWeight: FontWeight.w700, color: _mainColor),
//       headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
//     ),
//     colorScheme: ColorScheme.fromSeed(
//         primary: _mainColor,
//         secondary: const Color(0xffffffff),
//         // surface: const Color(0xff00000),
//         seedColor: Colors.red),
//   );

//   static ThemeData green = ThemeData( useMaterial3: true,
//     appBarTheme: AppBarTheme(
//         titleTextStyle: TextStyle(
//       fontSize: 45,
//       color: Colors.green,
//     )),
//     textTheme: TextTheme(
//       titleMedium: TextStyle(fontSize: 40, fontStyle: FontStyle.italic),
//       headlineMedium: TextStyle(
//           fontSize: 35, fontWeight: FontWeight.w700, color: Colors.green),
//       headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
//     ),
//     colorScheme: ColorScheme.fromSeed(
//         primary: Colors.green,
//         secondary: const Color(0xffffffff),
//         // surface: const Color(0xff00000),
//         seedColor: Colors.red),
//   );

//   static List<ThemeData> _appThemes = [main];

//   List<ThemeData> getAppThemes(){
//     return _appThemes;
//   }
// }
