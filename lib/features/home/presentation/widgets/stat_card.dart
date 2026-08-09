// import 'package:flutter/material.dart';
// import 'package:hugeicons/hugeicons.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../domain/models/daily_stat_model.dart';

// class StatCard extends StatelessWidget {
//   final DailyStatModel stat;

//   const StatCard({super.key, required this.stat});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(14.w),
//       decoration: BoxDecoration(
//         color: context.colors.surface,
//         borderRadius: BorderRadius.circular(18.r),
//         border: Border.all(color: context.colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 36.w,
//             height: 36.w,
//             decoration: BoxDecoration(
//               color: stat.color.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(12.r),
//             ),
//             child: HugeIcon(icon: stat.icon, color: stat.color, size: 18.sp),
//           ),
//           SizedBox(height: 12.h),
//           Text(
//             stat.value,
//             style: AppTextStyles.cairoBold18.copyWith(
//               color: context.colors.text,
//               fontSize: 15.sp,
//             ),
//           ),
//           SizedBox(height: 4.h),
//           Text(
//             stat.label,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: AppTextStyles.almaraiRegular14.copyWith(
//               color: context.colors.textMuted,
//               fontSize: 11.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.colors.border),
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
            child: HugeIcon(icon: stat.icon, color: stat.color, size: 18.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            stat.value,
            style: AppTextStyles.cairoBold18.copyWith(
              color: context.colors.text,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: context.colors.textMuted,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                '▲ ${stat.trendPercent}%',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: AppColors.primaryGreen,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'عن الشهر الماضي',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: context.colors.textMuted,
                    fontSize: 9.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
