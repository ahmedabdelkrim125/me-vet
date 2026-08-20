import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/core/widgets/custom_alert_dialog.dart';
import '../../domain/mock_inventory_repository.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/product_unit.dart';
import 'add_product_sheet.dart';

Future<void> showProductDetailSheet(
    BuildContext context, ProductModel product) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProductDetailSheet(product: product),
  );
}

class ProductDetailSheet extends StatelessWidget {
  final ProductModel product;

  const ProductDetailSheet({super.key, required this.product});

  Future<void> _confirmDelete(BuildContext context) async {
    Navigator.of(context).pop();
    await showDialog(
      context: context,
      builder: (dialogContext) => CustomAlertDialog(
        title: 'حذف الصنف',
        content:
            'هل أنت متأكد من حذف "${product.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
        primaryButtonText: 'حذف',
        secondaryButtonText: 'إلغاء',
        primaryButtonColor: dialogContext.colors.statusNotReached,
        onPrimaryPressed: () async {
          await MockInventoryRepository.instance.deleteProduct(product.id);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = MockInventoryRepository.instance.stockOf(product.id);
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 16.h),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.file(File(product.imagePath!),
                            fit: BoxFit.cover)
                        : Icon(Icons.medication_liquid_outlined,
                            color: context.colors.primary, size: 26.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: AppTextStyles.cairoBold18.copyWith(
                                color: context.colors.text, fontSize: 16.sp)),
                        SizedBox(height: 4.h),
                        Text(product.category.label,
                            style: AppTextStyles.almaraiRegular14.copyWith(
                                color: context.colors.textMuted,
                                fontSize: 11.sp)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'السعر الأساسي',
                  value: '${product.basePrice.toStringAsFixed(0)} ج.م'),
              _DetailRow(
                  icon: Icons.straighten_rounded,
                  label: 'وحدة القياس',
                  value: product.unit.label),
              _DetailRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'الحد الأدنى العام',
                  value: '${product.minStockThreshold} ${product.unit.label}'),
              _DetailRow(
                icon: Icons.local_shipping_outlined,
                label: 'الكمية في العربية',
                value: stock == null
                    ? 'غير مضاف للعربية'
                    : '${stock.quantity} ${product.unit.label}',
              ),
              if (stock != null)
                _DetailRow(
                    icon: Icons.rule_rounded,
                    label: 'الحد الأدنى بالعربية',
                    value: '${stock.minThreshold} ${product.unit.label}'),
              _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'تاريخ الإضافة',
                  value: DateFormat('yyyy/MM/dd').format(product.createdAt)),
              _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'وقت الإضافة',
                  value: DateFormat('hh:mm a').format(product.createdAt)),
              if (product.expiryDate != null)
                _DetailRow(
                  icon: Icons.event_busy_outlined,
                  label: 'تاريخ الصلاحية',
                  value: DateFormat('yyyy/MM/dd').format(product.expiryDate!),
                ),
              Builder(
                builder: (context) {
                  final warehouse = MockInventoryRepository.instance
                      .warehouseStockOf(product.id);
                  return _DetailRow(
                    icon: Icons.warehouse_outlined,
                    label: 'الكمية بالمخزن الرئيسي',
                    value: warehouse == null
                        ? '0 ${product.unit.label}'
                        : '${warehouse.quantity} ${product.unit.label}',
                  );
                },
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: context.colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () {
                          Navigator.of(context).pop();
                          showAddProductSheet(context, productToEdit: product);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: context.colors.primary, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('تعديل',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.primary,
                                      fontSize: 13.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Material(
                      color: context.colors.statusNotReached.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: () => _confirmDelete(context),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: context.colors.statusNotReached,
                                  size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('حذف',
                                  style: AppTextStyles.cairoMedium16.copyWith(
                                      color: context.colors.statusNotReached,
                                      fontSize: 13.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: context.colors.textMuted),
          SizedBox(width: 8.w),
          Text(label,
              style: AppTextStyles.almaraiRegular14
                  .copyWith(color: context.colors.textMuted, fontSize: 11.sp)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: context.colors.text, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
