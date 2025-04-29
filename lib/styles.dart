import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFFADD8E6);
  static const Color secondaryTan = Color.fromARGB(255, 250, 244, 236);
  static const Color accentTan = Color.fromARGB(255, 250, 244, 236);
  static const Color darkText = Colors.black;
}

class AppThemes {
  static final ThemeData defaultTheme = ThemeData(
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.secondaryTan,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.black,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.black,
    ),
    cardColor: AppColors.primaryBlue,
  );

  static final ThemeData snowTheme = ThemeData(
    primaryColor: Colors.grey,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.grey,
      foregroundColor: Colors.black,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.grey,
      foregroundColor: Colors.black,
    ),
    cardColor: Colors.grey,
  );

  static final ThemeData spaceTheme = ThemeData(
    primaryColor: Colors.purple,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.purple,
  );

  static final ThemeData lightningTheme = ThemeData(
    primaryColor: Colors.yellow,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.yellow,
      foregroundColor: Colors.black,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.yellow,
      foregroundColor: Colors.black,
    ),
    cardColor: Colors.yellow,
  );

  static final ThemeData waterTheme = ThemeData(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.lightBlueAccent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.blue,
  );

  static final ThemeData woodTheme = ThemeData(
    primaryColor: Colors.brown,
    scaffoldBackgroundColor: AppColors.secondaryTan,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.brown,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.brown,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.brown,
  );
}
