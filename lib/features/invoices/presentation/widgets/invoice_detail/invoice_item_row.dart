import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/invoices/data/invoices_repository.dart';

class InvoiceItemTile extends StatelessWidget {
  final InvoiceItemRow item;

  const InvoiceItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.cairoMedium16.copyWith(
                    color: colors.text,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.almaraiRegular14.copyWith(
                    color: colors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.lineTotal.toStringAsFixed(0)} ج.م',
            style: AppTextStyles.cairoBold18.copyWith(
              color: colors.primary,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
