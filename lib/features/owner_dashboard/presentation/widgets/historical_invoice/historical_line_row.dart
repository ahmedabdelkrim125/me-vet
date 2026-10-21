import 'package:flutter/material.dart';
import 'package:mivet_app/core/theme/app_color_scheme_extension.dart';
import 'package:mivet_app/core/theme/app_colors.dart';
import 'package:mivet_app/core/theme/app_text_styles.dart';
import 'package:mivet_app/core/utils/responsive_extension.dart';
import 'package:mivet_app/features/owner_dashboard/presentation/cubit/historical_invoice_state.dart';

class HistoricalLineRow extends StatelessWidget {
  final HistoricalInvoiceLine line;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const HistoricalLineRow({
    super.key,
    required this.line,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.cairoMedium16.copyWith(fontSize: 12.5.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${line.quantity} × ${line.unitPrice.toStringAsFixed(2)} ج.م',
                    style: AppTextStyles.almaraiRegular14
                        .copyWith(color: colors.textMuted, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            Text(
              '${line.total.toStringAsFixed(0)} ج.م',
              style: AppTextStyles.cairoMedium16
                  .copyWith(color: colors.text, fontSize: 12.5.sp),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.statusNotReached,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
