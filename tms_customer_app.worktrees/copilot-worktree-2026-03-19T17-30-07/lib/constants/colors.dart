import 'package:flutter/material.dart';

class AppColors {
  // SV Trucking Brand Colors (from logo)
  static const primary = Color(0xFF2E3E92); // SV Blue (deep royal blue)
  static const primaryDark = Color(0xFF1E2A5E);
  static const primaryLight = Color(0xFF4A5FB8);

  static const secondary = Color(0xFFE31E24); // SV Red (vibrant red from logo)
  static const secondaryDark = Color(0xFFC41017);
  static const secondaryLight = Color(0xFFEF4444);

  static const accent = Color(0xFFFF6B35);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE31E24); // Same as secondary red

  // UI Colors
  static const background = Color(0xFFF8F9FA);
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF3F4F6);

  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  static const textDisabled = Color(0xFFD1D5DB);

  // Border & Divider
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFE5E7EB);

  // Gradient (SV Brand)
  static const gradientStart = secondary; // Red
  static const gradientEnd = primary; // Blue

  // Shadow colors
  // use withOpacity for Flutter 3.24 compatibility
  static Color shadowLight = Colors.black.withOpacity(0.05);
  static Color shadowMedium = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.15);
}
