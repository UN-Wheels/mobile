import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary teal — #45acab del web (tailwind.config.js)
  static const Color primary = Color(0xFF45ACAB);
  static const Color primaryLight = Color(0xFF6BC1C0);
  static const Color primaryDark = Color(0xFF2E7F7E);

  // Secondary dark blue — #284a6f del web
  static const Color secondary = Color(0xFF284A6F);
  static const Color secondaryLight = Color(0xFF3A6591);
  static const Color secondaryMedium = Color(0xFF1F3A5A);

  // Backgrounds & surfaces
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);

  // Text
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Borders & dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color white = Color(0xFFFFFFFF);

  // Dark auth theme — matches web AuthLayout gradients
  static const Color authBg1 = Color(0xFF07091A);
  static const Color authBg2 = Color(0xFF0A0F28);
  static const Color authBg3 = Color(0xFF0A1830);
  static const Color authCard1 = Color(0xFF0E1730);
  static const Color authCard2 = Color(0xFF0B1226);
}
