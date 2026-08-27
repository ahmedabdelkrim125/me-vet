import 'package:flutter/material.dart';
import '../../../../core/const/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_extension.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          AppImages.logo,
          width: 120.w,
          height: 120.w,
        ),
        SizedBox(height: 16.h),
        Text(
          'مرحباً بك في MIVET',
          style: AppTextStyles.cairoMedium16.copyWith(
            fontSize: 24.sp,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'سجل الدخول للمتابعة',
          style: AppTextStyles.cairoMedium16.copyWith(
            color: AppColors.navInactive,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
