import 'package:flutter/material.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get typokar24White => TextStyle(
        fontFamily: 'typokar',
        fontSize: 24.sp,
        color: Colors.white,
      );

  static TextStyle get wessamBold24black => TextStyle(
        fontFamily: 'Wessam',
        fontSize: 24.sp,
        color: Colors.black,
      );

  static TextStyle get cairoRegular14 => TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w400,
        fontSize: 14.sp,
      );

  static TextStyle get cairoMedium16 => TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w500,
        fontSize: 16.sp,
      );

  static TextStyle get cairoBold18 => TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        fontSize: 18.sp,
      );

  static TextStyle get almaraiRegular14 => TextStyle(
        fontFamily: 'Almarai',
        fontWeight: FontWeight.w400,
        fontSize: 14.sp,
      );
}
