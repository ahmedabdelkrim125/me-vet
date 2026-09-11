import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mivet_app/core/errors/app_toast.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/core/widgets/custom_alert_dialog.dart';
import '../../data/products_repository.dart';
import '../../domain/models/product_catalog.dart';
import '../../domain/models/product_model.dart';
import 'add_product_sheet.dart';

/// Returns true if the product was edited or deleted, so the caller can
/// refresh whatever list it is showing.
Future<bool> showProductDetailSheet(
  BuildContext context,
  ProductModel product, {
  ProductCatalog catalog = ProductCatalog.empty,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProductDetailSheet(
      product: product,
      catalog: catalog,
    ),
  );
  return changed ?? false;
}

class ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final ProductCatalog catalog;

  const ProductDetailSheet({
    super.key,
    required this.product,
    this.catalog = ProductCatalog.empty,
  });

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  late ProductModel _product;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _editProduct() async {
    final updated = await showAddProductSheet(context, productToEdit: _product);
    if (!mounted || updated == null) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => CustomAlertDialog(
        title: 'حذف المنتج',
        content:
            'هل أنت متأكد من حذف "${_product.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
        primaryButtonText: 'حذف',
        secondaryButtonText: 'إلغاء',
        primaryButtonColor: dialogContext.colors.statusNotReached,
        onPrimaryPressed: () => _performDelete(dialogContext),
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _performDelete(BuildContext dialogContext) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await ProductsRepository.instance.deleteProduct(_product.id);
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      if (!mounted) return;
      showAppSuccess(context, 'تم حذف الصنف بنجاح');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      if (mounted) {
        setState(() => _deleting = false);
        showAppError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;
    final categoryName = widget.catalog.categoryName(product.category);
    final unitName = widget.catalog.unitName(product.unit);

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
                        ? product.imagePath!.startsWith('http')
                            ? Image.network(product.imagePath!,
                                fit: BoxFit.cover)
                            : Image.file(File(product.imagePath!),
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
                        Text(categoryName,
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
                  label: 'سعر التجزئة',
                  value: '${product.retailPrice.toStringAsFixed(0)} ج.م'),
              _DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'سعر الجملة',
                  value: '${product.wholesalePrice.toStringAsFixed(0)} ج.م'),
              _DetailRow(
                  icon: Icons.straighten_rounded,
                  label: 'وحدة القياس',
                  value: unitName),
              _DetailRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'الحد الأدنى للمخزون',
                  value: '${product.minStockThreshold} $unitName'),
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
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: context.colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: _deleting ? null : _editProduct,
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
                        onTap: _deleting ? null : _confirmDelete,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _deleting
                                  ? SizedBox(
                                      width: 16.sp,
                                      height: 16.sp,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.colors.statusNotReached,
                                      ),
                                    )
                                  : Icon(Icons.delete_outline_rounded,
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