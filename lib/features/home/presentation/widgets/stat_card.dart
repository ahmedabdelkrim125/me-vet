import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/daily_stat_model.dart';

class StatCard extends StatelessWidget {
  final DailyStatModel stat;

  const StatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            stat.value,
            style: AppTextStyles.cairoBold18.copyWith(
              color: AppColors.primary,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
