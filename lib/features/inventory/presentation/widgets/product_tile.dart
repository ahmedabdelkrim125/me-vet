import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/product_unit.dart';
import '../../domain/models/vehicle_stock_model.dart';

class ProductTile extends StatelessWidget {
  final ProductModel product;
  final VehicleStockModel? stock;
  final VoidCallback onAddToVehicle;

  const ProductTile({
    super.key,
    required this.product,
    required this.stock,
    required this.onAddToVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = stock?.quantity ?? 0;
    final threshold = stock?.minThreshold ?? product.minStockThreshold;
    final isLow = quantity <= threshold;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(CupertinoIcons.bandage_fill,
                color: context.colors.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: context.colors.text, fontSize: 13.sp)),
                SizedBox(height: 4.h),
                Text(
                  '${product.category.label} — ${product.unit.label} — ${product.basePrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: context.colors.textMuted, fontSize: 10.sp),
                ),
                SizedBox(height: 6.h),
                Text(
                  stock == null
                      ? 'غير موجود في العربية'
                      : '$quantity ${product.unit.label} في العربية',
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: isLow
                        ? context.colors.statusNotReached
                        : context.colors.primary,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: onAddToVehicle,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child:
                    Icon(CupertinoIcons.add, color: Colors.white, size: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
