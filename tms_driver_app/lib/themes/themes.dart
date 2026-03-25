import 'package:flutter/material.dart';

const _svBlue = Color(0xFF2E3E92);
const _svRed = Color(0xFFE31E24);

final darkTheme = ThemeData.dark().copyWith(
  primaryColor: _svBlue,
  scaffoldBackgroundColor: Colors.blueGrey[900],
  appBarTheme: const AppBarTheme(
    backgroundColor: _svBlue,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _svBlue,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.blueGrey[800],
    selectedItemColor: const Color(0xFF6D7FCC),
    unselectedItemColor: Colors.white70,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: TextStyle(
      color: Colors.white70,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    titleLarge: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
);

final lightTheme = ThemeData.light().copyWith(
  primaryColor: _svBlue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: _svBlue,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: _svRed,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: _svBlue,
    unselectedItemColor: Colors.grey,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Colors.black87,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: TextStyle(
      color: Colors.black54,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    titleLarge: TextStyle(
      color: Colors.black87,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
);
