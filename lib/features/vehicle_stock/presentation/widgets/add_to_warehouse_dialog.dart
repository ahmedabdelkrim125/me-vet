import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import '../../../inventory/domain/mock_inventory_repository.dart';
import '../../../inventory/domain/models/product_model.dart';

Future<void> showAddToWarehouseDialog(BuildContext context,
    {required ProductModel product}) {
  final controller = TextEditingController();

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
                'إضافة ${product.name} للمخزن الرئيسي',
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
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
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
                        final quantity = int.tryParse(controller.text) ?? 0;
                        if (quantity <= 0) return;
                        await MockInventoryRepository.instance.addToWarehouse(
                          productId: product.id,
                          quantity: quantity,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text('إضافة',
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
