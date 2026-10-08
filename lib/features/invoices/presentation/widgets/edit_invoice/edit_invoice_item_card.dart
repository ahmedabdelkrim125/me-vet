import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/domain/invoice_draft.dart';
import 'package:mivet_app/features/invoices/presentation/widgets/edit_invoice/edit_invoice_quantity_control.dart';

class EditInvoiceItemCard extends StatelessWidget {
  final InvoiceItemDraft item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final ValueChanged<int> onEditQuantity;
  final VoidCallback onEditPrice;
  final VoidCallback onRemove;

  const EditInvoiceItemCard({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onEditQuantity,
    required this.onEditPrice,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: colors.text,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.textMuted,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEditPrice,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: colors.primary,
                          size: 15.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${item.unitPrice.toStringAsFixed(2)} ج.م',
                          style: AppTextStyles.cairoMedium16.copyWith(
                            color: colors.text,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              EditInvoiceQuantityControl(
                quantity: item.quantity,
                onIncrease: onIncrease,
                onDecrease: onDecrease,
                onEditQuantity: onEditQuantity,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.almaraiRegular14.copyWith(
                  color: colors.textMuted,
                  fontSize: 11.sp,
                ),
              ),
              const Spacer(),
              Text(
                '${item.total.toStringAsFixed(2)} ج.م',
                style: AppTextStyles.cairoBold18.copyWith(
                  color: colors.primary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
