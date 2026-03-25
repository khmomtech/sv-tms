// lib/core/constants/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// To support UI theme toggling, ensure this class is used in combination
/// with a ThemeProvider that controls ThemeMode.light or ThemeMode.dark.
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: TextTheme(
          bodyLarge: AppTextStyles.body.copyWith(fontSize: 16.0),
          bodyMedium: AppTextStyles.caption.copyWith(fontSize: 14.0),
          titleLarge: AppTextStyles.heading1.copyWith(fontSize: 20.0),
        ).apply(
          fontFamily: 'NotoSansKhmer',
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppColors.secondary,
        ),
      );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: TextTheme(
          bodyLarge: const TextStyle(fontSize: 16.0, color: Colors.white),
          bodyMedium: const TextStyle(fontSize: 14.0, color: Colors.white70),
          titleLarge: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ).apply(
          fontFamily: 'NotoSansKhmer',
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        colorScheme:
            ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
          secondary: AppColors.secondary,
        ),
      );
}
