import 'package:flutter/material.dart';

/// نظام ألوان مبسط وعصري مأخوذ من هوية MIVET الأصلية
/// بس بشكل أخف وأنضف يناسب يوزر عادي على الموبايل
class AppColors {
  AppColors._();

  // Brand
  static const Color navy = Color(0xFF0B1F3A);
  static const Color teal = Color(0xFF0E7C7B);
  static const Color tealLight = Color(0xFF12A09E);
  static const Color gold = Color(0xFFF5A623);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color danger = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2D7DD2);
  static const Color warning = Color(0xFFF5A623);

  // Neutrals
  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E9F0);
  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF627D98);
  static const Color textMuted = Color(0xFF9FB3C8);

  // Gradients
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, Color(0xFF1A3A5C)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, tealLight],
  );
}
