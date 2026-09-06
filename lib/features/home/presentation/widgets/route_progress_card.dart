// import 'package:flutter/material.dart';
// import 'package:hugeicons/hugeicons.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_colors.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';

// class RouteProgressCard extends StatelessWidget {
//   final String routeName;
//   final String dayLabel;
//   final int totalVisits;
//   final int completedVisits;
//   final String buttonText;
//   final VoidCallback? onButtonTap;

//   const RouteProgressCard({
//     super.key,
//     required this.routeName,
//     required this.dayLabel,
//     required this.totalVisits,
//     required this.completedVisits,
//     required this.buttonText,
//     this.onButtonTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final remaining = (totalVisits - completedVisits).clamp(0, totalVisits);
//     final progress = totalVisits == 0 ? 0.0 : completedVisits / totalVisits;
//     final percent = (progress.clamp(0.0, 1.0) * 100).round();

//     return Container(
//       padding: EdgeInsets.all(18.w),
//       decoration: BoxDecoration(
//         color: AppColors.primary,
//         borderRadius: BorderRadius.circular(26.r),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.24),
//             blurRadius: 30,
//             offset: const Offset(0, 14),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 48.w,
//                 height: 48.w,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(18.r),
//                   border: Border.all(color: Colors.white.withOpacity(0.12)),
//                 ),
//                 child: HugeIcon(
//                   icon: HugeIcons.strokeRoundedRoute01,
//                   color: Colors.white,
//                   size: 24.sp,
//                 ),
//               ),
//               SizedBox(width: 12.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       routeName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppTextStyles.cairoBold18.copyWith(
//                         color: Colors.white,
//                         fontSize: 18.sp,
//                       ),
//                     ),
//                     SizedBox(height: 3.h),
//                     Text(
//                       dayLabel,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppTextStyles.almaraiRegular14.copyWith(
//                         color: Colors.white.withOpacity(0.7),
//                         fontSize: 12.sp,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               _PercentBadge(percent: percent),
//             ],
//           ),
//           SizedBox(height: 18.h),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(999),
//             child: LinearProgressIndicator(
//               value: progress.clamp(0.0, 1.0),
//               minHeight: 9.h,
//               backgroundColor: Colors.white.withOpacity(0.14),
//               valueColor:
//                   const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Row(
//             children: [
//               Expanded(
//                 child: _RouteStat(
//                   value: '$totalVisits',
//                   label: 'عميل',
//                   icon: HugeIcons.strokeRoundedUserGroup,
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               Expanded(
//                 child: _RouteStat(
//                   value: '$completedVisits',
//                   label: 'تمت',
//                   icon: HugeIcons.strokeRoundedCheckmarkCircle01,
//                   color: AppColors.primaryGreen,
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               Expanded(
//                 child: _RouteStat(
//                   value: '$remaining',
//                   label: 'متبقي',
//                   icon: HugeIcons.strokeRoundedClock01,
//                   color: AppColors.statOrange,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16.h),
//           _RouteActionButton(buttonText: buttonText, onTap: onButtonTap),
//         ],
//       ),
//     );
//   }
// }

// class _PercentBadge extends StatelessWidget {
//   final int percent;

//   const _PercentBadge({required this.percent});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(14.r),
//         border: Border.all(color: Colors.white.withOpacity(0.12)),
//       ),
//       child: Text(
//         '$percent%',
//         style: AppTextStyles.cairoBold18.copyWith(
//           color: Colors.white,
//           fontSize: 13.sp,
//         ),
//       ),
//     );
//   }
// }

// class _RouteStat extends StatelessWidget {
//   final String value;
//   final String label;
//   final List<List<dynamic>> icon;
//   final Color color;

//   const _RouteStat({
//     required this.value,
//     required this.label,
//     required this.icon,
//     this.color = Colors.white,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(18.r),
//         border: Border.all(color: Colors.white.withOpacity(0.1)),
//       ),
//       child: Column(
//         children: [
//           HugeIcon(icon: icon, color: color, size: 18.sp),
//           SizedBox(height: 5.h),
//           Text(
//             value,
//             style: AppTextStyles.cairoBold18.copyWith(
//               color: Colors.white,
//               fontSize: 16.sp,
//             ),
//           ),
//           Text(
//             label,
//             style: AppTextStyles.almaraiRegular14.copyWith(
//               color: Colors.white.withOpacity(0.66),
//               fontSize: 10.5.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _RouteActionButton extends StatelessWidget {
//   final String buttonText;
//   final VoidCallback? onTap;

//   const _RouteActionButton({required this.buttonText, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;

//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(18.r),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18.r),
//         onTap: onTap,
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 buttonText,
//                 style: AppTextStyles.cairoMedium16.copyWith(
//                   color: colors.primary,
//                   fontSize: 13.sp,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               Icon(Icons.add_rounded, color: colors.primary, size: 19.sp),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';

class RouteProgressCard extends StatelessWidget {
  final String routeName;
  final String dayLabel;
  final int totalVisits;
  final int completedVisits;

  const RouteProgressCard({
    super.key,
    required this.routeName,
    required this.dayLabel,
    required this.totalVisits,
    required this.completedVisits,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (totalVisits - completedVisits).clamp(0, totalVisits);
    final progress = totalVisits == 0 ? 0.0 : completedVisits / totalVisits;
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedRoute01,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cairoBold18.copyWith(
                        color: Colors.white,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      dayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.almaraiRegular14.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _PercentBadge(percent: percent),
            ],
          ),
          SizedBox(height: 18.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9.h,
              backgroundColor: Colors.white.withOpacity(0.14),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _RouteStat(
                  value: '$totalVisits',
                  label: 'عميل',
                  icon: HugeIcons.strokeRoundedUserGroup,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _RouteStat(
                  value: '$completedVisits',
                  label: 'تمت',
                  icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _RouteStat(
                  value: '$remaining',
                  label: 'متبقي',
                  icon: HugeIcons.strokeRoundedClock01,
                  color: AppColors.statOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final int percent;

  const _PercentBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        '$percent%',
        style: AppTextStyles.cairoBold18.copyWith(
          color: Colors.white,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  final String value;
  final String label;
  final List<List<dynamic>> icon;
  final Color color;

  const _RouteStat({
    required this.value,
    required this.label,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, color: color, size: 18.sp),
          SizedBox(height: 5.h),
          Text(
            value,
            style: AppTextStyles.cairoBold18.copyWith(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.almaraiRegular14.copyWith(
              color: Colors.white.withOpacity(0.66),
              fontSize: 10.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}
