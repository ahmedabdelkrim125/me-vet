// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_colors.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';
// import '../../../auth/domain/models/user_profile.dart';

// class RepListTile extends StatelessWidget {
//   final UserProfile rep;
//   final VoidCallback onEdit;
//   final VoidCallback onDeactivate;

//   const RepListTile({
//     super.key,
//     required this.rep,
//     required this.onEdit,
//     required this.onDeactivate,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final statusColor =
//         rep.isActive ? AppColors.primaryGreen : AppColors.statusNotReached;
//     return Container(
//       margin: EdgeInsets.only(bottom: 12.h),
//       padding: EdgeInsets.all(14.w),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: colors.border),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 22.w,
//             backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
//             child: Icon(
//               Icons.person_rounded,
//               color: AppColors.primaryGreen,
//               size: 24.sp,
//             ),
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   rep.name,
//                   style: AppTextStyles.cairoBold18
//                       .copyWith(color: colors.text, fontSize: 15.sp),
//                 ),
//                 SizedBox(height: 2.h),
//                 Text(
//                   rep.phone,
//                   style: AppTextStyles.almaraiRegular14.copyWith(
//                     color: colors.textMuted,
//                     fontSize: 12.5.sp,
//                   ),
//                   textDirection: TextDirection.ltr,
//                 ),
//                 SizedBox(height: 6.h),
//                 Container(
//                   padding:
//                       EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
//                   decoration: BoxDecoration(
//                     color: statusColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8.r),
//                   ),
//                   child: Text(
//                     rep.isActive ? 'نشط' : 'معطل',
//                     style: AppTextStyles.almaraiRegular14.copyWith(
//                       color: statusColor,
//                       fontSize: 11.sp,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 onPressed: onEdit,
//                 icon: Icon(
//                   Icons.edit_outlined,
//                   color: AppColors.primary,
//                   size: 22.sp,
//                 ),
//               ),
//               if (rep.isActive)
//                 IconButton(
//                   onPressed: onDeactivate,
//                   icon: Icon(
//                     Icons.block_rounded,
//                     color: AppColors.statusNotReached,
//                     size: 22.sp,
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../auth/domain/models/user_profile.dart';

class RepListTile extends StatelessWidget {
  final UserProfile rep;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  const RepListTile({
    super.key,
    required this.rep,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor =
        rep.isActive ? AppColors.primaryGreen : AppColors.statusNotReached;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.w,
            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primaryGreen,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rep.name,
                  style: AppTextStyles.cairoBold18
                      .copyWith(color: colors.text, fontSize: 15.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  rep.phone,
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 12.5.sp,
                  ),
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    rep.isActive ? 'نشط' : 'معطل',
                    style: AppTextStyles.almaraiRegular14.copyWith(
                      color: statusColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
              ),
              if (rep.isActive)
                IconButton(
                  onPressed: onDeactivate,
                  icon: Icon(
                    Icons.block_rounded,
                    color: AppColors.statusNotReached,
                    size: 22.sp,
                  ),
                ),
              if (!rep.isActive)
                IconButton(
                  onPressed: onReactivate,
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primaryGreen,
                    size: 22.sp,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
