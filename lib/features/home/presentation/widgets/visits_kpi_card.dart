import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class VisitsKpiCard extends StatelessWidget {
  final int currentVisits;
  final int targetVisits;

  const VisitsKpiCard({
    super.key,
    required this.currentVisits,
    required this.targetVisits,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetVisits == 0
        ? 0.0
        : (currentVisits / targetVisits).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppColors.primaryGreen,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'مؤشر الزيارات الشهرية',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: context.colors.text,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              Text(
                '$currentVisits / $targetVisits',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: AppColors.primaryGreen,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: context.colors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'الهدف الشهري لكل عميل من 3 إلى 4 زيارات',
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: AppColors.navInactive,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
