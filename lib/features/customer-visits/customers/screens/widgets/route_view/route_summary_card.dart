import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RouteSummaryCard extends StatelessWidget {
  final int total;
  final int completed;

  const RouteSummaryCard({
    super.key,
    required this.total,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final remaining = total - completed;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed من $total زيارة مكتملة',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12.sp,
                ),
              ),
              const Spacer(),
              Text(
                '$remaining متبقي',
                style: AppTextStyles.cairoMedium16.copyWith(
                  color: AppColors.primaryGreen,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8.h,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryGreen),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
