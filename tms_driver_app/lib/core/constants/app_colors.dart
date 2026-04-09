// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E3E92); // SV Blue (brand primary)
  static const Color secondary = Color(0xFFE31E24); // SV Red (brand secondary)
  static const Color background = Color(0xFFF9F9F9); // light grey
  static const Color text = Color(0xFF212121); // dark text
  static const Color muted = Color(0xFF757575); // grey text
  static const Color border = Color(0xFFE0E0E0); // light border
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFBC02D);

  // Theme-friendly scaffold fallback
  static Color scaffoldBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
}
