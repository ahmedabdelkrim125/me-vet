import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/customer-visits/customers/data/invoices_repository.dart';

/// The quantity stepper is capped at the invoice line's original quantity.
/// The backend also enforces the true remaining-returnable quantity
/// (original minus previous returns) inside `create_sales_return` — that
/// number isn't exposed by any verified RPC, so Flutter cannot pre-filter
/// against it and relies on the server rejecting an over-return.
class ReturnItemSelector extends StatelessWidget {
  final InvoiceItemRow item;
  final int quantity;
  final ValueChanged<int> onChanged;

  const ReturnItemSelector({
    super.key,
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: AppTextStyles.cairoMedium16
                        .copyWith(color: colors.text, fontSize: 12.sp)),
                Text(
                  'الكمية الأصلية: ${item.quantity} — السعر: ${item.unitPrice.toStringAsFixed(0)} ج.م',
                  style: AppTextStyles.almaraiRegular14
                      .copyWith(color: colors.textMuted, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$quantity',
              style: AppTextStyles.cairoMedium16.copyWith(color: colors.text, fontSize: 13.sp)),
          IconButton(
            onPressed: quantity < item.quantity ? () => onChanged(quantity + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}