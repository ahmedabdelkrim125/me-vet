import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RepEntryHeader extends StatelessWidget {
  const RepEntryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              color: Colors.white,
              size: 32.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'أهلًا بيك في MIVET',
          style: AppTextStyles.cairoBold18
              .copyWith(color: AppColors.primary, fontSize: 20.sp),
        ),
        SizedBox(height: 6.h),
        Text(
          'منصة توزيع الأدوية البيطرية للمناديب',
          style: AppTextStyles.almaraiRegular14
              .copyWith(color: AppColors.navInactive, fontSize: 12.5.sp),
        ),
      ],
    );
  }
}
