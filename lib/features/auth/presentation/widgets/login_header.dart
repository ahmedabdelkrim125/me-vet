import 'package:flutter/material.dart';
import 'package:mivet_app/core/const/app_images.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class LoginHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginHeader({
    super.key,
    this.title = 'أهلًا بيك في MEVET',
    this.subtitle = 'سجّل الدخول للمتابعة',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(AppImages.logoSplash, width: 150.w, height: 180.w),
        Text(
          title,
          style: AppTextStyles.cairoBold18
              .copyWith(color: AppColors.primary, fontSize: 20.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: AppColors.navInactive, fontSize: 12.5.sp),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
