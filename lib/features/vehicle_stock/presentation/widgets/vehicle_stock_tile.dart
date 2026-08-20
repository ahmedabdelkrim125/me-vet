// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
// import 'package:mivet_app/core/theme/app_text_styles.dart';
// import 'package:mivet_app/core/utils/responsive_extension.dart';

// import '../../../inventory/domain/models/product_category.dart';
// import '../../../inventory/domain/models/product_model.dart';
// import '../../../inventory/domain/models/product_unit.dart';
// import '../../../inventory/domain/models/vehicle_stock_model.dart';

// class VehicleStockTile extends StatelessWidget {
//   final ProductModel product;
//   final VehicleStockModel stock;
//   final VoidCallback onTopUp;

//   const VehicleStockTile({
//     super.key,
//     required this.product,
//     required this.stock,
//     required this.onTopUp,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isOut = stock.quantity == 0;
//     final isLow = !isOut && stock.quantity <= stock.minThreshold;
//     final statusColor = isOut
//         ? context.colors.statusNotReached
//         : isLow
//             ? context.colors.statOrange
//             : context.colors.primary;
//     final progress = stock.minThreshold == 0
//         ? 1.0
//         : (stock.quantity / (stock.minThreshold * 2)).clamp(0.0, 1.0);

//     return Container(
//       padding: EdgeInsets.all(14.w),
//       decoration: BoxDecoration(
//         color: context.colors.surface,
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: context.colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 44.w,
//                 height: 44.w,
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(13.r),
//                 ),
//                 child: Icon(CupertinoIcons.bandage_fill,
//                     color: statusColor, size: 18.sp),
//               ),
//               SizedBox(width: 12.w),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(product.name,
//                         style: AppTextStyles.cairoMedium16.copyWith(
//                             color: context.colors.text, fontSize: 13.sp)),
//                     SizedBox(height: 2.h),
//                     Text(
//                       '${product.category.label} — ${product.unit.label}',
//                       style: AppTextStyles.almaraiRegular14.copyWith(
//                           color: context.colors.textMuted, fontSize: 10.sp),
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     '${stock.quantity}',
//                     style: AppTextStyles.cairoBold18
//                         .copyWith(color: statusColor, fontSize: 16.sp),
//                   ),
//                   Text(
//                     'الحد ${stock.minThreshold}',
//                     style: AppTextStyles.almaraiRegular14.copyWith(
//                         color: context.colors.textMuted, fontSize: 9.sp),
//                   ),
//                 ],
//               ),
//               SizedBox(width: 10.w),
//               Material(
//                 color: context.colors.primary,
//                 borderRadius: BorderRadius.circular(10.r),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(10.r),
//                   onTap: onTopUp,
//                   child: Padding(
//                     padding: EdgeInsets.all(8.w),
//                     child: Icon(CupertinoIcons.add,
//                         color: Colors.white, size: 14.sp),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 10.h),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(20.r),
//             child: LinearProgressIndicator(
//               value: progress,
//               minHeight: 6.h,
//               backgroundColor: context.colors.background,
//               valueColor: AlwaysStoppedAnimation(statusColor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/domain/models/product_category.dart';
import '../../../inventory/domain/models/product_model.dart';
import '../../../inventory/domain/models/product_unit.dart';
import '../../../inventory/domain/models/vehicle_stock_model.dart';

class VehicleStockTile extends StatelessWidget {
  final ProductModel product;
  final VehicleStockModel stock;
  final VoidCallback onLoadMore;

  const VehicleStockTile({
    super.key,
    required this.product,
    required this.stock,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = stock.quantity == 0;
    final isLow = !isOut && stock.quantity <= stock.minThreshold;
    final statusColor = isOut
        ? context.colors.statusNotReached
        : isLow
            ? context.colors.statOrange
            : context.colors.primary;
    final progress = stock.minThreshold == 0
        ? 1.0
        : (stock.quantity / (stock.minThreshold * 2)).clamp(0.0, 1.0);
    final daysLeft = product.daysUntilExpiry;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(CupertinoIcons.bandage_fill,
                    color: statusColor, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(product.name,
                              style: AppTextStyles.cairoMedium16.copyWith(
                                  color: context.colors.text, fontSize: 13.sp)),
                        ),
                        if (product.isExpired)
                          _Badge(
                              label: 'منتهي',
                              color: context.colors.statusNotReached)
                        else if (daysLeft != null && daysLeft <= 30)
                          _Badge(
                              label: 'صلاحية قربت',
                              color: context.colors.statOrange),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${product.category.label} — ${product.unit.label}',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: context.colors.textMuted, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${stock.quantity}',
                      style: AppTextStyles.cairoBold18
                          .copyWith(color: statusColor, fontSize: 16.sp)),
                  Text('الحد ${stock.minThreshold}',
                      style: AppTextStyles.almaraiRegular14.copyWith(
                          color: context.colors.textMuted, fontSize: 9.sp)),
                ],
              ),
              SizedBox(width: 10.w),
              Material(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.r),
                  onTap: onLoadMore,
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(CupertinoIcons.add,
                        color: Colors.white, size: 14.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.h,
              backgroundColor: context.colors.background,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8.r)),
      child: Text(label,
          style: AppTextStyles.cairoMedium16
              .copyWith(color: color, fontSize: 9.sp)),
    );
  }
}
