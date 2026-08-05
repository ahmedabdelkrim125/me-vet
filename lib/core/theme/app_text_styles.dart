import 'package:flutter/material.dart';
import 'app_colors.dart';

/// استخدام الخطين:
/// - Almarai: للعناوين الكبيرة والأرقام البارزة (شكله أقوى وأوضح في الحجم الكبير)
/// - Cairo: لباقي النصوص والفقرات والأزرار (مريح في القراءة بالحجم الصغير)
class AppTextStyles {
  AppTextStyles._();

  static const String headingFont = 'Almarai';
  static const String bodyFont = 'Cairo';

  // Headings (Almarai)
  static const TextStyle h1 = TextStyle(
    fontFamily: headingFont,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headingFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headingFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: headingFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body (Cairo)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: bodyFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
