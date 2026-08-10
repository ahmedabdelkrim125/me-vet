import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../domain/models/product_model.dart';

Future<void> showAddToVehicleDialog(
  BuildContext context, {
  required ProductModel product,
  required Future<void> Function(int quantity, int minThreshold) onConfirm,
}) {
  final quantityController = TextEditingController();
  final thresholdController =
      TextEditingController(text: '${product.minStockThreshold}');

  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: context.colors.surface,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إضافة ${product.name} للعربية',
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.text, fontSize: 15.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),
              Text('الكمية',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: context.colors.textMuted, fontSize: 11.sp)),
              SizedBox(height: 6.h),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.text),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: context.colors.border)),
                ),
              ),
              SizedBox(height: 14.h),
              Text('الحد الأدنى في العربية',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                      color: context.colors.textMuted, fontSize: 11.sp)),
              SizedBox(height: 6.h),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.cairoMedium16
                    .copyWith(color: context.colors.text),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: context.colors.border)),
                ),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text('إلغاء',
                            style: AppTextStyles.cairoMedium16
                                .copyWith(color: context.colors.text)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final quantity =
                            int.tryParse(quantityController.text) ?? 0;
                        final threshold =
                            int.tryParse(thresholdController.text) ??
                                product.minStockThreshold;
                        if (quantity <= 0) return;
                        await onConfirm(quantity, threshold);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text('تأكيد',
                            style: AppTextStyles.cairoMedium16
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
